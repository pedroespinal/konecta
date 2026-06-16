import 'dart:typed_data';
import 'package:convert/convert.dart';
import 'package:cryptography/cryptography.dart';
import 'key_models.dart';

// Extended Triple Diffie-Hellman (X3DH) — Signal Protocol
// https://signal.org/docs/specifications/x3dh/
//
// Permite establecer una sesion cifrada con Forward Secrecy antes de que
// el receptor este en linea. El emisor usa el PreKeyBundle publico del receptor.
//
// DH outcomes:
//   DH1 = DH(IK_A, SPK_B)
//   DH2 = DH(EK_A, IK_B)
//   DH3 = DH(EK_A, SPK_B)
//   DH4 = DH(EK_A, OPK_B)   (si hay One-Time PreKey disponible)
//   SK  = KDF(DH1 || DH2 || DH3 [|| DH4])

abstract final class X3DH {
  static final _x25519 = X25519();
  static final _hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);

  static const _info = 'konecta-x3dh-v1';
  static const _saltLen = 32;

  // ─── Emisor ────────────────────────────────────────────────────

  /// Calcula el shared secret SK del lado del EMISOR (Alice).
  /// Requiere el PreKeyBundle publico de Bob.
  static Future<X3DHResult> calculateSenderSK({
    required SimpleKeyPair aliceIdentityPair, // Ed25519 — se convierte a X25519
    required KonectaIdentity bobBundle,
    KonectaOneTimePreKey? bobOTPK,
  }) async {
    // Ephemeral key pair
    final ephemeralPair = await _x25519.newKeyPair();
    final ephemeralPublic =
        (await ephemeralPair.extractPublicKey()).bytes;

    // Convertir IK_A Ed25519 → X25519 para el calculo DH
    // (En produccion se usa ed25519_to_curve25519; aqui se firma con Ed25519 y
    // se usa un par X25519 independiente — la identidad ya guarda ambos)
    final aliceIKPub =
        (await aliceIdentityPair.extractPublicKey()).bytes;

    // DH1 = DH(IK_A, SPK_B)
    final spkBPublic =
        SimplePublicKey(hex.decode(bobBundle.signedPreKeyPublicHex),
            type: KeyPairType.x25519);
    final dh1 = await _dh(aliceIdentityPair, spkBPublic);

    // DH2 = DH(EK_A, IK_B)
    final ikBPublic = SimplePublicKey(hex.decode(bobBundle.identityPublicKeyHex),
        type: KeyPairType.x25519);
    final dh2 = await _dh(ephemeralPair, ikBPublic);

    // DH3 = DH(EK_A, SPK_B)
    final dh3 = await _dh(ephemeralPair, spkBPublic);

    // DH4 = DH(EK_A, OPK_B) — opcional
    List<int>? dh4;
    String? otpkIdUsed;
    if (bobOTPK != null) {
      final otpkPublic = SimplePublicKey(
          hex.decode(bobOTPK.publicKeyHex),
          type: KeyPairType.x25519);
      dh4 = await _dh(ephemeralPair, otpkPublic);
      otpkIdUsed = bobOTPK.keyId.toString();
    }

    final dhInputs = [dh1, dh2, dh3];
    if (dh4 != null) dhInputs.add(dh4);
    final sk = await _kdf(dhInputs);

    return X3DHResult(
      sharedKey: sk,
      ephemeralPublicHex: hex.encode(ephemeralPublic),
      aliceIdentityPublicHex: hex.encode(aliceIKPub),
      otpkIdUsed: otpkIdUsed,
    );
  }

  // ─── Receptor ──────────────────────────────────────────────────

  /// Calcula el shared secret SK del lado del RECEPTOR (Bob).
  static Future<List<int>> calculateReceiverSK({
    required SimpleKeyPair bobIdentityPair,
    required SimpleKeyPair bobSignedPreKeyPair,
    SimpleKeyPair? bobOTPKPair,
    required String aliceIdentityPublicHex,
    required String aliceEphemeralPublicHex,
  }) async {
    final aliceIKPub = SimplePublicKey(
        hex.decode(aliceIdentityPublicHex),
        type: KeyPairType.x25519);
    final aliceEKPub = SimplePublicKey(
        hex.decode(aliceEphemeralPublicHex),
        type: KeyPairType.x25519);

    // DH1 = DH(SPK_B, IK_A)
    final dh1 = await _dh(bobSignedPreKeyPair, aliceIKPub);

    // DH2 = DH(IK_B, EK_A)
    final dh2 = await _dh(bobIdentityPair, aliceEKPub);

    // DH3 = DH(SPK_B, EK_A)
    final dh3 = await _dh(bobSignedPreKeyPair, aliceEKPub);

    // DH4 = DH(OPK_B, EK_A)
    List<int>? dh4;
    if (bobOTPKPair != null) {
      dh4 = await _dh(bobOTPKPair, aliceEKPub);
    }

    final inputs = [dh1, dh2, dh3];
    if (dh4 != null) inputs.add(dh4);
    return _kdf(inputs);
  }

  // ─── Helpers ──────────────────────────────────────────────────

  static Future<List<int>> _dh(
      SimpleKeyPair pair, SimplePublicKey pub) async {
    final shared = await _x25519.sharedSecretKey(
        keyPair: pair, remotePublicKey: pub);
    return shared.extractBytes();
  }

  static Future<List<int>> _kdf(List<List<int>> dhOutputs) async {
    final combined = dhOutputs.expand((x) => x).toList();
    final salt = Uint8List(_saltLen); // zeros
    final info = _info.codeUnits;
    final key = await _hkdf.deriveKey(
      secretKey: SecretKey(combined),
      nonce: salt,
      info: info,
    );
    return key.extractBytes();
  }
}

class X3DHResult {
  final List<int> sharedKey;
  final String ephemeralPublicHex;
  final String aliceIdentityPublicHex;
  final String? otpkIdUsed;

  const X3DHResult({
    required this.sharedKey,
    required this.ephemeralPublicHex,
    required this.aliceIdentityPublicHex,
    this.otpkIdUsed,
  });
}
