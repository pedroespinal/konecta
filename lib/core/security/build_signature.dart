// ARCHIVO GENERADO AUTOMATICAMENTE — no editar a mano
// Generado por: dart run tool/sign_build.dart
// Esta firma criptografica certifica la autoria y fecha de compilacion.
// Es verificada en tiempo de ejecucion. Alterar este archivo invalida la firma.

abstract final class BuildSignature {
  // Payload firmado (visible, pero la firma lo hace inalterable)
  static const String signedPayload = '{"app":"Konecta","author":"Pedro Espinal","created":"2026-06-17T12:37:27.730256Z","version":"1.0.9+11","copyright":"Todos los derechos reservados 2026"}';

  // Firma Ed25519 — invalida si el payload es modificado
  static const String signature = 'a69a2190796151652a513bb299e53bfeeea7458933cdedee262501fd8f8d17e2085b935f08ed44a5480704f04cb927aaeff0cc2fd1ffa0c0d8e0fbd73369030c';

  // Clave publica para verificacion (no es secreta)
  static const String publicKey = '0381c8a42a938dfa26b7b02698c795e6bb587b4e7dab449ed22a8d1f6c164841';

  // Metadatos rapidos (derivados del payload, para lectura interna)
  static const String buildTimestamp = '2026-06-17T12:37:27.730256Z';
  static const String buildVersion = '1.0.9+11';
  static const String buildAuthor = 'Pedro Espinal';
}
