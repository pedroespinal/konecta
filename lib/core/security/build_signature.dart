// ARCHIVO GENERADO AUTOMATICAMENTE — no editar a mano
// Generado por: dart run tool/sign_build.dart
// Esta firma criptografica certifica la autoria y fecha de compilacion.
// Es verificada en tiempo de ejecucion. Alterar este archivo invalida la firma.

abstract final class BuildSignature {
  // Payload firmado (visible, pero la firma lo hace inalterable)
  static const String signedPayload = '{"app":"Konecta","author":"Pedro Espinal","created":"2026-06-21T17:44:35.796166Z","version":"1.2.0+17","copyright":"Todos los derechos reservados 2026"}';

  // Firma Ed25519 — invalida si el payload es modificado
  static const String signature = '5837b08482763c48e75c9b5ff4bbcfb2edea09fa775fe3dda0e6029a64f16efd0bb7fcb0e24b552c5b1da9a5b552002a993a079c1a4993419688aca14e1a2c01';

  // Clave publica para verificacion (no es secreta)
  static const String publicKey = '0381c8a42a938dfa26b7b02698c795e6bb587b4e7dab449ed22a8d1f6c164841';

  // Metadatos rapidos (derivados del payload, para lectura interna)
  static const String buildTimestamp = '2026-06-21T17:44:35.796166Z';
  static const String buildVersion = '1.2.0+17';
  static const String buildAuthor = 'Pedro Espinal';
}
