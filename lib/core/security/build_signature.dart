// ARCHIVO GENERADO AUTOMATICAMENTE — no editar a mano
// Generado por: dart run tool/sign_build.dart
// Esta firma criptografica certifica la autoria y fecha de compilacion.
// Es verificada en tiempo de ejecucion. Alterar este archivo invalida la firma.

abstract final class BuildSignature {
  // Payload firmado (visible, pero la firma lo hace inalterable)
  static const String signedPayload = '{"app":"Konecta","author":"Pedro Espinal","created":"2026-06-21T17:23:29.979433Z","version":"1.2.0+16","copyright":"Todos los derechos reservados 2026"}';

  // Firma Ed25519 — invalida si el payload es modificado
  static const String signature = '1fc18ac2f0a67d52223b087949d2a675886fdf7624bd8638e0144de98a814c828fdf9a4dc7e78406686560bd95b269baec32544323e6ece827ff44fe5e1ec40f';

  // Clave publica para verificacion (no es secreta)
  static const String publicKey = '0381c8a42a938dfa26b7b02698c795e6bb587b4e7dab449ed22a8d1f6c164841';

  // Metadatos rapidos (derivados del payload, para lectura interna)
  static const String buildTimestamp = '2026-06-21T17:23:29.979433Z';
  static const String buildVersion = '1.2.0+16';
  static const String buildAuthor = 'Pedro Espinal';
}
