// dart run tool/bump_version.dart [patch|minor|major]
//
// Incrementa el numero de version en pubspec.yaml y actualiza
// lib/core/constants/app_version.dart automaticamente.
// Ejecutar antes de cada build oficial.
//
// Uso:
//   dart run tool/bump_version.dart         -> incrementa build number (+1)
//   dart run tool/bump_version.dart patch   -> incrementa parche (1.0.0 -> 1.0.1)
//   dart run tool/bump_version.dart minor   -> incrementa menor (1.0.0 -> 1.1.0)
//   dart run tool/bump_version.dart major   -> incrementa mayor (1.0.0 -> 2.0.0)

import 'dart:io';

void main(List<String> args) {
  final pubspecFile = File('pubspec.yaml');
  final content = pubspecFile.readAsStringSync();

  final versionRegex = RegExp(r'^version:\s+(\d+)\.(\d+)\.(\d+)\+(\d+)', multiLine: true);
  final match = versionRegex.firstMatch(content);

  if (match == null) {
    stderr.writeln('❌ No se encontro el campo version en pubspec.yaml');
    exit(1);
  }

  int major = int.parse(match.group(1)!);
  int minor = int.parse(match.group(2)!);
  int patch = int.parse(match.group(3)!);
  int build = int.parse(match.group(4)!);

  final type = args.isNotEmpty ? args[0] : 'build';

  switch (type) {
    case 'major':
      major++;
      minor = 0;
      patch = 0;
      build++;
    case 'minor':
      minor++;
      patch = 0;
      build++;
    case 'patch':
      patch++;
      build++;
    default:
      build++;
  }

  final newVersion = '$major.$minor.$patch+$build';
  final newContent = content.replaceFirst(versionRegex, 'version: $newVersion');
  pubspecFile.writeAsStringSync(newContent);

  // Actualizar app_version.dart
  final today = DateTime.now().toUtc();
  final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

  final versionFile = File('lib/core/constants/app_version.dart');
  final versionContent = versionFile.readAsStringSync();

  final updatedVersion = versionContent
      .replaceFirst(RegExp(r"static const String version = '[^']+';"), "static const String version = '$major.$minor.$patch';")
      .replaceFirst(RegExp(r'static const int buildNumber = \d+;'), 'static const int buildNumber = $build;')
      .replaceFirst(RegExp(r"static const String fullVersion = '[^']+';"), "static const String fullVersion = '$newVersion';")
      .replaceFirst(RegExp(r"static const String displayVersion = '[^']+';"), "static const String displayVersion = 'v$major.$minor.$patch (build $build)';");

  versionFile.writeAsStringSync(updatedVersion);

  print('✅ Version actualizada: $newVersion');
  print('   Fecha: $dateStr');
  print('   Ejecuta ahora: dart run tool/sign_build.dart');
}
