// ARCHIVO GENERADO AUTOMATICAMENTE — no editar a mano
// Generado por: dart run tool/sign_build.dart
// Esta firma criptografica certifica la autoria y fecha de compilacion.
// Es verificada en tiempo de ejecucion. Alterar este archivo invalida la firma.

abstract final class BuildSignature {
  // Payload firmado (visible, pero la firma lo hace inalterable)
  static const String signedPayload = '{"app":"Konecta","author":"Pedro Espinal","created":"2026-06-17T19:24:09.104715Z","version":"1.2.0+13","copyright":"Todos los derechos reservados 2026"}';

  // Firma Ed25519 — invalida si el payload es modificado
  static const String signature = 'e1b19219b88af3a4f1e45a02e2f55b3111f4801196298ae09fe4fa782a7de2484cebcfd85fd6188ef94fe3f0280194fddf45fd8bdeccb333f9c4833b7adc1003';

  // Clave publica para verificacion (no es secreta)
  static const String publicKey = '0381c8a42a938dfa26b7b02698c795e6bb587b4e7dab449ed22a8d1f6c164841';

  // Metadatos rapidos (derivados del payload, para lectura interna)
  static const String buildTimestamp = '2026-06-17T19:24:09.104715Z';
  static const String buildVersion = '1.2.0+13';
  static const String buildAuthor = 'Pedro Espinal';
}
