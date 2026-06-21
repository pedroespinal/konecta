import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/database/models/chat_model.dart';
import '../../../core/router/app_router.dart';
import '../../../core/database/models/message_model.dart';
import '../../../core/network/message_payload.dart';
import '../../../core/network/socket_client.dart';
import '../../../features/auth/repositories/auth_repository.dart';
import '../../../features/media/media_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/konecta_footer.dart';
import '../providers/chat_provider.dart';
import '../repositories/chat_repository.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/message_bubble.dart';
import '../widgets/typing_indicator.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final ChatModel chat;
  const ChatScreen({super.key, required this.chat});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  MessageModel? _replyingTo;
  MessageModel? _editingMessage;
  int _disappearsInSeconds = 0;
  bool _isMuted = false;
  bool _showSearch = false;
  String _searchQuery = '';
  StreamSubscription? _typingSubscription;
  StreamSubscription? _msgSub;

  @override
  void initState() {
    super.initState();
    _isMuted = widget.chat.isMuted;
    _scrollController.addListener(_onScroll);
    _listenToTyping();
    _listenToMessages();
    _loadEphemeralPref();
  }

  Future<void> _loadEphemeralPref() async {
    final prefs = await SharedPreferences.getInstance();
    final secs = prefs.getInt('ephemeral_${widget.chat.id}') ?? 0;
    if (mounted) setState(() => _disappearsInSeconds = secs);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(chatScreenProvider(widget.chat.id).notifier).loadMore();
    }
  }

  void _listenToTyping() {
    final socket = ref.read(socketProvider.notifier);
    _typingSubscription = socket.typingEvents.listen((event) {
      if (event.chatId == widget.chat.id) {
        ref
            .read(chatScreenProvider(widget.chat.id).notifier)
            .setTyping(event.isTyping ? event.from : null);
      }
    });
  }

  void _listenToMessages() {
    final myUserId = ref.read(authProvider).profile?.userId ?? '';
    final peer = _peerFromChatId(widget.chat.id, myUserId);
    _msgSub = ref.read(socketProvider.notifier).messages.listen((payload) async {
      if (payload.from != peer) return;
      final msg = await ref
          .read(chatRepositoryProvider)
          .receiveMessage(payload, widget.chat.id);
      if (msg != null && mounted) {
        ref.read(chatScreenProvider(widget.chat.id).notifier).addMessage(msg);
        Future.delayed(const Duration(milliseconds: 80), _scrollToBottom);
      }
    });
  }

  String _peerFromChatId(String chatId, String myUserId) {
    if (!chatId.startsWith('chat_')) return chatId;
    final inner = chatId.substring(5);
    final mid = inner.indexOf('_');
    if (mid < 0) return chatId;
    final a = inner.substring(0, mid);
    final b = inner.substring(mid + 1);
    return a == myUserId ? b : a;
  }

  void _scrollToBottom({bool animated = true}) {
    if (!_scrollController.hasClients) return;
    if (animated) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(0);
    }
  }

  void _sendMessage(String text) {
    if (_editingMessage != null) {
      ref
          .read(chatScreenProvider(widget.chat.id).notifier)
          .updateMessage(_editingMessage!.id, text);
      setState(() => _editingMessage = null);
    } else {
      ref.read(chatScreenProvider(widget.chat.id).notifier).sendText(
            text,
            replyToId: _replyingTo?.id,
            disappearsInSeconds: _disappearsInSeconds > 0 ? _disappearsInSeconds : null,
          );
      setState(() => _replyingTo = null);
    }
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  Future<void> _sendMediaMessage(MediaFile file) async {
    // La encriptacion del archivo se hace en el repositorio (Fase 5+)
    // Por ahora enviamos como texto con el path local como referencia
    final label = '[${file.type.name.toUpperCase()}] ${file.fileName} (${file.displaySize})';
    ref.read(chatScreenProvider(widget.chat.id).notifier).sendText(
          label,
          replyToId: _replyingTo?.id,
        );
    setState(() => _replyingTo = null);
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  void _onTypingChanged(bool isTyping) {
    final myUserId = ref.read(authProvider).profile?.userId ?? '';
    final socket = ref.read(socketProvider.notifier);
    socket.sendTyping(
      TypingPayload(
        from: myUserId,
        chatId: widget.chat.id,
        isTyping: isTyping,
      ),
    );
  }

  @override
  void dispose() {
    _msgSub?.cancel();
    _typingSubscription?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(chatScreenProvider(widget.chat.id));
    final myUserId = ref.watch(authProvider).profile?.userId ?? '';

    return Scaffold(
      backgroundColor:
          isDark ? KonectaColors.darkBackground : KonectaColors.lightBackground,
      appBar: _buildAppBar(isDark, state),
      body: Column(
        children: [
          // Barra de búsqueda en chat
          if (_showSearch)
            _SearchBar(
              controller: _searchController,
              onChanged: (q) => setState(() => _searchQuery = q.toLowerCase()),
              onClose: () => setState(() {
                _showSearch = false;
                _searchQuery = '';
                _searchController.clear();
              }),
              isDark: isDark,
            ),

          // Lista de mensajes
          Expanded(
            child: state.isLoading && state.messages.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(
                      color: KonectaColors.primary,
                    ),
                  )
                : state.messages.isEmpty
                    ? _EmptyChat(chatName: widget.chat.name)
                    : Builder(builder: (context) {
                        final visible = _searchQuery.isEmpty
                            ? state.messages
                            : state.messages
                                .where((m) =>
                                    (m.decryptedContent ?? '')
                                        .toLowerCase()
                                        .contains(_searchQuery))
                                .toList();
                        if (visible.isEmpty && _searchQuery.isNotEmpty) {
                          return Center(
                            child: Text('Sin resultados para "$_searchQuery"',
                                style: TextStyle(
                                    color: isDark
                                        ? KonectaColors.darkTextSecondary
                                        : KonectaColors.lightTextSecondary)),
                          );
                        }
                        return ListView.builder(
                          controller: _scrollController,
                          reverse: true,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 0, vertical: 8),
                          itemCount:
                              visible.length + (state.hasMore && _searchQuery.isEmpty ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == visible.length) {
                              return state.isLoading
                                  ? const Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Center(
                                        child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: KonectaColors.primary,
                                          ),
                                        ),
                                      ),
                                    )
                                  : const SizedBox.shrink();
                            }

                            final reversed = visible.reversed.toList();
                            final msg = reversed[index];
                            final isMine = msg.senderId == myUserId;

                            MessageModel? replyMsg;
                            if (msg.replyToId != null) {
                              try {
                                replyMsg = state.messages.firstWhere(
                                  (m) => m.id == msg.replyToId,
                                );
                              } catch (_) {}
                            }

                            return MessageBubble(
                              message: msg,
                              isMine: isMine,
                              showSender: widget.chat.type == ChatType.group,
                              senderName: msg.senderId,
                              replyTo: replyMsg,
                              onReply: () =>
                                  setState(() => _replyingTo = msg),
                              onDelete: () => ref
                                  .read(chatScreenProvider(widget.chat.id)
                                      .notifier)
                                  .deleteMessage(msg.id),
                              onReact: (emoji) => ref
                                  .read(chatScreenProvider(widget.chat.id)
                                      .notifier)
                                  .reactTo(msg.id, emoji),
                              onEdit: isMine
                                  ? () => setState(() {
                                        _editingMessage = msg;
                                        _replyingTo = null;
                                      })
                                  : null,
                              onStar: () => ref
                                  .read(chatScreenProvider(widget.chat.id)
                                      .notifier)
                                  .starMessage(msg.id, !msg.isStarred),
                            );
                          },
                        );
                      }),
          ),

          // Indicador de escritura
          if (state.typingUserId != null)
            TypingIndicator(
              userName: widget.chat.type == ChatType.group
                  ? state.typingUserId
                  : null,
            ),

          // Barra de entrada
          ChatInputBar(
            onSend: _sendMessage,
            onMediaSend: _sendMediaMessage,
            onTypingChanged: _onTypingChanged,
            replyingTo: _replyingTo,
            onCancelReply: () => setState(() => _replyingTo = null),
            editingMessage: _editingMessage,
            onCancelEdit: () => setState(() => _editingMessage = null),
          ),

          const KonectaFooter(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark, ChatScreenState state) {
    return AppBar(
      backgroundColor:
          isDark ? KonectaColors.darkSurface : KonectaColors.lightSurface,
      elevation: 0,
      titleSpacing: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: KonectaColors.primary.withValues(alpha: 0.15),
            backgroundImage: widget.chat.avatarPath != null
                ? AssetImage(widget.chat.avatarPath!)
                : null,
            child: widget.chat.avatarPath == null
                ? Text(
                    widget.chat.name.isNotEmpty
                        ? widget.chat.name[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: KonectaColors.primary,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.chat.name,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? KonectaColors.darkTextPrimary
                        : KonectaColors.lightTextPrimary,
                  ),
                ),
                if (state.typingUserId != null)
                  Text(
                    'escribiendo…',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: KonectaColors.primary,
                    ),
                  )
                else if (widget.chat.type == ChatType.group)
                  Text(
                    '${widget.chat.memberIds.length} miembros',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: isDark
                          ? KonectaColors.darkTextSecondary
                          : KonectaColors.lightTextSecondary,
                    ),
                  )
                else
                  Text(
                    'en línea',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: KonectaColors.accent,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.videocam_rounded),
          tooltip: 'Videollamada',
          onPressed: () => context.push(AppRoutes.call, extra: {
            'peerId': widget.chat.id,
            'peerName': widget.chat.name,
            'isVideo': true,
            'isOutgoing': true,
          }),
        ),
        IconButton(
          icon: const Icon(Icons.call_rounded),
          tooltip: 'Llamada',
          onPressed: () => context.push(AppRoutes.call, extra: {
            'peerId': widget.chat.id,
            'peerName': widget.chat.name,
            'isVideo': false,
            'isOutgoing': true,
          }),
        ),
        PopupMenuButton<_ChatAction>(
          icon: const Icon(Icons.more_vert_rounded),
          itemBuilder: (_) => [
            PopupMenuItem(
                value: _ChatAction.search,
                child: Row(children: [
                  const Icon(Icons.search_rounded, size: 18),
                  const SizedBox(width: 10),
                  const Text('Buscar en chat'),
                ])),
            PopupMenuItem(
                value: _ChatAction.mute,
                child: Row(children: [
                  Icon(_isMuted ? Icons.volume_up_rounded : Icons.volume_off_rounded, size: 18),
                  const SizedBox(width: 10),
                  Text(_isMuted ? 'Activar notificaciones' : 'Silenciar'),
                ])),
            PopupMenuItem(
              value: _ChatAction.ephemeral,
              child: Row(
                children: [
                  Icon(Icons.timer_rounded,
                      size: 18,
                      color: _disappearsInSeconds > 0
                          ? KonectaColors.secondary
                          : null),
                  const SizedBox(width: 8),
                  Text(_disappearsInSeconds > 0
                      ? 'Efímeros: ${_ephemeralLabel()}'
                      : 'Mensajes efímeros'),
                ],
              ),
            ),
            const PopupMenuItem(
                value: _ChatAction.delete,
                child: Text('Borrar conversación',
                    style: TextStyle(color: KonectaColors.error))),
          ],
          onSelected: (action) => _handleChatAction(action),
        ),
      ],
    );
  }

  void _handleChatAction(_ChatAction action) {
    switch (action) {
      case _ChatAction.delete:
        _confirmDeleteChat();
      case _ChatAction.ephemeral:
        _showEphemeralPicker();
      case _ChatAction.search:
        setState(() {
          _showSearch = true;
          _searchQuery = '';
          _searchController.clear();
        });
      case _ChatAction.mute:
        _toggleMute();
    }
  }

  Future<void> _toggleMute() async {
    final next = !_isMuted;
    await ref.read(chatRepositoryProvider).toggleMute(widget.chat.id, next);
    if (mounted) {
      setState(() => _isMuted = next);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(next
            ? 'Notificaciones silenciadas'
            : 'Notificaciones activadas'),
        duration: const Duration(seconds: 2),
      ));
    }
  }

  String _ephemeralLabel() {
    switch (_disappearsInSeconds) {
      case 300: return '5 min';
      case 3600: return '1 hora';
      case 86400: return '1 día';
      case 604800: return '7 días';
      default: return '${_disappearsInSeconds}s';
    }
  }

  void _showEphemeralPicker() {
    final options = [
      (label: 'Desactivado', seconds: 0),
      (label: '5 minutos', seconds: 300),
      (label: '1 hora', seconds: 3600),
      (label: '1 día', seconds: 86400),
      (label: '7 días', seconds: 604800),
    ];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setLocalState) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Text(
                'Mensajes efímeros',
                style: GoogleFonts.inter(
                    fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Los mensajes nuevos desaparecerán automáticamente',
                style: GoogleFonts.inter(fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              ...options.map((opt) => ListTile(
                    leading: Icon(
                      _disappearsInSeconds == opt.seconds
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: KonectaColors.primary,
                    ),
                    title: Text(opt.label),
                    trailing: opt.seconds == 0
                        ? null
                        : const Icon(Icons.timer_rounded,
                            color: KonectaColors.secondary, size: 18),
                    onTap: () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setInt(
                          'ephemeral_${widget.chat.id}', opt.seconds);
                      if (mounted) {
                        setState(() => _disappearsInSeconds = opt.seconds);
                      }
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                  )),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeleteChat() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Borrar conversación'),
        content: const Text(
            'Se eliminarán todos los mensajes. Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              final notifier =
                  ref.read(chatScreenProvider(widget.chat.id).notifier);
              // Eliminar y refrescar lista cuando termine (sin await para evitar
              // uso de context tras gap async)
              notifier.deleteChat().then((_) {
                if (mounted) ref.invalidate(chatsProvider);
              });
              Navigator.pop(context); // cierra el dialog
              Navigator.pop(context); // vuelve a la lista
            },
            child: const Text('Borrar',
                style: TextStyle(color: KonectaColors.error)),
          ),
        ],
      ),
    );
  }

}

enum _ChatAction { search, mute, ephemeral, delete }

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClose;
  final bool isDark;

  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClose,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      color: isDark ? KonectaColors.darkSurface : KonectaColors.lightSurface,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              autofocus: true,
              onChanged: onChanged,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Buscar en la conversación…',
                prefixIcon: const Icon(Icons.search_rounded, size: 20,
                    color: KonectaColors.primary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: isDark
                    ? KonectaColors.darkSurface2
                    : KonectaColors.lightSurface2,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                isDense: true,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: onClose,
            color: isDark
                ? KonectaColors.darkTextSecondary
                : KonectaColors.lightTextSecondary,
          ),
        ],
      ),
    );
  }
}

class _EmptyChat extends StatelessWidget {
  final String chatName;
  const _EmptyChat({required this.chatName});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: KonectaColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_rounded,
                size: 32, color: KonectaColors.primary),
          ),
          const SizedBox(height: 12),
          Text(
            'Los mensajes son cifrados E2E',
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? KonectaColors.darkTextSecondary
                  : KonectaColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Nadie más puede leerlos, ni Konecta.',
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? KonectaColors.darkTextTertiary
                  : KonectaColors.lightTextTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

