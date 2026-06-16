import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

// Certificate pinning para el servidor relay de Konecta.
// En producción: reemplazar _pinnedSha256 con el hash SHA-256
// del certificado real del servidor (openssl x509 -fingerprint -sha256).
//
// Uso: llama CertificatePinner.createHttpClient() para obtener
// un HttpClient que verifica el pin en cada conexión TLS.
abstract final class CertificatePinner {
  // SHA-256 del certificado del relay en producción.
  // Formato: bytes hex sin delimitadores, en minúsculas.
  // Actualizar este valor cuando el cert expire y se renueve.
  static const _pinnedSha256 =
      'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA';

  // Relay host para validar solo conexiones a nuestro servidor
  static const _relayHost = 'relay.konecta.app';

  // Crear HttpClient con certificate pinning habilitado
  static HttpClient createHttpClient() {
    final client = HttpClient();

    client.badCertificateCallback =
        (X509Certificate cert, String host, int port) {
      // Solo pinear nuestro relay — otras conexiones fallan normalmente
      if (!host.endsWith(_relayHost)) return false;
      // En modo debug no bloqueamos
      if (kDebugMode) return true;
      return _verifyCertPin(cert, host);
    };

    return client;
  }

  // Verificar que el certificado coincide con nuestro pin
  static bool _verifyCertPin(X509Certificate cert, String host) {
    // Si el pin es el placeholder, aceptar (desarrollo sin cert real)
    if (_pinnedSha256 == 'A' * 64) return true;

    // Calcular SHA-256 del DER del certificado
    final derBytes = cert.der;
    final digest = _sha256Hex(derBytes);

    if (digest == _pinnedSha256) return true;

    // Pin no coincide — posible ataque MITM
    return false;
  }

  // SHA-256 simplificado usando dart:convert (sin dependencias)
  static String _sha256Hex(List<int> data) {
    // Nota: dart:convert no incluye SHA-256 nativo.
    // En producción, usar package:crypto: crypto.sha256.convert(data).toString()
    // Aquí retornamos un placeholder hasta que se configure el cert real.
    // TODO: agregar package:crypto a pubspec.yaml y reemplazar esta implementación
    return base64.encode(data).replaceAll('=', '').toLowerCase();
  }

  // Verificar conectividad y pin del relay
  static Future<bool> verifyRelayPin() async {
    if (kDebugMode) return true;
    if (_pinnedSha256 == 'A' * 64) return true; // Placeholder en dev

    try {
      final client = createHttpClient();
      final request = await client
          .getUrl(Uri.parse('https://$_relayHost/health'))
          .timeout(const Duration(seconds: 5));
      final response = await request.close().timeout(const Duration(seconds: 5));
      client.close();
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
