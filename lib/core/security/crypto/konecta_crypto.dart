// Motor criptografico de Konecta.
// Genera las claves del protocolo Signal (X3DH) en el dispositivo.
// Las claves PRIVADAS nunca salen del dispositivo en texto plano.

import 'dart:math';
import 'package:cryptography/cryptography.dart';
import 'package:convert/convert.dart';
import 'key_models.dart';
import 'secure_key_store.dart';

/// Resultado de generar el bundle de claves.
/// Contiene la identidad publica (para el servidor) y
/// el mapa de claves privadas (para guardar en Keystore).
class KeyGenerationResult {
  final KonectaIdentity publicIdentity;
  final Map<String, String> privateKeyMap;

  const KeyGenerationResult({
    required this.publicIdentity,
    required this.privateKeyMap,
  });
}

abstract final class KonectaCrypto {
  static final _ed25519 = Ed25519();
  static final _x25519 = X25519();
  static final _random = Random.secure();

  static int generateRegistrationId() => _random.nextInt(16380) + 1;
  static int generatePreKeyId() => _random.nextInt(0xFFFFFF) + 1;

  /// Genera el bundle completo de claves Signal Protocol para un nuevo usuario.
  /// Llama a [SecureKeyStore.saveKeyBundle] internamente.
  /// Retorna la identidad publica (para subir al servidor) y el mapa de privadas.
  static Future<KeyGenerationResult> generateAndSaveKeyBundle(
    String userId,
  ) async {
    // 1. Identity Key Pair — Ed25519
    final identityPair = await _ed25519.newKeyPair();
    final identityPublic = await identityPair.extractPublicKey();
    final identityPrivateBytes = await identityPair.extractPrivateKeyBytes();

    // 2. Signed PreKey — X25519
    final signedPreKeyPair = await _x25519.newKeyPair();
    final signedPreKeyPublic = await signedPreKeyPair.extractPublicKey();
    final signedPreKeyPrivate = await signedPreKeyPair.extractPrivateKeyBytes();
    final signedPreKeyId = generatePreKeyId();

    // 3. Firmar la Signed PreKey con la Identity Key
    final signedPreKeySignature = await _ed25519.sign(
      signedPreKeyPublic.bytes,
      keyPair: identityPair,
    );

    // 4. One-Time PreKeys — 100 claves X25519
    final otpkPublic = <KonectaOneTimePreKey>[];
    final privateMap = <String, String>{
      'identity_private': hex.encode(identityPrivateBytes),
      'identity_public': hex.encode(identityPublic.bytes),
      'signed_prekey_${signedPreKeyId}_private': hex.encode(signedPreKeyPrivate),
      'registration_id': generateRegistrationId().toString(),
    };

    for (var i = 0; i < 100; i++) {
      final pair = await _x25519.newKeyPair();
      final pub = await pair.extractPublicKey();
      final priv = await pair.extractPrivateKeyBytes();
      final keyId = generatePreKeyId();
      otpkPublic.add(KonectaOneTimePreKey(
        keyId: keyId,
        publicKeyHex: hex.encode(pub.bytes),
      ));
      privateMap['otpk_${keyId}_private'] = hex.encode(priv);
    }

    // Guardar claves privadas en Keystore/Keychain
    await SecureKeyStore.saveKeyBundle(privateMap);

    final publicIdentity = KonectaIdentity(
      userId: userId,
      registrationId: int.parse(privateMap['registration_id']!),
      identityPublicKeyHex: hex.encode(identityPublic.bytes),
      signedPreKeyPublicHex: hex.encode(signedPreKeyPublic.bytes),
      signedPreKeySignatureHex: hex.encode(signedPreKeySignature.bytes),
      signedPreKeyId: signedPreKeyId,
      oneTimePreKeys: otpkPublic,
      createdAt: DateTime.now().toUtc(),
    );

    return KeyGenerationResult(
      publicIdentity: publicIdentity,
      privateKeyMap: privateMap,
    );
  }

  /// Verifica una firma Ed25519
  static Future<bool> verifySignature({
    required List<int> message,
    required String signatureHex,
    required String publicKeyHex,
  }) async {
    try {
      final pubKey =
          SimplePublicKey(hex.decode(publicKeyHex), type: KeyPairType.ed25519);
      final sig = Signature(hex.decode(signatureHex), publicKey: pubKey);
      return await _ed25519.verify(message, signature: sig);
    } catch (_) {
      return false;
    }
  }

  /// Deriva una clave desde un PIN usando PBKDF2-SHA256
  static Future<List<int>> derivePinKey(String pin, List<int> salt) async {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: 100000,
      bits: 256,
    );
    final secretKey = await pbkdf2.deriveKeyFromPassword(
      password: pin,
      nonce: salt,
    );
    return secretKey.extractBytes();
  }

  /// Genera salt criptograficamente seguro (32 bytes)
  static List<int> generateSalt() =>
      List<int>.generate(32, (_) => _random.nextInt(256));
}
