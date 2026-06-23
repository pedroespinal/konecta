// ARCHIVO GENERADO AUTOMATICAMENTE — no editar a mano
// Generado por: dart run tool/sign_build.dart
// Esta firma criptografica certifica la autoria y fecha de compilacion.
// Es verificada en tiempo de ejecucion. Alterar este archivo invalida la firma.

abstract final class BuildSignature {
  // Payload firmado (visible, pero la firma lo hace inalterable)
  static const String signedPayload = '{"app":"Konecta","author":"Pedro Espinal","created":"2026-06-22T23:27:25.383740Z","version":"1.2.0+20","copyright":"Todos los derechos reservados 2026"}';

  // Firma Ed25519 — invalida si el payload es modificado
  static const String signature = 'e675409a4400be414814d31ae7d609c429b872e4152e5c961021c6fdb3739399a25f3e55d5ce8d2151f78b783886c6fbfcfe6e61eaf7897418682506d9ca600d';

  // Clave publica para verificacion (no es secreta)
  static const String publicKey = '0381c8a42a938dfa26b7b02698c795e6bb587b4e7dab449ed22a8d1f6c164841';

  // Metadatos rapidos (derivados del payload, para lectura interna)
  static const String buildTimestamp = '2026-06-22T23:27:25.383740Z';
  static const String buildVersion = '1.2.0+20';
  static const String buildAuthor = 'Pedro Espinal';
}
