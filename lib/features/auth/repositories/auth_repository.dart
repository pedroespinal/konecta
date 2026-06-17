// Repositorio de autenticacion.
// Coordina el flujo de registro/login con las claves criptograficas locales.
// La conexion real al servidor relay se implementa en Fase 3.

import 'dart:math';
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

      // TODO Fase 3: subir claves publicas al servidor relay
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

  // Cerrar sesion (mantiene las claves, solo cierra la sesion activa)
  void signOut() {
    state = state.copyWith(status: AuthStatus.pinRequired);
  }

  // Borrar cuenta completamente
  Future<void> deleteAccount() async {
    await SecureKeyStore.deleteAllKeys();
    state = const AuthState(status: AuthStatus.unauthenticated);
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
