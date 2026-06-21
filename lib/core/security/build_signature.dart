// ARCHIVO GENERADO AUTOMATICAMENTE — no editar a mano
// Generado por: dart run tool/sign_build.dart
// Esta firma criptografica certifica la autoria y fecha de compilacion.
// Es verificada en tiempo de ejecucion. Alterar este archivo invalida la firma.

abstract final class BuildSignature {
  // Payload firmado (visible, pero la firma lo hace inalterable)
  static const String signedPayload = '{"app":"Konecta","author":"Pedro Espinal","created":"2026-06-21T18:03:23.133908Z","version":"1.2.0+18","copyright":"Todos los derechos reservados 2026"}';

  // Firma Ed25519 — invalida si el payload es modificado
  static const String signature = '60f937546e77403703879ebc037b00845e080e047d91119fb42fb0a7f0ccc765ac1ae6a8c0e9c14b605084bdb5114d3d908ae8df85a393c566df18482b4b400c';

  // Clave publica para verificacion (no es secreta)
  static const String publicKey = '0381c8a42a938dfa26b7b02698c795e6bb587b4e7dab449ed22a8d1f6c164841';

  // Metadatos rapidos (derivados del payload, para lectura interna)
  static const String buildTimestamp = '2026-06-21T18:03:23.133908Z';
  static const String buildVersion = '1.2.0+18';
  static const String buildAuthor = 'Pedro Espinal';
}
