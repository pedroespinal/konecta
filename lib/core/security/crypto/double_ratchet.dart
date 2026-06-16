import 'dart:convert';
import 'dart:typed_data';
import 'package:convert/convert.dart';
import 'package:cryptography/cryptography.dart';

// Implementacion del Double Ratchet Algorithm (Signal Protocol)
// Basado en: https://signal.org/docs/specifications/doubleratchet/
//
// Cada sesion entre dos usuarios tiene:
//  - Root Chain Key (RK)
//  - Sending Chain Key (CKs) + mensaje keys derivadas de ella
//  - Receiving Chain Key (CKr) + mensaje keys derivadas de ella
//
// Cada vez que hay un nuevo PreKey Diffie-Hellman se hace "ratchet" del Root
// y se reinician las cadenas de envio/recepcion.

class RatchetSession {
  // Claves de cadena (32 bytes c/u)
  List<int> rootKey;
  List<int>? sendChainKey;
  List<int>? recvChainKey;

  // Par de claves DH actuales (X25519)
  SimpleKeyPair? dhSendPair;       // nuestra clave para este ratchet
  List<int>? dhRemotePublic;       // clave publica del peer

  // Contadores
  int sendMsgNum = 0;
  int recvMsgNum = 0;
  int prevSendChainLen = 0;        // para headers

  // Claves de mensaje guardadas (para mensajes fuera de orden)
  // key = (ratchetPubHex, msgNum), value = messageKey
  final Map<String, List<int>> _skippedKeys = {};

  RatchetSession({required this.rootKey});

  // Serializar para persistencia cifrada
  Map<String, dynamic> toMap() => {
        'rootKey': hex.encode(rootKey),
        'sendChainKey': sendChainKey != null ? hex.encode(sendChainKey!) : null,
        'recvChainKey': recvChainKey != null ? hex.encode(recvChainKey!) : null,
        'dhRemotePublic':
            dhRemotePublic != null ? hex.encode(dhRemotePublic!) : null,
        'sendMsgNum': sendMsgNum,
        'recvMsgNum': recvMsgNum,
        'prevSendChainLen': prevSendChainLen,
      };

  factory RatchetSession.fromMap(Map<String, dynamic> m) {
    final s = RatchetSession(rootKey: hex.decode(m['rootKey'] as String));
    if (m['sendChainKey'] != null) {
      s.sendChainKey = hex.decode(m['sendChainKey'] as String);
    }
    if (m['recvChainKey'] != null) {
      s.recvChainKey = hex.decode(m['recvChainKey'] as String);
    }
    if (m['dhRemotePublic'] != null) {
      s.dhRemotePublic = hex.decode(m['dhRemotePublic'] as String);
    }
    s.sendMsgNum = m['sendMsgNum'] as int;
    s.recvMsgNum = m['recvMsgNum'] as int;
    s.prevSendChainLen = m['prevSendChainLen'] as int;
    return s;
  }
}

class RatchetHeader {
  final List<int> dhPublic;   // Nuestra clave DH publica en este ratchet
  final int prevChainLen;
  final int msgNum;

  const RatchetHeader({
    required this.dhPublic,
    required this.prevChainLen,
    required this.msgNum,
  });

  List<int> encode() {
    final buf = BytesBuilder();
    buf.add(dhPublic);                       // 32 bytes
    buf.addByte((prevChainLen >> 8) & 0xFF);
    buf.addByte(prevChainLen & 0xFF);
    buf.addByte((msgNum >> 8) & 0xFF);
    buf.addByte(msgNum & 0xFF);
    return buf.toBytes();
  }

  factory RatchetHeader.decode(List<int> bytes) {
    return RatchetHeader(
      dhPublic: bytes.sublist(0, 32),
      prevChainLen: (bytes[32] << 8) | bytes[33],
      msgNum: (bytes[34] << 8) | bytes[35],
    );
  }
}

abstract final class DoubleRatchet {
  static final _hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);
  static final _aesGcm = AesGcm.with256bits();
  static final _x25519 = X25519();

  // ─── KDF ──────────────────────────────────────────────────────

  static Future<List<int>> _hkdfDerive(
    List<int> inputKey,
    List<int> salt,
    String info,
  ) async {
    final key = await _hkdf.deriveKey(
      secretKey: SecretKey(inputKey),
      nonce: salt,
      info: utf8.encode(info),
    );
    return key.extractBytes();
  }

  // KDF_RK: deriva (newRootKey, chainKey) del rootKey + DH output
  static Future<(List<int>, List<int>)> kdfRootKey(
    List<int> rootKey,
    List<int> dhOutput,
  ) async {
    final salt = Uint8List(32); // zero salt
    final mk = await _hkdfDerive(dhOutput, salt, 'konecta-rk-v1');
    final ck = await _hkdfDerive(mk, salt, 'konecta-ck-v1');
    return (mk, ck);
  }

  // KDF_CK: deriva (newChainKey, messageKey) del chainKey
  static Future<(List<int>, List<int>)> kdfChainKey(
      List<int> chainKey) async {
    final mk = await _hkdfDerive(chainKey, [0x01], 'konecta-mk-v1');
    final newCk = await _hkdfDerive(chainKey, [0x02], 'konecta-ck-step');
    return (newCk, mk);
  }

  // ─── DH ───────────────────────────────────────────────────────

  static Future<SimpleKeyPair> generateDHPair() => _x25519.newKeyPair();

  static Future<List<int>> dhOutput(
    SimpleKeyPair ourPair,
    List<int> theirPublic,
  ) async {
    final shared = await _x25519.sharedSecretKey(
      keyPair: ourPair,
      remotePublicKey: SimplePublicKey(theirPublic, type: KeyPairType.x25519),
    );
    return shared.extractBytes();
  }

  // ─── Inicializar sesion (emisor — quien inicia el X3DH) ───────

  static Future<RatchetSession> initSender({
    required List<int> sharedSecret, // del X3DH
    required SimpleKeyPair myDHPair,
    required List<int> theirDHPublic,
  }) async {
    final dh = await dhOutput(myDHPair, theirDHPublic);
    final (rk, ck) = await kdfRootKey(sharedSecret, dh);
    final session = RatchetSession(rootKey: rk);
    session.sendChainKey = ck;
    session.dhSendPair = myDHPair;
    session.dhRemotePublic = theirDHPublic;
    return session;
  }

  // ─── Inicializar sesion (receptor) ───────────────────────────

  static Future<RatchetSession> initReceiver({
    required List<int> sharedSecret,
    required List<int> theirDHPublic,
  }) async {
    final session = RatchetSession(rootKey: sharedSecret);
    session.dhRemotePublic = theirDHPublic;
    return session;
  }

  // ─── Cifrar mensaje ──────────────────────────────────────────

  static Future<(List<int>, RatchetHeader)> encrypt(
    RatchetSession session,
    List<int> plaintext,
    List<int> associatedData,
  ) async {
    if (session.sendChainKey == null) {
      throw StateError('Session not initialized for sending');
    }

    final (newCk, mk) = await kdfChainKey(session.sendChainKey!);
    session.sendChainKey = newCk;

    final pub = (await session.dhSendPair!.extractPublicKey()).bytes;
    final header = RatchetHeader(
      dhPublic: pub,
      prevChainLen: session.prevSendChainLen,
      msgNum: session.sendMsgNum,
    );
    session.sendMsgNum++;

    final headerBytes = header.encode();
    final aad = [...associatedData, ...headerBytes];

    final nonce = _aesGcm.newNonce();
    final sealed = await _aesGcm.encrypt(
      plaintext,
      secretKey: SecretKey(mk),
      nonce: nonce,
      aad: aad,
    );

    // Formato: [nonceLen(1)][nonce][headerLen(1)][header][ciphertext][mac]
    final buf = BytesBuilder();
    buf.addByte(nonce.length);
    buf.add(nonce);
    buf.addByte(headerBytes.length);
    buf.add(headerBytes);
    buf.add(sealed.cipherText);
    buf.add(sealed.mac.bytes);

    return (buf.toBytes(), header);
  }

  // ─── Descifrar mensaje ───────────────────────────────────────

  static Future<List<int>> decrypt(
    RatchetSession session,
    List<int> ciphertext,
    List<int> associatedData,
  ) async {
    // Parsear el frame
    int offset = 0;
    final nonceLen = ciphertext[offset++];
    final nonce = ciphertext.sublist(offset, offset + nonceLen);
    offset += nonceLen;
    final headerLen = ciphertext[offset++];
    final headerBytes = ciphertext.sublist(offset, offset + headerLen);
    offset += headerLen;
    // ciphertext + mac (mac = ultimos 16 bytes del sobre AES-GCM)
    final ct = ciphertext.sublist(offset, ciphertext.length - 16);
    final mac = ciphertext.sublist(ciphertext.length - 16);

    final header = RatchetHeader.decode(headerBytes);
    final aad = [...associatedData, ...headerBytes];

    // Verificar si hay clave guardada para este mensaje
    final skipKey =
        '${hex.encode(header.dhPublic)}_${header.msgNum}';
    List<int> mk;

    if (session._skippedKeys.containsKey(skipKey)) {
      mk = session._skippedKeys.remove(skipKey)!;
    } else {
      // Ratchet DH si la clave publica del header es nueva
      final remoteHex = session.dhRemotePublic != null
          ? hex.encode(session.dhRemotePublic!)
          : '';
      if (hex.encode(header.dhPublic) != remoteHex) {
        await _skipMessageKeys(session, header.prevChainLen);
        await _dhratchet(session, header);
      }
      await _skipMessageKeys(session, header.msgNum);
      final (newCk, msgKey) = await kdfChainKey(session.recvChainKey!);
      session.recvChainKey = newCk;
      session.recvMsgNum++;
      mk = msgKey;
    }

    final sealed = SecretBox(ct, nonce: nonce, mac: Mac(mac));
    final plain = await _aesGcm.decrypt(
      sealed,
      secretKey: SecretKey(mk),
      aad: aad,
    );
    return plain;
  }

  // ─── Helpers internos ─────────────────────────────────────────

  static Future<void> _skipMessageKeys(
      RatchetSession session, int until) async {
    if (session.recvChainKey == null) return;
    const maxSkip = 100;
    if (until - session.recvMsgNum > maxSkip) {
      throw StateError('Demasiados mensajes saltados');
    }
    while (session.recvMsgNum < until) {
      final (newCk, mk) = await kdfChainKey(session.recvChainKey!);
      session.recvChainKey = newCk;
      final key =
          '${hex.encode(session.dhRemotePublic ?? [])}_${session.recvMsgNum}';
      session._skippedKeys[key] = mk;
      session.recvMsgNum++;
    }
  }

  static Future<void> _dhratchet(
      RatchetSession session, RatchetHeader header) async {
    session.prevSendChainLen = session.sendMsgNum;
    session.sendMsgNum = 0;
    session.recvMsgNum = 0;
    session.dhRemotePublic = header.dhPublic;

    // Nuevo par DH para el siguiente envio
    final newPair = await generateDHPair();

    // Recv ratchet
    final dh1 = await dhOutput(session.dhSendPair!, header.dhPublic);
    final (rk1, ck1) = await kdfRootKey(session.rootKey, dh1);
    session.rootKey = rk1;
    session.recvChainKey = ck1;

    // Send ratchet
    final dh2 = await dhOutput(newPair, header.dhPublic);
    final (rk2, ck2) = await kdfRootKey(session.rootKey, dh2);
    session.rootKey = rk2;
    session.sendChainKey = ck2;
    session.dhSendPair = newPair;
  }
}
