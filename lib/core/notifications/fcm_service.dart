import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Maneja mensajes FCM en background (cuando la app está cerrada).
@pragma('vm:entry-point')
Future<void> _onBackgroundMessage(RemoteMessage message) async {
  debugPrint('[FCM] background: ${message.notification?.title}');
}

class FcmService {
  FcmService._();

  static final _messaging = FirebaseMessaging.instance;

  static Future<void> initialize() async {
    // Solicitar permiso (iOS/web; Android 13+ también)
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Registrar handler de background
    FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);

    // Foreground: mostrar notificación como SnackBar / banner
    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('[FCM] foreground: ${message.notification?.title}');
      // El relay ya entrega el mensaje por WebSocket en foreground;
      // FCM solo se necesita cuando la app está en background/cerrada.
    });

    // Notificación clickeada desde background
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('[FCM] opened from background: ${message.data}');
      // TODO: navegar al chat correspondiente usando message.data['chatId']
    });

    // Token del dispositivo — enviar al relay cuando esté disponible
    final token = await _messaging.getToken();
    if (token != null) {
      debugPrint('[FCM] token: $token');
      await _sendTokenToRelay(token);
    }

    // Renovación automática del token
    _messaging.onTokenRefresh.listen(_sendTokenToRelay);
  }

  static Future<void> _sendTokenToRelay(String token) async {
    // El relay almacena el token para enviar FCM cuando el usuario esté offline.
    // Se implementa via WebSocket: envía mensaje tipo "register_fcm_token".
    debugPrint('[FCM] enviando token al relay: ${token.substring(0, 20)}...');
    // El KonectaSocketClient lo enviará al conectar (ver socket_client.dart).
    _pendingToken = token;
  }

  static String? _pendingToken;
  static String? get pendingFcmToken => _pendingToken;
}

final fcmServiceProvider = Provider<FcmService>((ref) => FcmService._());
