// dart run tool/generate_keys.dart
//
// Ejecutar UNA SOLA VEZ al inicio del proyecto.
// Genera el par de claves Ed25519.
// La clave PRIVADA la guarda en keys/private_key.hex (NUNCA subir al repo).
// La clave PUBLICA se imprime en pantalla y debe copiarse al archivo
// lib/core/security/build_signature.dart
//
// IMPORTANTE: Guarda el archivo private_key.hex en un lugar seguro fuera
// del repositorio. Si lo pierdes, no podras firmar nuevas versiones.

import 'dart:io';
import 'package:cryptography/cryptography.dart';
import 'package:convert/convert.dart';

void main() async {
  print('\n🔑 Konecta — Generador de claves de firma Ed25519\n');

  final algorithm = Ed25519();
  final keyPair = await algorithm.newKeyPair();

  final publicKey = await keyPair.extractPublicKey();
  final privateKeyBytes = await keyPair.extractPrivateKeyBytes();

  final privateKeyHex = hex.encode(privateKeyBytes);
  final publicKeyHex = hex.encode(publicKey.bytes);

  // Guardar clave privada localmente (jamas al repo)
  final keysDir = Directory('keys');
  if (!keysDir.existsSync()) keysDir.createSync();
  File('keys/private_key.hex').writeAsStringSync(privateKeyHex);

  print('✅ Par de claves generado.\n');
  print('🔒 CLAVE PRIVADA guardada en: keys/private_key.hex');
  print('   ⚠️  NUNCA subas este archivo al repositorio.');
  print('   ⚠️  Guarda una copia en lugar seguro OFFLINE.\n');
  print('🔓 CLAVE PUBLICA (copia esto en build_signature.dart):');
  print('   $publicKeyHex\n');
  print('Ejecuta ahora: dart run tool/sign_build.dart');
}
