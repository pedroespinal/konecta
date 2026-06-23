// ARCHIVO GENERADO AUTOMATICAMENTE — no editar a mano
// Generado por: dart run tool/sign_build.dart
// Esta firma criptografica certifica la autoria y fecha de compilacion.
// Es verificada en tiempo de ejecucion. Alterar este archivo invalida la firma.

abstract final class BuildSignature {
  // Payload firmado (visible, pero la firma lo hace inalterable)
  static const String signedPayload = '{"app":"Konecta","author":"Pedro Espinal","created":"2026-06-23T15:26:27.900508Z","version":"1.2.4+24","copyright":"Todos los derechos reservados 2026"}';

  // Firma Ed25519 — invalida si el payload es modificado
  static const String signature = '365aed46adf9de5a3be570d58e07b68e195d685319e7797b8a842cf20575b71efbe1e8381f7c71b87c584eb538d39647b920191beb4406143261cd38fa393409';

  // Clave publica para verificacion (no es secreta)
  static const String publicKey = '0381c8a42a938dfa26b7b02698c795e6bb587b4e7dab449ed22a8d1f6c164841';

  // Metadatos rapidos (derivados del payload, para lectura interna)
  static const String buildTimestamp = '2026-06-23T15:26:27.900508Z';
  static const String buildVersion = '1.2.4+24';
  static const String buildAuthor = 'Pedro Espinal';
}
