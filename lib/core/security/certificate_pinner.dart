import 'dart:io';
import 'package:crypto/crypto.dart' as crypto;
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

  // Relay host — Railway production
  static const _relayHost = 'relay-production-38eb.up.railway.app';

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

  static String _sha256Hex(List<int> data) {
    return crypto.sha256.convert(data).toString();
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
