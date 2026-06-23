import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/daos/chats_dao.dart';
import '../database/daos/messages_dao.dart';
import '../database/models/chat_model.dart';
import '../database/models/message_model.dart';
import '../router/app_router.dart';

// ─── Background handler (top-level, fuera de clase) ──────────────────────────
// Firebase lo invoca en un Isolate separado cuando la app está CERRADA o en BG.
// DEBE guardar el mensaje en SQLite para que aparezca aunque el usuario
// abra la app sin tocar la notificación.
@pragma('vm:entry-point')
Future<void> onBackgroundMessage(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();

  final data = message.data;
  final ciphertext = data['ciphertext'];
  final chatId     = data['chatId'];
  final from       = data['from'];
  final messageId  = data['messageId'];
  final ts         = int.tryParse(data['timestamp'] ?? '');

  if (ciphertext == null || chatId == null || chatId.isEmpty ||
      from == null || messageId == null || messageId.isEmpty) {
    return;
  }

  try {
    final messagesDao = MessagesDao();
    final chatsDao    = ChatsDao();

    if (await messagesDao.existsById(messageId)) return; // ya procesado

    final sentAt = ts != null
        ? DateTime.fromMillisecondsSinceEpoch(ts)
        : DateTime.now();

    await messagesDao.insert(MessageModel(
      id: messageId,
      chatId: chatId,
      senderId: from,
      type: MessageType.text,
      encryptedContent: ciphertext,
      status: MessageStatus.delivered,
      sentAt: sentAt,
      deliveredAt: DateTime.now(),
    ));

    final existingChat = await chatsDao.getById(chatId);
    if (existingChat == null) {
      await chatsDao.upsert(ChatModel(
        id: chatId,
        type: ChatType.individual,
        name: from,
        createdAt: DateTime.now(),
      ));
    }
    await chatsDao.incrementUnread(chatId);
    await chatsDao.updateLastMessage(chatId,
        messageId: messageId,
        preview: '🔒 Mensaje nuevo',
        sentAt: sentAt);
  } catch (e) {
    debugPrint('[FCM] background save error: $e');
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
