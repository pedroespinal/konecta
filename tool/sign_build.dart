// dart run tool/sign_build.dart
//
// Ejecutar ANTES de cada compilacion oficial.
// Lee la clave privada, firma los metadatos de la build (fecha/hora exacta,
// version, autor) y actualiza lib/core/security/build_signature.dart
// con la firma incrustada. La firma es verificada por la app en tiempo de
// ejecucion. Es INVISIBLE para el usuario y NO puede ser alterada sin
// invalidarla (requeriria la clave privada para re-firmar).

import 'dart:io';
import 'package:cryptography/cryptography.dart';
import 'package:convert/convert.dart';

void main() async {
  final privateKeyFile = File('keys/private_key.hex');
  if (!privateKeyFile.existsSync()) {
    stderr.writeln('❌ Error: keys/private_key.hex no encontrado.');
    stderr.writeln('   Ejecuta primero: dart run tool/generate_keys.dart');
    exit(1);
  }

  // Leer clave privada
  final privateKeyHex = privateKeyFile.readAsStringSync().trim();
  final privateKeyBytes = hex.decode(privateKeyHex);

  // Leer version actual
  final pubspec = File('pubspec.yaml').readAsStringSync();
  final versionMatch = RegExp(r'^version:\s+(\S+)', multiLine: true).firstMatch(pubspec);
  final fullVersion = versionMatch?.group(1) ?? '0.0.0+0';

  // Crear payload de firma
  final now = DateTime.now().toUtc();
  final timestamp = now.toIso8601String();
  final payload = '{"app":"Konecta","author":"Pedro Espinal",'
      '"created":"$timestamp","version":"$fullVersion",'
      '"copyright":"Todos los derechos reservados 2026"}';

  // Firmar con Ed25519
  final algorithm = Ed25519();
  final keyPair = await algorithm.newKeyPairFromSeed(privateKeyBytes);
  final publicKey = await keyPair.extractPublicKey();
  final signature = await algorithm.sign(payload.codeUnits, keyPair: keyPair);

  final signatureHex = hex.encode(signature.bytes);
  final publicKeyHex = hex.encode(publicKey.bytes);

  // Generar archivo Dart con la firma incrustada
  final dartCode = '''// ARCHIVO GENERADO AUTOMATICAMENTE — no editar a mano
// Generado por: dart run tool/sign_build.dart
// Esta firma criptografica certifica la autoria y fecha de compilacion.
// Es verificada en tiempo de ejecucion. Alterar este archivo invalida la firma.

abstract final class BuildSignature {
  // Payload firmado (visible, pero la firma lo hace inalterable)
  static const String signedPayload = '$payload';

  // Firma Ed25519 — invalida si el payload es modificado
  static const String signature = '$signatureHex';

  // Clave publica para verificacion (no es secreta)
  static const String publicKey = '$publicKeyHex';

  // Metadatos rapidos (derivados del payload, para lectura interna)
  static const String buildTimestamp = '$timestamp';
  static const String buildVersion = '$fullVersion';
  static const String buildAuthor = 'Pedro Espinal';
}
''';

  File('lib/core/security/build_signature.dart').writeAsStringSync(dartCode);

  print('✅ Firma generada correctamente.');
  print('   📅 Fecha/hora: $timestamp');
  print('   📦 Version: $fullVersion');
  print('   🔐 Firma: ${signatureHex.substring(0, 32)}...');
  print('   Archivo actualizado: lib/core/security/build_signature.dart');
}
