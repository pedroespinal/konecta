// ARCHIVO GENERADO AUTOMATICAMENTE — no editar a mano
// Generado por: dart run tool/sign_build.dart
// Esta firma criptografica certifica la autoria y fecha de compilacion.
// Es verificada en tiempo de ejecucion. Alterar este archivo invalida la firma.

abstract final class BuildSignature {
  // Payload firmado (visible, pero la firma lo hace inalterable)
  static const String signedPayload = '{"app":"Konecta","author":"Pedro Espinal","created":"2026-06-17T13:12:45.587555Z","version":"1.1.0+12","copyright":"Todos los derechos reservados 2026"}';

  // Firma Ed25519 — invalida si el payload es modificado
  static const String signature = '3d2c96246d3bca0bd3d88c4869254b5bea052a2b240a99df8bb0c4c063fc0a405c0f4928cf8e3c7873b6fbcfd6ca4b97e02ebda3f64397fc9be21a221557700e';

  // Clave publica para verificacion (no es secreta)
  static const String publicKey = '0381c8a42a938dfa26b7b02698c795e6bb587b4e7dab449ed22a8d1f6c164841';

  // Metadatos rapidos (derivados del payload, para lectura interna)
  static const String buildTimestamp = '2026-06-17T13:12:45.587555Z';
  static const String buildVersion = '1.1.0+12';
  static const String buildAuthor = 'Pedro Espinal';
}
