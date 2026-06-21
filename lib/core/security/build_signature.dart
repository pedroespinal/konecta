// ARCHIVO GENERADO AUTOMATICAMENTE — no editar a mano
// Generado por: dart run tool/sign_build.dart
// Esta firma criptografica certifica la autoria y fecha de compilacion.
// Es verificada en tiempo de ejecucion. Alterar este archivo invalida la firma.

abstract final class BuildSignature {
  // Payload firmado (visible, pero la firma lo hace inalterable)
  static const String signedPayload = '{"app":"Konecta","author":"Pedro Espinal","created":"2026-06-21T16:54:07.736143Z","version":"1.2.0+15","copyright":"Todos los derechos reservados 2026"}';

  // Firma Ed25519 — invalida si el payload es modificado
  static const String signature = '652dea115b2ef103a205c7e3b62519946b1ced60ff765ade367c8dd608321ca1dd53b4dcd3b09fa5f570e2db8021717b0ee384729016094d1c7906bf1bd00205';

  // Clave publica para verificacion (no es secreta)
  static const String publicKey = '0381c8a42a938dfa26b7b02698c795e6bb587b4e7dab449ed22a8d1f6c164841';

  // Metadatos rapidos (derivados del payload, para lectura interna)
  static const String buildTimestamp = '2026-06-21T16:54:07.736143Z';
  static const String buildVersion = '1.2.0+15';
  static const String buildAuthor = 'Pedro Espinal';
}
