// ARCHIVO GENERADO AUTOMATICAMENTE — no editar a mano
// Generado por: dart run tool/sign_build.dart
// Esta firma criptografica certifica la autoria y fecha de compilacion.
// Es verificada en tiempo de ejecucion. Alterar este archivo invalida la firma.

abstract final class BuildSignature {
  // Payload firmado (visible, pero la firma lo hace inalterable)
  static const String signedPayload = '{"app":"Konecta","author":"Pedro Espinal","created":"2026-06-19T22:02:14.211256Z","version":"1.2.0+14","copyright":"Todos los derechos reservados 2026"}';

  // Firma Ed25519 — invalida si el payload es modificado
  static const String signature = '9628038a2a92d00c00b1dd3a6d21ed435c31d18c6038e5cd52afa4ba5f318403acc4a7750f5f68cd1d9db9bc27d2b20737eef5109e8fd094b6cdb698e5707e04';

  // Clave publica para verificacion (no es secreta)
  static const String publicKey = '0381c8a42a938dfa26b7b02698c795e6bb587b4e7dab449ed22a8d1f6c164841';

  // Metadatos rapidos (derivados del payload, para lectura interna)
  static const String buildTimestamp = '2026-06-19T22:02:14.211256Z';
  static const String buildVersion = '1.2.0+14';
  static const String buildAuthor = 'Pedro Espinal';
}
