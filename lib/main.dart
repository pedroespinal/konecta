import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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

  // Registrar handler de background ANTES de runApp.
  // Firebase requiere que esto ocurra lo más temprano posible.
  FirebaseMessaging.onBackgroundMessage(onBackgroundMessage);

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

  // Push notifications: crear canal Android + permisos + token.
  // Se awaita para garantizar que el canal exista ANTES de que llegue
  // cualquier notificación y que el token FCM esté listo.
  await FcmService.initialize();

  // Verificaciones de seguridad en segundo plano
  _unawaited(IntegrityMonitor.runStartupChecks());

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

void _unawaited(Future<Object?> future) => future;
