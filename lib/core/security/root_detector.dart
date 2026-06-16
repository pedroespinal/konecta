import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

// Detecta si el dispositivo tiene root (Android) o jailbreak (iOS).
// Usa solo Dart — sin dependencia extra para no aumentar el attack surface.
abstract final class RootDetector {
  static const _channel = MethodChannel('com.pedroespinal.konecta/security');

  // Archivos y binarios tipicos de root en Android
  static const _rootBinaries = [
    '/system/app/Superuser.apk',
    '/system/xbin/su',
    '/system/bin/su',
    '/sbin/su',
    '/data/local/su',
    '/data/local/bin/su',
    '/data/local/xbin/su',
    '/system/sd/xbin/su',
    '/system/bin/failsafe/su',
    '/data/local/tmp/su',
    '/system/app/SuperSU.apk',
    '/system/app/Supersu.apk',
    '/system/etc/init.d/99SuperSUDaemon',
    '/dev/com.koushikdutta.superuser.daemon/',
    '/system/xbin/daemonsu',
    '/system/xbin/busybox',
    '/system/bin/busybox',
    '/sbin/busybox',
  ];

  static Future<bool> isRooted() async {
    if (kDebugMode) return false; // No bloquear en desarrollo
    if (Platform.isAndroid) return _checkAndroid();
    if (Platform.isIOS) return _checkIOS();
    return false;
  }

  static Future<bool> _checkAndroid() async {
    // 1. Verificar binarios de root
    for (final path in _rootBinaries) {
      if (File(path).existsSync()) return true;
    }

    // 2. Intentar ejecutar 'which su' — si funciona, hay root
    try {
      final result = await Process.run('which', ['su'],
          runInShell: false);
      if ((result.stdout as String).trim().isNotEmpty) return true;
    } catch (_) {}

    // 3. Verificar via canal nativo (Kotlin detecta Magisk, paquetes root)
    try {
      final isRooted =
          await _channel.invokeMethod<bool>('isRooted') ?? false;
      if (isRooted) return true;
    } on PlatformException {
      // Si el canal falla, continuar con las otras verificaciones
    }

    // 4. Intentar escribir en /data — solo root puede hacerlo fuera de /data/data/...
    try {
      final testFile = File('/data/.konecta_root_test');
      testFile.writeAsStringSync('test');
      testFile.deleteSync();
      return true; // Pudimos escribir — tiene root
    } catch (_) {}

    return false;
  }

  static Future<bool> _checkIOS() async {
    // Archivos tipicos de jailbreak
    const jailbreakPaths = [
      '/Applications/Cydia.app',
      '/Library/MobileSubstrate/MobileSubstrate.dylib',
      '/bin/bash',
      '/usr/sbin/sshd',
      '/etc/apt',
      '/private/var/lib/apt/',
      '/usr/bin/ssh',
      '/private/var/tmp/cydia.log',
      '/Applications/FakeCarrier.app',
      '/Applications/Icy.app',
      '/Applications/IntelliScreen.app',
      '/Applications/MxTube.app',
      '/Applications/RockApp.app',
      '/Applications/SBSettings.app',
      '/Applications/WinterBoard.app',
    ];

    for (final path in jailbreakPaths) {
      if (File(path).existsSync()) return true;
    }

    // Intentar escribir fuera del sandbox
    try {
      File('/private/jailbreak_test.txt')
          .writeAsStringSync('test');
      return true;
    } catch (_) {}

    return false;
  }

  // Verifica si se está depurando via USB en modo no-dev
  static Future<bool> isDebugged() async {
    if (kDebugMode) return false;
    try {
      final result =
          await _channel.invokeMethod<bool>('isDebugged') ?? false;
      return result;
    } on PlatformException {
      return false;
    }
  }
}
