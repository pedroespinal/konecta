import 'dart:async';
import 'package:flutter/foundation.dart';
import 'root_detector.dart';
import 'frida_detector.dart';
import 'certificate_pinner.dart';

// Monitor de integridad del sistema.
// Se ejecuta al inicio de la app y reporta anomalias internamente.
// En produccion: cuando shouldTerminate es true, el llamador puede
// cerrar la app o mostrar una pantalla de error genérica.
abstract final class IntegrityMonitor {
  static final List<IntegrityEvent> _events = [];
  static bool _checked = false;

  // Ejecutar todas las verificaciones de seguridad al inicio.
  // Retorna true si la app debe continuar, false si debe terminar.
  static Future<bool> runStartupChecks() async {
    if (_checked) return !shouldTerminate;
    _checked = true;

    await Future.wait([
      _checkRoot(),
      _checkFrida(),
      _checkCertPin(),
    ]);

    if (kDebugMode && _events.isNotEmpty) {
      for (final e in _events) {
        // ignore: avoid_print
        print('[IntegrityMonitor] ${e.type}: ${e.detail}');
      }
    }

    return !shouldTerminate;
  }

  static Future<void> _checkRoot() async {
    final rooted = await RootDetector.isRooted();
    if (rooted) reportRootDetected();

    final debugged = await RootDetector.isDebugged();
    if (debugged) reportDebuggerAttached();
  }

  static Future<void> _checkFrida() async {
    final frida = await FridaDetector.isFridaDetected();
    if (frida) {
      _events.add(IntegrityEvent(
        type: 'FRIDA_DETECTED',
        detail: 'Frida/Xposed hooking framework detectado',
        timestamp: DateTime.now().toUtc(),
        severity: IntegritySeverity.critical,
      ));
      _scheduleReport();
    }
  }

  static Future<void> _checkCertPin() async {
    // Solo verificar pin si hay red disponible (no fallar en offline)
    try {
      final pinOk = await CertificatePinner.verifyRelayPin()
          .timeout(const Duration(seconds: 6));
      if (!pinOk) {
        _events.add(IntegrityEvent(
          type: 'CERT_PIN_FAILED',
          detail: 'Certificado del relay no coincide — posible MITM',
          timestamp: DateTime.now().toUtc(),
          severity: IntegritySeverity.critical,
        ));
        _scheduleReport();
      }
    } on TimeoutException {
      // No hay red — no registrar como anomalia
    } catch (_) {
      // Error inesperado — no registrar como anomalia de seguridad
    }
  }

  static void reportTampering(String detail) {
    _events.add(IntegrityEvent(
      type: 'TAMPERING',
      detail: detail,
      timestamp: DateTime.now().toUtc(),
      severity: IntegritySeverity.critical,
    ));
    _scheduleReport();
  }

  static void reportRootDetected() {
    _events.add(IntegrityEvent(
      type: 'ROOT_DETECTED',
      detail: 'El dispositivo tiene acceso root o jailbreak',
      timestamp: DateTime.now().toUtc(),
      severity: IntegritySeverity.high,
    ));
    _scheduleReport();
  }

  static void reportDebuggerAttached() {
    _events.add(IntegrityEvent(
      type: 'DEBUGGER',
      detail: 'Depurador detectado en tiempo de ejecucion',
      timestamp: DateTime.now().toUtc(),
      severity: IntegritySeverity.high,
    ));
    _scheduleReport();
  }

  // true si se detectó al menos un evento crítico
  static bool get shouldTerminate => _events.any(
      (e) => e.severity == IntegritySeverity.critical);

  static bool get hasAnomalies => _events.isNotEmpty;
  static List<IntegrityEvent> get events => List.unmodifiable(_events);

  static void _scheduleReport() {
    // Reporte anónimo al servidor sin datos personales — implementar en v2
  }
}

enum IntegritySeverity { low, high, critical }

class IntegrityEvent {
  final String type;
  final String detail;
  final DateTime timestamp;
  final IntegritySeverity severity;

  const IntegrityEvent({
    required this.type,
    required this.detail,
    required this.timestamp,
    this.severity = IntegritySeverity.low,
  });
}
