import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/security/crypto/konecta_crypto.dart';
import '../../../core/security/crypto/secure_key_store.dart';
import '../../../core/security/crypto/key_models.dart';

enum AuthStatus { unknown, unauthenticated, pinRequired, authenticated }

class AuthState {
  final AuthStatus status;
  final KonectaUserProfile? profile;
  final String? error;
  final bool isLoading;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.profile,
    this.error,
    this.isLoading = false,
  });

  AuthState copyWith({
    AuthStatus? status,
    KonectaUserProfile? profile,
    String? error,
    bool? isLoading,
  }) =>
      AuthState(
        status: status ?? this.status,
        profile: profile ?? this.profile,
        error: error,
        isLoading: isLoading ?? this.isLoading,
      );
}

class AuthRepository extends StateNotifier<AuthState> {
  AuthRepository() : super(const AuthState());

  // Verifica si ya hay una sesion activa al arrancar la app
  Future<void> checkSession() async {
    state = state.copyWith(isLoading: true);
    try {
      final profile = await SecureKeyStore.loadUserProfile();
      final hasKeys = await SecureKeyStore.hasIdentityKey();

      if (profile == null || !hasKeys) {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          isLoading: false,
        );
        return;
      }

      final hasPin = await SecureKeyStore.hasPin();
      state = state.copyWith(
        status: hasPin ? AuthStatus.pinRequired : AuthStatus.authenticated,
        profile: profile,
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        isLoading: false,
      );
    }
  }

  // Registrar nuevo usuario
  Future<KonectaIdentity> register({
    required String displayName,
    String? phone,
    String? avatarPath,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Generar ID de usuario unico
      final userId = _generateUserId();

      // Generar todas las claves Signal Protocol y guardarlas en Keystore
      final result = await KonectaCrypto.generateAndSaveKeyBundle(userId);
      final identity = result.publicIdentity;

      // Guardar perfil
      final profile = KonectaUserProfile(
        userId: userId,
        displayName: displayName,
        phone: phone,
        avatarPath: avatarPath,
        registeredAt: DateTime.now().toUtc(),
      );
      await SecureKeyStore.saveUserProfile(profile);

      state = state.copyWith(
        status: AuthStatus.authenticated,
        profile: profile,
        isLoading: false,
      );

      // Publicar claves públicas al relay (best-effort, no bloquea el registro)
      _publishKeysToRelay(identity);
      return identity;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error durante el registro: $e',
      );
      rethrow;
    }
  }

  // Configurar PIN
  Future<void> setupPin(String pin) async {
    await SecureKeyStore.savePinHash(pin);
    final profile = state.profile?.copyWith(hasPin: true);
    if (profile != null) {
      await SecureKeyStore.saveUserProfile(profile);
      state = state.copyWith(profile: profile);
    }
  }

  // Verificar PIN al desbloquear
  Future<bool> verifyPin(String pin) async {
    final valid = await SecureKeyStore.verifyPin(pin);
    if (valid) {
      state = state.copyWith(status: AuthStatus.authenticated);
    }
    return valid;
  }

  // Marcar biometria activada
  Future<void> setBiometricsEnabled(bool enabled) async {
    final profile = state.profile?.copyWith(hasBiometrics: enabled);
    if (profile != null) {
      await SecureKeyStore.saveUserProfile(profile);
      state = state.copyWith(profile: profile);
    }
  }

  // Desbloqueo biometrico exitoso
  void onBiometricSuccess() {
    state = state.copyWith(status: AuthStatus.authenticated);
  }

  // Actualizar foto de perfil
  Future<void> updateAvatarPath(String path) async {
    final profile = state.profile?.copyWith(avatarPath: path);
    if (profile != null) {
      await SecureKeyStore.saveUserProfile(profile);
      state = state.copyWith(profile: profile);
    }
  }

  // PIN de pánico (modo decoy)
  Future<void> setupDecoyPin(String pin) => SecureKeyStore.saveDecoyPinHash(pin);
  Future<void> clearDecoyPin() => SecureKeyStore.deleteDecoyPin();
  Future<bool> hasDecoyPin() => SecureKeyStore.hasDecoyPin();

  // Cerrar sesion (mantiene las claves, solo cierra la sesion activa)
  void signOut() {
    state = state.copyWith(status: AuthStatus.pinRequired);
  }

  // Borrar cuenta completamente
  Future<void> deleteAccount() async {
    await SecureKeyStore.deleteAllKeys();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  static const _relayBase = 'https://relay-production-38eb.up.railway.app';

  Future<void> _publishKeysToRelay(KonectaIdentity identity) async {
    try {
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 10);
      final req =
          await client.postUrl(Uri.parse('$_relayBase/publish-keys'));
      req.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      req.write(jsonEncode(identity.toJson()));
      final res = await req.close();
      await res.drain<void>();
      debugPrint('[AUTH] claves publicadas en relay para ${identity.userId}');
    } catch (e) {
      debugPrint('[AUTH] no se pudo publicar claves (se reintentará en login): $e');
    }
  }

  // Republicar claves al relay si el relay las perdió (ej. reinicio en Railway)
  Future<void> republishKeysIfNeeded() async {
    try {
      final profile = state.profile;
      if (profile == null) return;
      final identityPubHex =
          await SecureKeyStore.readKey('identity_public') ?? '';
      if (identityPubHex.isEmpty) return;

      // Chequear si el relay ya las tiene
      final check = HttpClient()..connectionTimeout = const Duration(seconds: 5);
      final checkReq = await check
          .getUrl(Uri.parse('$_relayBase/keys/${profile.userId}'));
      final checkRes = await checkReq.close();
      await checkRes.drain<void>();
      if (checkRes.statusCode == 200) return;

      // Republicar
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 10);
      final req =
          await client.postUrl(Uri.parse('$_relayBase/publish-keys'));
      req.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      req.write(jsonEncode({
        'userId': profile.userId,
        'identityPublicKey': identityPubHex,
      }));
      final res = await req.close();
      await res.drain<void>();
      debugPrint('[AUTH] claves republicadas para ${profile.userId}');
    } catch (e) {
      debugPrint('[AUTH] republish error: $e');
    }
  }

  String _generateUserId() {
    final rand = Random.secure();
    final bytes = List<int>.generate(16, (_) => rand.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}

final authProvider = StateNotifierProvider<AuthRepository, AuthState>(
  (_) => AuthRepository(),
);
