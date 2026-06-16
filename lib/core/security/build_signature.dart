// ARCHIVO GENERADO AUTOMATICAMENTE — no editar a mano
// Generado por: dart run tool/sign_build.dart
// Esta firma criptografica certifica la autoria y fecha de compilacion.
// Es verificada en tiempo de ejecucion. Alterar este archivo invalida la firma.

abstract final class BuildSignature {
  // Payload firmado (visible, pero la firma lo hace inalterable)
  static const String signedPayload = '{"app":"Konecta","author":"Pedro Espinal","created":"2026-06-16T22:15:24.360724Z","version":"1.0.6+8","copyright":"Todos los derechos reservados 2026"}';

  // Firma Ed25519 — invalida si el payload es modificado
  static const String signature = '2a0f3b4d3348bcf753fccbf2a6d0763d0263f95d5fc1db84b0f1b1cb912fbf4af71b9cb52822027a05c5de9cc48eca555379b78a380f7d4e203c7f617f1bbd00';

  // Clave publica para verificacion (no es secreta)
  static const String publicKey = '0381c8a42a938dfa26b7b02698c795e6bb587b4e7dab449ed22a8d1f6c164841';

  // Metadatos rapidos (derivados del payload, para lectura interna)
  static const String buildTimestamp = '2026-06-16T22:15:24.360724Z';
  static const String buildVersion = '1.0.6+8';
  static const String buildAuthor = 'Pedro Espinal';
}
