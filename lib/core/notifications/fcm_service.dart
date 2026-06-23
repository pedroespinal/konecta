import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../router/app_router.dart';

const _kPendingBgKey = 'pending_fcm_background_messages';

// ─── Background handler (top-level, fuera de clase) ──────────────────────────
// Firebase lo invoca en un Isolate separado cuando la app está CERRADA.
// sqflite NO funciona en este isolate (platform channels no registradas).
// Solución: guardar los datos crudos en SharedPreferences y procesarlos
// en el hilo principal cuando la app abra.
@pragma('vm:entry-point')
Future<void> onBackgroundMessage(RemoteMessage message) async {
  final data = message.data;
  final ciphertext = data['ciphertext'];
  final chatId     = data['chatId'];
  final from       = data['from'];
  final messageId  = data['messageId'];

  if (ciphertext == null || chatId == null || chatId.isEmpty ||
      from == null || messageId == null || messageId.isEmpty) {
    return;
  }

  try {
    // SharedPreferences SÍ funciona en background isolates de Firebase.
    // Guardamos el mensaje completo para procesarlo cuando la app abra.
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_kPendingBgKey) ?? [];
    existing.add(jsonEncode(Map<String, String>.from(data)));
    await prefs.setStringList(_kPendingBgKey, existing);
  } catch (e) {
    debugPrint('[FCM] background store error: $e');
  }
}

// ─── Servicio ─────────────────────────────────────────────────────────────────
class FcmService {
  FcmService._();

  static const _relayBase = 'https://relay-production-38eb.up.railway.app';

  static final _messaging = FirebaseMessaging.instance;

  static Future<void> initialize() async {
    // 1. Pedir permiso de notificaciones al usuario (Android 13+, iOS).
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 2. Mensaje en primer plano (app abierta y WebSocket desconectado):
    //    Firebase NO muestra notif automáticamente en foreground.
    //    Aquí solo guardamos los datos; el WebSocket ya maneja el caso normal.
    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('[FCM] foreground: ${message.notification?.title}');
      final data = message.data;
      if (data.containsKey('ciphertext') && data.containsKey('chatId')) {
        _pendingMessageData = Map<String, String>.from(data);
      }
    });

    // 3. Notificación clickeada desde background (app estaba en background).
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('[FCM] opened from background: ${message.data}');
      final data = message.data;
      final chatId = data['chatId'] as String?;
      if (chatId != null) _pendingChatId = chatId;
      if (data.containsKey('ciphertext')) {
        _pendingMessageData = Map<String, String>.from(data);
      }
      appRouter.go(AppRoutes.home);
    });

    // 4. Cold start: app cerrada, usuario toca la notificación.
    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      final data = initial.data;
      final chatId = data['chatId'] as String?;
      if (chatId != null) _pendingChatId = chatId;
      if (data.containsKey('ciphertext')) {
        _pendingMessageData = Map<String, String>.from(data);
      }
    }

    // 5. Obtener token FCM.
    final token = await _messaging.getToken();
    if (token != null) {
      debugPrint('[FCM] token: ${token.substring(0, 20)}...');
      _pendingToken = token;
    }

    // 6. Renovación del token.
    _messaging.onTokenRefresh.listen((t) {
      debugPrint('[FCM] token refreshed: ${t.substring(0, 20)}...');
      _pendingToken = t;
    });
  }

  // ── Registro HTTP del token en el relay ──────────────────────────────────
  // Llama a /register-token para que el relay tenga el token aunque el
  // WebSocket no esté conectado o el relay haya reiniciado en Railway.
  static Future<void> registerTokenWithRelay(
      String userId, String fcmToken) async {
    try {
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 8);
      final req =
          await client.postUrl(Uri.parse('$_relayBase/register-token'));
      req.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      req.write(jsonEncode({'userId': userId, 'fcmToken': fcmToken}));
      final res = await req.close();
      await res.drain<void>();
      debugPrint('[FCM] token registrado en relay para $userId');
    } catch (e) {
      debugPrint('[FCM] error registrando token: $e');
    }
  }

  // ── Mensajes guardados por onBackgroundMessage ───────────────────────────
  // Devuelve los mensajes pendientes y los borra de SharedPreferences.
  // Llamar desde el hilo principal (sqflite funciona aquí).
  static Future<List<Map<String, String>>> popPendingBackgroundMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_kPendingBgKey);
      if (raw == null || raw.isEmpty) return [];
      await prefs.remove(_kPendingBgKey);
      return raw
          .map((s) => Map<String, String>.from(jsonDecode(s) as Map))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ── Estado estático ──────────────────────────────────────────────────────
  static String? _pendingToken;
  static String? get pendingFcmToken => _pendingToken;

  static String? _pendingChatId;
  static String? get pendingChatId => _pendingChatId;
  static void clearPendingChatId() => _pendingChatId = null;

  static Map<String, String>? _pendingMessageData;
  static Map<String, String>? get pendingMessageData => _pendingMessageData;
  static void clearPendingMessageData() => _pendingMessageData = null;
}

final fcmServiceProvider = Provider<FcmService>((ref) => FcmService._());
