// ARCHIVO GENERADO AUTOMATICAMENTE — no editar a mano
// Generado por: dart run tool/sign_build.dart
// Esta firma criptografica certifica la autoria y fecha de compilacion.
// Es verificada en tiempo de ejecucion. Alterar este archivo invalida la firma.

abstract final class BuildSignature {
  // Payload firmado (visible, pero la firma lo hace inalterable)
  static const String signedPayload = '{"app":"Konecta","author":"Pedro Espinal","created":"2026-06-17T11:56:20.365812Z","version":"1.0.8+10","copyright":"Todos los derechos reservados 2026"}';

  // Firma Ed25519 — invalida si el payload es modificado
  static const String signature = 'ddf30db6f6e7a38b3b234606dd45b5760d85b0f53a6025f20f3b21e3079d7490fc5be80c9e3435f8cda7b8d86fb8d93b4cf03750481d11b1a16d5064a35aac00';

  // Clave publica para verificacion (no es secreta)
  static const String publicKey = '0381c8a42a938dfa26b7b02698c795e6bb587b4e7dab449ed22a8d1f6c164841';

  // Metadatos rapidos (derivados del payload, para lectura interna)
  static const String buildTimestamp = '2026-06-17T11:56:20.365812Z';
  static const String buildVersion = '1.0.8+10';
  static const String buildAuthor = 'Pedro Espinal';
}
