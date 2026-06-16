import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/security/integrity_monitor.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
  ));

  // Verificaciones de seguridad en segundo plano — no bloquean el arranque
  // en desarrollo, sí bloquean en release si se detecta algo critico.
  unawaited(IntegrityMonitor.runStartupChecks());

  runApp(
    const ProviderScope(
      child: KonectaApp(),
    ),
  );
}

// Ejecutar Future sin await — el resultado no es necesario de inmediato
void unawaited(Future<Object?> future) => future;
