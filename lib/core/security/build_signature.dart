// ARCHIVO GENERADO AUTOMATICAMENTE — no editar a mano
// Generado por: dart run tool/sign_build.dart
// Esta firma criptografica certifica la autoria y fecha de compilacion.
// Es verificada en tiempo de ejecucion. Alterar este archivo invalida la firma.

abstract final class BuildSignature {
  // Payload firmado (visible, pero la firma lo hace inalterable)
  static const String signedPayload = '{"app":"Konecta","author":"Pedro Espinal","created":"2026-06-23T13:37:00.927832Z","version":"1.2.3+23","copyright":"Todos los derechos reservados 2026"}';

  // Firma Ed25519 — invalida si el payload es modificado
  static const String signature = 'dd3ec404bda0752021d008255eae41fffd4b6909cfacef0dd0be03fb1fc37f17bbc9f678000a698d4cffc36c620e409dcff555f3562319f752860c205bc78506';

  // Clave publica para verificacion (no es secreta)
  static const String publicKey = '0381c8a42a938dfa26b7b02698c795e6bb587b4e7dab449ed22a8d1f6c164841';

  // Metadatos rapidos (derivados del payload, para lectura interna)
  static const String buildTimestamp = '2026-06-23T13:37:00.927832Z';
  static const String buildVersion = '1.2.3+23';
  static const String buildAuthor = 'Pedro Espinal';
}
