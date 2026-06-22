// ARCHIVO GENERADO AUTOMATICAMENTE — no editar a mano
// Generado por: dart run tool/sign_build.dart
// Esta firma criptografica certifica la autoria y fecha de compilacion.
// Es verificada en tiempo de ejecucion. Alterar este archivo invalida la firma.

abstract final class BuildSignature {
  // Payload firmado (visible, pero la firma lo hace inalterable)
  static const String signedPayload = '{"app":"Konecta","author":"Pedro Espinal","created":"2026-06-22T16:21:07.984443Z","version":"1.2.0+19","copyright":"Todos los derechos reservados 2026"}';

  // Firma Ed25519 — invalida si el payload es modificado
  static const String signature = '70399528efb0440d1b13cccd778fac90277cfd0f8d3b61093633765be3442f92b9a2e3f4b0779f84fd2be1ec46ad350fc991f51a9a92c499f7a60cd0e7252f00';

  // Clave publica para verificacion (no es secreta)
  static const String publicKey = '0381c8a42a938dfa26b7b02698c795e6bb587b4e7dab449ed22a8d1f6c164841';

  // Metadatos rapidos (derivados del payload, para lectura interna)
  static const String buildTimestamp = '2026-06-22T16:21:07.984443Z';
  static const String buildVersion = '1.2.0+19';
  static const String buildAuthor = 'Pedro Espinal';
}
