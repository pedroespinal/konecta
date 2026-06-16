import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/database/models/message_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/media/media_service.dart';
import '../../../features/media/voice_recorder_widget.dart';

class ChatInputBar extends StatefulWidget {
  final ValueChanged<String> onSend;
  final ValueChanged<MediaFile>? onMediaSend;
  final VoidCallback? onAttach;
  final VoidCallback? onEmoji;
  final ValueChanged<bool>? onTypingChanged;
  final MessageModel? replyingTo;
  final VoidCallback? onCancelReply;

  const ChatInputBar({
    super.key,
    required this.onSend,
    this.onMediaSend,
    this.onAttach,
    this.onEmoji,
    this.onTypingChanged,
    this.replyingTo,
    this.onCancelReply,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final has = _controller.text.trim().isNotEmpty;
    if (has != _hasText) {
      setState(() => _hasText = has);
      widget.onTypingChanged?.call(has);
    }
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    widget.onSend(text);
    widget.onTypingChanged?.call(false);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Banner de respuesta
        if (widget.replyingTo != null)
          _ReplyBanner(
            message: widget.replyingTo!,
            onCancel: widget.onCancelReply,
            isDark: isDark,
          ),

        // Barra de entrada
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? KonectaColors.darkBackground : KonectaColors.lightBackground,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Emoji
                _BarButton(
                  icon: Icons.emoji_emotions_outlined,
                  onTap: () {
                    widget.onEmoji?.call();
                    _focus.requestFocus();
                  },
                ),

                // Campo de texto
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 120),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: isDark
                          ? KonectaColors.darkSurface2
                          : KonectaColors.lightSurface,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _controller,
                      focusNode: _focus,
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: isDark
                            ? KonectaColors.darkTextPrimary
                            : KonectaColors.lightTextPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Escribe un mensaje…',
                        hintStyle: GoogleFonts.inter(
                          fontSize: 15,
                          color: isDark
                              ? KonectaColors.darkTextTertiary
                              : KonectaColors.lightTextTertiary,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        suffixIcon: _hasText
                            ? null
                            : IconButton(
                                icon: const Icon(
                                  Icons.attach_file_rounded,
                                  size: 22,
                                ),
                                color: isDark
                                    ? KonectaColors.darkTextSecondary
                                    : KonectaColors.lightTextSecondary,
                                onPressed: () async {
                                  final file = await MediaService.showPicker(context);
                                  if (file != null) {
                                    widget.onMediaSend?.call(file);
                                  }
                                  widget.onAttach?.call();
                                },
                              ),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                ),

                // Botón enviar / grabador de voz
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, anim) => ScaleTransition(
                    scale: anim,
                    child: child,
                  ),
                  child: _hasText
                      ? _SendButton(key: const ValueKey('send'), onTap: _send)
                      : VoiceRecorderButton(
                          key: const ValueKey('mic'),
                          onRecorded: (file) {
                            widget.onMediaSend?.call(file);
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BarButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _BarButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            size: 24,
            color: isDark
                ? KonectaColors.darkTextSecondary
                : KonectaColors.lightTextSecondary,
          ),
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  final VoidCallback onTap;
  const _SendButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [KonectaColors.primary, KonectaColors.secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
      ),
    );
  }
}

class _ReplyBanner extends StatelessWidget {
  final MessageModel message;
  final VoidCallback? onCancel;
  final bool isDark;
  const _ReplyBanner({
    required this.message,
    required this.isDark,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isDark ? KonectaColors.darkSurface2 : KonectaColors.lightSurface,
      child: Row(
        children: [
          Container(
            width: 3,
            height: 36,
            decoration: BoxDecoration(
              color: KonectaColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Responder a',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: KonectaColors.primary,
                  ),
                ),
                Text(
                  message.decryptedContent ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: isDark
                        ? KonectaColors.darkTextSecondary
                        : KonectaColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18),
            onPressed: onCancel,
            color:
                isDark ? KonectaColors.darkTextSecondary : KonectaColors.lightTextSecondary,
          ),
        ],
      ),
    );
  }
}
