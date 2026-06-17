// ARCHIVO GENERADO AUTOMATICAMENTE — no editar a mano
// Generado por: dart run tool/sign_build.dart
// Esta firma criptografica certifica la autoria y fecha de compilacion.
// Es verificada en tiempo de ejecucion. Alterar este archivo invalida la firma.

abstract final class BuildSignature {
  // Payload firmado (visible, pero la firma lo hace inalterable)
  static const String signedPayload = '{"app":"Konecta","author":"Pedro Espinal","created":"2026-06-17T12:15:08.421957Z","version":"1.0.8+10","copyright":"Todos los derechos reservados 2026"}';

  // Firma Ed25519 — invalida si el payload es modificado
  static const String signature = 'd9e34fbb3ca6df03a422572db57af64ff25baaa077e97ff0ed3f586d2b886603af8346ec057fdf403cd2de4d91942b4bd5a31a03593734afbf38727b970abe00';

  // Clave publica para verificacion (no es secreta)
  static const String publicKey = '0381c8a42a938dfa26b7b02698c795e6bb587b4e7dab449ed22a8d1f6c164841';

  // Metadatos rapidos (derivados del payload, para lectura interna)
  static const String buildTimestamp = '2026-06-17T12:15:08.421957Z';
  static const String buildVersion = '1.0.8+10';
  static const String buildAuthor = 'Pedro Espinal';
}
