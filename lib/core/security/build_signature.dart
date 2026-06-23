// ARCHIVO GENERADO AUTOMATICAMENTE — no editar a mano
// Generado por: dart run tool/sign_build.dart
// Esta firma criptografica certifica la autoria y fecha de compilacion.
// Es verificada en tiempo de ejecucion. Alterar este archivo invalida la firma.

abstract final class BuildSignature {
  // Payload firmado (visible, pero la firma lo hace inalterable)
  static const String signedPayload = '{"app":"Konecta","author":"Pedro Espinal","created":"2026-06-23T13:07:51.796852Z","version":"1.2.2+22","copyright":"Todos los derechos reservados 2026"}';

  // Firma Ed25519 — invalida si el payload es modificado
  static const String signature = 'ca965d033922f4ed78f71f6222a7e6d720ebe640a5a4b624bfd72c8cf5bec3762cd20f8df728f42d405aa4bc1be63eba8b36308844b62d3d9ae8143a0e24d607';

  // Clave publica para verificacion (no es secreta)
  static const String publicKey = '0381c8a42a938dfa26b7b02698c795e6bb587b4e7dab449ed22a8d1f6c164841';

  // Metadatos rapidos (derivados del payload, para lectura interna)
  static const String buildTimestamp = '2026-06-23T13:07:51.796852Z';
  static const String buildVersion = '1.2.2+22';
  static const String buildAuthor = 'Pedro Espinal';
}
