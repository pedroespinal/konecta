import 'dart:convert';
import 'package:convert/convert.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/daos/chats_dao.dart';
import '../../../core/database/daos/messages_dao.dart';
import '../../../core/database/models/chat_model.dart';
import '../../../core/database/models/message_model.dart';
import '../../../core/network/message_payload.dart';
import '../../../core/network/socket_client.dart';
import '../../../features/auth/repositories/auth_repository.dart';

// Cifrado simetrico de mensajes para Fase 3.
// En Fase 5 se reemplaza por Double Ratchet completo.
class _MessageCipher {
  static final _aesGcm = AesGcm.with256bits();
  static final _uuid = Uuid();

  // Clave simétrica compartida derivada del chatId.
  // Ambos dispositivos conocen el chatId → misma clave → descifrado correcto.
  // Fase 5: reemplazar con clave derivada de X3DH / Double Ratchet.
  static Future<SecretKey> _sessionKey(String chatId) async {
    final hash = await Sha256().hash(utf8.encode('konecta:v1:$chatId'));
    return SecretKey(hash.bytes);
  }

  static Future<String> encrypt(String plaintext, String chatId) async {
    final key = await _sessionKey(chatId);
    final nonce = _aesGcm.newNonce();
    final sealed = await _aesGcm.encrypt(
      utf8.encode(plaintext),
      secretKey: key,
      nonce: nonce,
    );
    final payload = jsonEncode({
      'n': hex.encode(nonce),
      'c': hex.encode(sealed.cipherText),
      'm': hex.encode(sealed.mac.bytes),
    });
    return base64Encode(utf8.encode(payload));
  }

  static Future<String> decrypt(String ciphertext, String chatId) async {
    final key = await _sessionKey(chatId);
    final payload = jsonDecode(utf8.decode(base64Decode(ciphertext)))
        as Map<String, dynamic>;
    final sealed = SecretBox(
      hex.decode(payload['c'] as String),
      nonce: hex.decode(payload['n'] as String),
      mac: Mac(hex.decode(payload['m'] as String)),
    );
    final plain = await _aesGcm.decrypt(sealed, secretKey: key);
    return utf8.decode(plain);
  }

  static String newId() => _uuid.v4();
}

class ChatRepository {
  final ChatsDao _chatsDao = ChatsDao();
  final MessagesDao _messagesDao = MessagesDao();
  final Ref _ref;

  ChatRepository(this._ref);

  Future<List<ChatModel>> loadChats() => _chatsDao.getAll();

  Future<List<MessageModel>> loadMessages(
    String chatId, {
    int limit = 50,
    int offset = 0,
  }) async {
    final encrypted = await _messagesDao.getForChat(chatId, limit: limit, offset: offset);
    // Descifrar en memoria
    final decrypted = <MessageModel>[];
    for (final msg in encrypted) {
      try {
        final plain = await _MessageCipher.decrypt(msg.encryptedContent, chatId);
        decrypted.add(msg.copyWith(decryptedContent: plain));
      } catch (_) {
        decrypted.add(msg.copyWith(decryptedContent: '[Mensaje cifrado]'));
      }
    }
    return decrypted;
  }

  Future<MessageModel> sendTextMessage({
    required String chatId,
    required String text,
    String? replyToId,
    int? disappearsInSeconds,
  }) async {
    final profile = _ref.read(authProvider).profile;
    if (profile == null) throw StateError('Sin sesion');

    final encrypted = await _MessageCipher.encrypt(text, chatId);
    final now = DateTime.now();
    final msg = MessageModel(
      id: _MessageCipher.newId(),
      chatId: chatId,
      senderId: profile.userId,
      type: MessageType.text,
      encryptedContent: encrypted,
      decryptedContent: text,
      status: MessageStatus.sending,
      sentAt: now,
      replyToId: replyToId,
      disappearsAt: disappearsInSeconds != null
          ? now.add(Duration(seconds: disappearsInSeconds)).millisecondsSinceEpoch
          : null,
    );

    await _messagesDao.insert(msg);
    await _chatsDao.updateLastMessage(chatId,
        messageId: msg.id,
        preview: text.length > 60 ? '${text.substring(0, 60)}...' : text,
        sentAt: now);

    // Enviar via WebSocket
    _sendViaSocket(msg);

    // Actualizar estado a "enviado" optimistamente
    await _messagesDao.updateStatus(msg.id, MessageStatus.sent);
    return msg.copyWith(status: MessageStatus.sent);
  }

  void _sendViaSocket(MessageModel msg) {
    final socket = _ref.read(socketProvider.notifier);
    if (_ref.read(socketProvider).status != SocketStatus.connected) return;

    final payload = MessagePayload(
      type: PayloadType.message,
      from: msg.senderId,
      to: _peerUserId(msg.chatId, msg.senderId),
      ciphertext: msg.encryptedContent,
      messageId: msg.id,
      timestamp: msg.sentAt.millisecondsSinceEpoch,
    );
    socket.sendMessage(payload);
  }

  /// Extrae el userId del peer a partir del chatId.
  /// Formato: 'chat_<32hexA>_<32hexB>' (A y B son userIds de 32 chars hex).
  String _peerUserId(String chatId, String myUserId) {
    if (!chatId.startsWith('chat_')) return chatId; // grupos: usar chatId
    final inner = chatId.substring(5);
    final mid = inner.indexOf('_');
    if (mid < 0) return chatId;
    final a = inner.substring(0, mid);
    final b = inner.substring(mid + 1);
    return a == myUserId ? b : a;
  }

  Future<MessageModel?> receiveMessage(MessagePayload payload, String chatId) async {
    // Crear el chat si no existe aún
    final existing = await _chatsDao.getById(chatId);
    if (existing == null) {
      await _chatsDao.upsert(ChatModel(
        id: chatId,
        type: ChatType.individual,
        name: payload.from,
        createdAt: DateTime.now(),
      ));
    }

    String decrypted;
    try {
      decrypted = await _MessageCipher.decrypt(payload.ciphertext, chatId);
    } catch (_) {
      decrypted = '[Mensaje cifrado]';
    }

    final msg = MessageModel(
      id: payload.messageId,
      chatId: chatId,
      senderId: payload.from,
      type: MessageType.text,
      encryptedContent: payload.ciphertext,
      decryptedContent: decrypted,
      status: MessageStatus.delivered,
      sentAt: DateTime.fromMillisecondsSinceEpoch(payload.timestamp),
      deliveredAt: DateTime.now(),
    );
    await _messagesDao.insert(msg); // ConflictAlgorithm.replace — idempotente
    await _chatsDao.incrementUnread(chatId);
    await _chatsDao.updateLastMessage(chatId,
        messageId: msg.id, preview: decrypted, sentAt: msg.sentAt);
    return msg;
  }

  Future<void> markRead(String chatId) async {
    await _messagesDao.markAllReadInChat(chatId);
    await _chatsDao.clearUnread(chatId);
  }

  Future<void> deleteMessage(String messageId) =>
      _messagesDao.softDelete(messageId);

  Future<void> reactToMessage(String messageId, String? emoji) =>
      _messagesDao.setReaction(messageId, emoji);

  Future<void> starMessage(String messageId, bool starred) =>
      _messagesDao.toggleStar(messageId, starred);

  Future<void> updateMessage(String messageId, String newText, String chatId) async {
    final encrypted = await _MessageCipher.encrypt(newText, chatId);
    await _messagesDao.updateMessage(messageId, encrypted);
  }

  Future<List<MessageModel>> getStarredMessages() async {
    final starred = await _messagesDao.getStarred();
    final decrypted = <MessageModel>[];
    for (final msg in starred) {
      try {
        final plain = await _MessageCipher.decrypt(msg.encryptedContent, msg.chatId);
        decrypted.add(msg.copyWith(decryptedContent: plain));
      } catch (_) {
        decrypted.add(msg.copyWith(decryptedContent: '[Mensaje cifrado]'));
      }
    }
    return decrypted;
  }

  Future<ChatModel> createIndividualChat(ContactModel contact) async {
    final profile = _ref.read(authProvider).profile;
    final chatId = _generateChatId(profile?.userId ?? '', contact.id);
    final chat = ChatModel(
      id: chatId,
      type: ChatType.individual,
      name: contact.displayName,
      avatarPath: contact.avatarPath,
      createdAt: DateTime.now(),
    );
    await _chatsDao.upsert(chat);
    return chat;
  }

  Future<ChatModel> createGroup({
    required String name,
    required List<String> memberIds,
    String? description,
  }) async {
    final profile = _ref.read(authProvider).profile;
    final chatId = 'grp_${DateTime.now().millisecondsSinceEpoch}';
    final allMembers = [...memberIds, if (profile != null) profile.userId];
    final chat = ChatModel(
      id: chatId,
      type: ChatType.group,
      name: name,
      description: description,
      memberIds: allMembers,
      createdAt: DateTime.now(),
    );
    await _chatsDao.upsert(chat);
    return chat;
  }

  String _generateChatId(String userA, String userB) {
    final sorted = [userA, userB]..sort();
    return 'chat_${sorted.join('_')}';
  }

  Future<void> deleteChat(String chatId) => _chatsDao.delete(chatId);
  Future<void> togglePin(String chatId, bool pinned) =>
      _chatsDao.togglePin(chatId, pinned);
  Future<void> toggleMute(String chatId, bool muted) =>
      _chatsDao.toggleMute(chatId, muted);
  Future<void> archiveChat(String chatId) =>
      _chatsDao.toggleArchive(chatId, true);

  /// Guarda un mensaje recibido via FCM cuando el usuario estaba offline.
  /// Crea el chat si no existe. Se llama desde HomeScreen al iniciar.
  Future<void> receiveFcmMessage(Map<String, String> data) async {
    final ciphertext = data['ciphertext'];
    final chatId = data['chatId'];
    final from = data['from'];
    final messageId = data['messageId'];
    final ts = int.tryParse(data['timestamp'] ?? '');
    if (ciphertext == null ||
        chatId == null ||
        from == null ||
        messageId == null) {
      return;
    }

    // Asegurar que el chat existe
    final existingChat = await _chatsDao.getById(chatId);
    if (existingChat == null) {
      await _chatsDao.upsert(ChatModel(
        id: chatId,
        type: ChatType.individual,
        name: from,
        createdAt: DateTime.now(),
      ));
    }

    final sentAt =
        ts != null ? DateTime.fromMillisecondsSinceEpoch(ts) : DateTime.now();
    await _messagesDao.insert(MessageModel(
      id: messageId,
      chatId: chatId,
      senderId: from,
      type: MessageType.text,
      encryptedContent: ciphertext,
      status: MessageStatus.delivered,
      sentAt: sentAt,
      deliveredAt: DateTime.now(),
    ));
    await _chatsDao.incrementUnread(chatId);
    await _chatsDao.updateLastMessage(
      chatId,
      messageId: messageId,
      preview: '🔒 Mensaje nuevo',
      sentAt: sentAt,
    );
  }
}

final chatRepositoryProvider = Provider<ChatRepository>(
  (ref) => ChatRepository(ref),
);
