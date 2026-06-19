import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../router/app_router.dart';

/// Handler de background — se ejecuta en isolate separado.
@pragma('vm:entry-point')
Future<void> _onBackgroundMessage(RemoteMessage message) async {
  // Firebase mostrará la notificación automáticamente (campo notification).
  // El mensaje se guarda cuando el usuario toca y abre la app (onMessageOpenedApp).
  debugPrint('[FCM] background: ${message.notification?.title}');
}

class FcmService {
  FcmService._();

  static final _messaging = FirebaseMessaging.instance;

  static Future<void> initialize() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);

    // Foreground: cuando la app está abierta y llega un FCM
    // (ocurre si el WebSocket se desconecta temporalmente)
    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('[FCM] foreground: ${message.notification?.title}');
      final data = message.data;
      if (data.containsKey('ciphertext') && data.containsKey('chatId')) {
        _pendingMessageData = Map<String, String>.from(data);
      }
    });

    // Notificación clickeada desde background
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

    // Cold start (app cerrada)
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      final data = initial.data;
      final chatId = data['chatId'] as String?;
      if (chatId != null) _pendingChatId = chatId;
      if (data.containsKey('ciphertext')) {
        _pendingMessageData = Map<String, String>.from(data);
      }
    }

    // FCM token del dispositivo
    final token = await _messaging.getToken();
    if (token != null) {
      debugPrint('[FCM] token: ${token.substring(0, 20)}...');
      _pendingToken = token;
    }
    _messaging.onTokenRefresh.listen((t) => _pendingToken = t);
  }

  static String? _pendingToken;
  static String? get pendingFcmToken => _pendingToken;

  static String? _pendingChatId;
  static String? get pendingChatId => _pendingChatId;
  static void clearPendingChatId() => _pendingChatId = null;

  /// Datos del mensaje FCM recibido (ciphertext, chatId, from, messageId, timestamp).
  /// HomeScreen lo procesa al iniciarse para guardar el mensaje en la BD local.
  static Map<String, String>? _pendingMessageData;
  static Map<String, String>? get pendingMessageData => _pendingMessageData;
  static void clearPendingMessageData() => _pendingMessageData = null;
}

final fcmServiceProvider = Provider<FcmService>((ref) => FcmService._());
