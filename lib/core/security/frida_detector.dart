import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

// Detecta hooks de Frida y Xposed en tiempo de ejecución.
// Frida inyecta un agente en el proceso via gadget o server.
abstract final class FridaDetector {
  static const _channel = MethodChannel('com.pedroespinal.konecta/security');

  // Puerto predeterminado del servidor Frida
  static const _fridaPort = 27042;

  // Nombres de bibliotecas de Frida que aparecen en /proc/self/maps
  static const _fridaLibs = [
    'frida-agent',
    'frida-gadget',
    'frida-inject',
    'frida-core',
    'gum-js-loop',
    'gmain',
    'linjector',
  ];

  static Future<bool> isFridaDetected() async {
    if (kDebugMode) return false;
    if (Platform.isAndroid) return _checkAndroid();
    if (Platform.isIOS) return _checkIOS();
    return false;
  }

  static Future<bool> _checkAndroid() async {
    // 1. Verificar si el puerto de Frida está abierto en localhost
    if (await _isFridaPortOpen()) return true;

    // 2. Leer /proc/self/maps buscando bibliotecas de Frida
    if (await _hasFridaInMaps()) return true;

    // 3. Verificar via canal nativo (busca paquetes Xposed, carga de agentes)
    try {
      final detected =
          await _channel.invokeMethod<bool>('isFridaDetected') ?? false;
      if (detected) return true;
    } on PlatformException {
      // Canal no disponible — continuar
    }

    return false;
  }

  static Future<bool> _isFridaPortOpen() async {
    try {
      final socket = await Socket.connect(
        InternetAddress.loopbackIPv4,
        _fridaPort,
        timeout: const Duration(milliseconds: 150),
      );
      socket.destroy();
      return true; // El puerto está abierto — Frida server corriendo
    } on SocketException {
      return false; // Bien — el puerto no responde
    }
  }

  static Future<bool> _hasFridaInMaps() async {
    try {
      final mapsFile = File('/proc/self/maps');
      if (!mapsFile.existsSync()) return false;
      final content = mapsFile.readAsStringSync().toLowerCase();
      for (final lib in _fridaLibs) {
        if (content.contains(lib.toLowerCase())) return true;
      }
    } catch (_) {}
    return false;
  }

  static Future<bool> _checkIOS() async {
    // En iOS buscar bibliotecas de Substrate/Frida inyectadas via dyld
    try {
      final detected =
          await _channel.invokeMethod<bool>('isFridaDetected') ?? false;
      return detected;
    } on PlatformException {
      return false;
    }
  }
}
