// Almacenamiento seguro de todas las claves privadas.
// Usa flutter_secure_storage (Android Keystore / iOS Keychain).
// Las claves NUNCA se escriben en SharedPreferences ni en disco sin cifrar.

import 'dart:convert';
import 'package:convert/convert.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'key_models.dart';
import 'konecta_crypto.dart';

class SecureKeyStore {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // ── Claves Signal Protocol ────────────────────────────────────────────────

  static Future<void> saveKeyBundle(Map<String, String> privateKeys) async {
    for (final entry in privateKeys.entries) {
      await _storage.write(key: 'kc_key_${entry.key}', value: entry.value);
    }
  }

  static Future<String?> readKey(String keyName) =>
      _storage.read(key: 'kc_key_$keyName');

  static Future<void> deleteKey(String keyName) =>
      _storage.delete(key: 'kc_key_$keyName');

  static Future<bool> hasIdentityKey() async {
    final key = await _storage.read(key: 'kc_key_identity_private');
    return key != null && key.isNotEmpty;
  }

  // ── PIN ───────────────────────────────────────────────────────────────────

  static Future<void> savePinHash(String pin) async {
    final salt = KonectaCrypto.generateSalt();
    final derived = await KonectaCrypto.derivePinKey(pin, salt);
    await _storage.write(key: 'kc_pin_salt', value: hex.encode(salt));
    await _storage.write(key: 'kc_pin_hash', value: hex.encode(derived));
  }

  static Future<bool> verifyPin(String pin) async {
    final saltHex = await _storage.read(key: 'kc_pin_salt');
    final storedHash = await _storage.read(key: 'kc_pin_hash');
    if (saltHex == null || storedHash == null) return false;
    final derived = await KonectaCrypto.derivePinKey(pin, hex.decode(saltHex));
    return hex.encode(derived) == storedHash;
  }

  static Future<bool> hasPin() async {
    final hash = await _storage.read(key: 'kc_pin_hash');
    return hash != null && hash.isNotEmpty;
  }

  static Future<void> deletePin() async {
    await _storage.delete(key: 'kc_pin_salt');
    await _storage.delete(key: 'kc_pin_hash');
  }

  // ── Perfil de usuario ─────────────────────────────────────────────────────

  static Future<void> saveUserProfile(KonectaUserProfile profile) async {
    final json = jsonEncode({
      'userId': profile.userId,
      'displayName': profile.displayName,
      'phone': profile.phone,
      'avatarPath': profile.avatarPath,
      'bio': profile.bio,
      'registeredAt': profile.registeredAt.toIso8601String(),
      'hasPin': profile.hasPin,
      'hasBiometrics': profile.hasBiometrics,
    });
    await _storage.write(key: 'kc_user_profile', value: json);
  }

  static Future<KonectaUserProfile?> loadUserProfile() async {
    final raw = await _storage.read(key: 'kc_user_profile');
    if (raw == null) return null;
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return KonectaUserProfile(
      userId: map['userId'] as String,
      displayName: map['displayName'] as String,
      phone: map['phone'] as String?,
      avatarPath: map['avatarPath'] as String?,
      bio: map['bio'] as String?,
      registeredAt: DateTime.parse(map['registeredAt'] as String),
      hasPin: map['hasPin'] as bool? ?? false,
      hasBiometrics: map['hasBiometrics'] as bool? ?? false,
    );
  }

  // ── Limpieza completa (logout / borrar cuenta) ─────────────────────────────

  static Future<void> deleteAllKeys() async {
    await _storage.deleteAll();
  }

  // ── Clave de sesion cifrada (para backup) ─────────────────────────────────

  static Future<String> exportEncryptedBackupKey(String pin) async {
    final identityPrivate = await readKey('identity_private');
    if (identityPrivate == null) throw StateError('No hay clave de identidad');

    final salt = KonectaCrypto.generateSalt();
    final aesKey = await KonectaCrypto.derivePinKey(pin, salt);

    final aesGcm = AesGcm.with256bits();
    final secretKey = SecretKey(aesKey);
    final nonce = aesGcm.newNonce();

    final encrypted = await aesGcm.encrypt(
      identityPrivate.codeUnits,
      secretKey: secretKey,
      nonce: nonce,
    );

    final payload = {
      'salt': hex.encode(salt),
      'nonce': hex.encode(nonce),
      'ciphertext': hex.encode(encrypted.cipherText),
      'mac': hex.encode(encrypted.mac.bytes),
    };
    return jsonEncode(payload);
  }
}
