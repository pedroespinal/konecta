import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/daos/contacts_dao.dart';
import '../../../core/database/models/chat_model.dart';
import '../../../core/database/models/message_model.dart';
import '../repositories/chat_repository.dart';

// Lista de todos los chats
final chatsProvider = FutureProvider<List<ChatModel>>((ref) {
  return ref.watch(chatRepositoryProvider).loadChats();
});

// Lista de contactos desde la DB local
final contactsProvider = FutureProvider<List<ContactModel>>((ref) {
  return ContactsDao().getAll();
});

// Mensajes de un chat especifico
final messagesProvider =
    FutureProvider.family<List<MessageModel>, String>((ref, chatId) {
  return ref.watch(chatRepositoryProvider).loadMessages(chatId);
});

// Estado local de la pantalla de chat
class ChatScreenState {
  final List<MessageModel> messages;
  final bool isLoading;
  final bool hasMore;
  final String? typingUserId;

  const ChatScreenState({
    this.messages = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.typingUserId,
  });

  ChatScreenState copyWith({
    List<MessageModel>? messages,
    bool? isLoading,
    bool? hasMore,
    String? typingUserId,
    bool clearTyping = false,
  }) =>
      ChatScreenState(
        messages: messages ?? this.messages,
        isLoading: isLoading ?? this.isLoading,
        hasMore: hasMore ?? this.hasMore,
        typingUserId: clearTyping ? null : (typingUserId ?? this.typingUserId),
      );
}

class ChatScreenNotifier extends StateNotifier<ChatScreenState> {
  final ChatRepository _repo;
  final String chatId;

  ChatScreenNotifier(this._repo, this.chatId)
      : super(const ChatScreenState()) {
    _load();
  }

  Future<void> _load() async {
    state = state.copyWith(isLoading: true);
    final msgs = await _repo.loadMessages(chatId);
    await _repo.markRead(chatId);
    state = state.copyWith(
      messages: msgs.reversed.toList(), // orden cronologico
      isLoading: false,
      hasMore: msgs.length == 50,
    );
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoading) return;
    state = state.copyWith(isLoading: true);
    final older = await _repo.loadMessages(chatId, offset: state.messages.length);
    state = state.copyWith(
      messages: [...state.messages, ...older.reversed],
      isLoading: false,
      hasMore: older.length == 50,
    );
  }

  Future<void> sendText(String text, {String? replyToId, int? disappearsInSeconds}) async {
    final msg = await _repo.sendTextMessage(
      chatId: chatId,
      text: text,
      replyToId: replyToId,
      disappearsInSeconds: disappearsInSeconds,
    );
    state = state.copyWith(messages: [...state.messages, msg]);
  }

  Future<void> deleteMessage(String messageId) async {
    await _repo.deleteMessage(messageId);
    state = state.copyWith(
      messages: state.messages.where((m) => m.id != messageId).toList(),
    );
  }

  Future<void> reactTo(String messageId, String? emoji) async {
    await _repo.reactToMessage(messageId, emoji);
    state = state.copyWith(
      messages: state.messages.map((m) {
        if (m.id != messageId) return m;
        return m.copyWith(reactionEmoji: emoji);
      }).toList(),
    );
  }

  Future<void> updateMessage(String messageId, String newText) async {
    await _repo.updateMessage(messageId, newText, chatId);
    state = state.copyWith(
      messages: state.messages.map((m) {
        if (m.id != messageId) return m;
        return m.copyWith(decryptedContent: newText);
      }).toList(),
    );
  }

  Future<void> starMessage(String messageId, bool starred) async {
    await _repo.starMessage(messageId, starred);
    state = state.copyWith(
      messages: state.messages.map((m) {
        if (m.id != messageId) return m;
        return m.copyWith(isStarred: starred);
      }).toList(),
    );
  }

  void addMessage(MessageModel msg) {
    if (state.messages.any((m) => m.id == msg.id)) return;
    state = state.copyWith(messages: [...state.messages, msg]);
  }

  Future<void> deleteChat() => _repo.deleteChat(chatId);

  void setTyping(String? userId) {
    state = userId != null
        ? state.copyWith(typingUserId: userId)
        : state.copyWith(clearTyping: true);
  }
}

final chatScreenProvider = StateNotifierProvider.family<
    ChatScreenNotifier, ChatScreenState, String>((ref, chatId) {
  final repo = ref.watch(chatRepositoryProvider);
  return ChatScreenNotifier(repo, chatId);
});
