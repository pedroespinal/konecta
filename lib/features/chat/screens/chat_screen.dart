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
  MessageModel? _replyingTo;
  MessageModel? _editingMessage;
  int _disappearsInSeconds = 0;
  StreamSubscription? _typingSubscription;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _listenToTyping();
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
    _typingSubscription?.cancel();
    _scrollController.dispose();
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
                    : ListView.builder(
                        controller: _scrollController,
                        reverse: true, // más recientes abajo
                        padding: const EdgeInsets.symmetric(
                            horizontal: 0, vertical: 8),
                        itemCount:
                            state.messages.length + (state.hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == state.messages.length) {
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

                          // reversed: index 0 = el más reciente (abajo)
                          final reversed =
                              state.messages.reversed.toList();
                          final msg = reversed[index];
                          final isMine = msg.senderId == myUserId;

                          // Buscar el mensaje al que responde
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
                            onEdit: isMine ? () => setState(() {
                                  _editingMessage = msg;
                                  _replyingTo = null;
                                }) : null,
                            onStar: () => ref
                                .read(chatScreenProvider(widget.chat.id)
                                    .notifier)
                                .starMessage(msg.id, !msg.isStarred),
                          );
                        },
                      ),
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
            const PopupMenuItem(
                value: _ChatAction.search,
                child: Text('Buscar en chat')),
            const PopupMenuItem(
                value: _ChatAction.media, child: Text('Multimedia')),
            const PopupMenuItem(
                value: _ChatAction.mute,
                child: Text('Silenciar notificaciones')),
            const PopupMenuItem(
                value: _ChatAction.wallpaper,
                child: Text('Fondo de pantalla')),
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
      default:
        _showComingSoon(context, action.name);
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

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature — próximamente'),
        backgroundColor: KonectaColors.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

enum _ChatAction { search, media, mute, wallpaper, ephemeral, delete }

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

