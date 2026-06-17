import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'core/notifications/fcm_service.dart';
import 'core/security/integrity_monitor.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Cargar preferencias persistidas (tema e idioma)
  final prefs = await SharedPreferences.getInstance();
  final savedThemeIndex = prefs.getInt('kc_theme_mode') ?? ThemeMode.system.index;
  final savedLangCode = prefs.getString('kc_language_code');

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
  ));

  // Push notifications (FCM)
  unawaited(FcmService.initialize());

  // Verificaciones de seguridad en segundo plano
  unawaited(IntegrityMonitor.runStartupChecks());

  runApp(
    ProviderScope(
      overrides: [
        themeModeProvider.overrideWith(
          (ref) => ThemeMode.values[savedThemeIndex.clamp(0, ThemeMode.values.length - 1)],
        ),
        localeProvider.overrideWith(
          (ref) => savedLangCode != null ? Locale(savedLangCode) : null,
        ),
      ],
      child: const KonectaApp(),
    ),
  );
}

void unawaited(Future<Object?> future) => future;
