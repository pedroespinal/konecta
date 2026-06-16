import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_version.dart';

/// Resultado de la verificación de actualización.
class UpdateInfo {
  final bool updateAvailable;
  final bool forceUpdate;       // true = no se puede descartar
  final String latestVersion;
  final String releaseNotes;
  final String updateUrl;

  const UpdateInfo({
    required this.updateAvailable,
    required this.forceUpdate,
    required this.latestVersion,
    required this.releaseNotes,
    required this.updateUrl,
  });

  static const none = UpdateInfo(
    updateAvailable: false,
    forceUpdate: false,
    latestVersion: AppVersion.version,
    releaseNotes: '',
    updateUrl: '',
  );
}

/// Claves en Firebase Remote Config.
abstract final class _RCKey {
  static const latestVersion    = 'latest_version';
  static const minVersion       = 'min_required_version';
  static const releaseNotes     = 'release_notes_es';
  static const updateUrl        = 'update_url';
  static const updateEnabled    = 'update_check_enabled';
}

/// Servicio que consulta Firebase Remote Config para saber si hay
/// una nueva versión disponible. No bloquea el arranque — se llama
/// de forma asíncrona y solo muestra el popup si hay novedades.
abstract final class UpdateChecker {
  static FirebaseRemoteConfig? _rc;

  static Future<void> _ensureInitialized() async {
    _rc ??= FirebaseRemoteConfig.instance;
    await _rc!.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(seconds: 10),
      // En producción usar 1 hora; en debug 0 para pruebas instantáneas
      minimumFetchInterval:
          kDebugMode ? Duration.zero : const Duration(hours: 1),
    ));

    // Valores por defecto (funcionan offline o si RC no está configurado)
    await _rc!.setDefaults({
      _RCKey.latestVersion : AppVersion.version,
      _RCKey.minVersion    : '1.0.0',
      _RCKey.releaseNotes  : '',
      _RCKey.updateUrl     : 'https://github.com/pedroespinal/konecta/releases/latest',
      _RCKey.updateEnabled : true,
    });
  }

  /// Descarga la configuración y retorna info de actualización.
  /// Si falla la red o RC no está activo retorna [UpdateInfo.none].
  static Future<UpdateInfo> check() async {
    try {
      await _ensureInitialized();
      await _rc!.fetchAndActivate();

      final enabled = _rc!.getBool(_RCKey.updateEnabled);
      if (!enabled) return UpdateInfo.none;

      final latest  = _rc!.getString(_RCKey.latestVersion).trim();
      final minReq  = _rc!.getString(_RCKey.minVersion).trim();
      final notes   = _rc!.getString(_RCKey.releaseNotes).trim();
      final url     = _rc!.getString(_RCKey.updateUrl).trim();

      final current  = AppVersion.version;
      final hasUpdate    = _isNewer(latest, current);
      final mustUpdate   = _isNewer(minReq, current);

      if (!hasUpdate) return UpdateInfo.none;

      return UpdateInfo(
        updateAvailable: true,
        forceUpdate    : mustUpdate,
        latestVersion  : latest,
        releaseNotes   : notes,
        updateUrl      : url,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[UpdateChecker] error: $e');
      return UpdateInfo.none;
    }
  }

  /// Compara semver simplificado: "1.2.3" > "1.0.6" → true
  static bool _isNewer(String candidate, String current) {
    final c = _parse(candidate);
    final v = _parse(current);
    for (int i = 0; i < 3; i++) {
      if (c[i] > v[i]) return true;
      if (c[i] < v[i]) return false;
    }
    return false;
  }

  static List<int> _parse(String ver) {
    final parts = ver.split('.');
    return List.generate(3, (i) => i < parts.length
        ? int.tryParse(parts[i]) ?? 0 : 0);
  }
}
