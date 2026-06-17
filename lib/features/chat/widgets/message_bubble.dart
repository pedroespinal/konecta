import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/database/models/message_model.dart';
import '../../../core/theme/app_colors.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMine;
  final bool showSender;
  final String? senderName;
  final VoidCallback? onReply;
  final VoidCallback? onDelete;
  final ValueChanged<String?>? onReact;
  final VoidCallback? onEdit;
  final VoidCallback? onStar;
  final MessageModel? replyTo;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    this.showSender = false,
    this.senderName,
    this.onReply,
    this.onDelete,
    this.onReact,
    this.onEdit,
    this.onStar,
    this.replyTo,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onLongPress: () => _showContextMenu(context),
      child: Align(
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment:
              isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMine)
              const Padding(
                padding: EdgeInsets.only(left: 8, bottom: 4),
                child: CircleAvatar(
                  radius: 14,
                  backgroundColor: KonectaColors.secondary,
                  child: Icon(Icons.person, size: 16, color: Colors.white),
                ),
              ),
            Flexible(
              child: Container(
                margin: EdgeInsets.only(
                  left: isMine ? 64 : 4,
                  right: isMine ? 8 : 64,
                  top: 2,
                  bottom: 2,
                ),
                child: Column(
                  crossAxisAlignment:
                      isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    // Bubble
                    _BubbleContainer(
                      isMine: isMine,
                      isDark: isDark,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Nombre del remitente (grupos)
                          if (showSender && !isMine && senderName != null) ...[
                            Text(
                              senderName!,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: KonectaColors.secondary,
                              ),
                            ),
                            const SizedBox(height: 3),
                          ],

                          // Mensaje citado (reply)
                          if (replyTo != null)
                            _ReplyPreview(
                              replyTo: replyTo!,
                              isMine: isMine,
                              isDark: isDark,
                            ),

                          // Contenido del mensaje
                          if (message.isDeleted)
                            Text(
                              '🚫 Mensaje eliminado',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                                color: isDark
                                    ? KonectaColors.darkTextSecondary
                                    : KonectaColors.lightTextSecondary,
                              ),
                            )
                          else
                            _MessageContent(
                              message: message,
                              isMine: isMine,
                              isDark: isDark,
                            ),

                          // Hora + efímero + estado
                          const SizedBox(height: 3),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (message.disappearsAt != null) ...[
                                Icon(
                                  Icons.timer_rounded,
                                  size: 11,
                                  color: isMine ? Colors.white60 : KonectaColors.secondary,
                                ),
                                const SizedBox(width: 2),
                              ],
                              Text(
                                _formatTime(message.sentAt),
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: isMine
                                      ? Colors.white60
                                      : (isDark
                                          ? KonectaColors.darkTextTertiary
                                          : KonectaColors.lightTextTertiary),
                                ),
                              ),
                              if (isMine) ...[
                                const SizedBox(width: 4),
                                _StatusIcon(status: message.status),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Reaccion (emoji)
                    if (message.reactionEmoji != null)
                      Container(
                        margin: const EdgeInsets.only(top: 2, right: 4, left: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark
                              ? KonectaColors.darkSurface3
                              : KonectaColors.lightSurface3,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark
                                ? KonectaColors.darkBorder
                                : KonectaColors.lightBorder,
                          ),
                        ),
                        child: Text(
                          message.reactionEmoji!,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _MessageContextMenu(
        message: message,
        isMine: isMine,
        onReply: onReply,
        onDelete: onDelete,
        onReact: onReact,
        onEdit: onEdit,
        onStar: onStar,
        onCopy: () {
          final text = message.decryptedContent ?? '';
          Clipboard.setData(ClipboardData(text: text));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Mensaje copiado'),
              duration: Duration(seconds: 1),
            ),
          );
        },
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _BubbleContainer extends StatelessWidget {
  final bool isMine;
  final bool isDark;
  final Widget child;
  const _BubbleContainer({
    required this.isMine,
    required this.isDark,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isMine
        ? KonectaColors.primary
        : (isDark ? KonectaColors.darkSurface2 : KonectaColors.lightSurface);
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isMine ? 18 : 4),
          bottomRight: Radius.circular(isMine ? 4 : 18),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      child: child,
    );
  }
}

class _MessageContent extends StatelessWidget {
  final MessageModel message;
  final bool isMine;
  final bool isDark;
  const _MessageContent({
    required this.message,
    required this.isMine,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    switch (message.type) {
      case MessageType.text:
        return Text(
          message.decryptedContent ?? '...',
          style: GoogleFonts.inter(
            fontSize: 15,
            height: 1.4,
            color: isMine
                ? Colors.white
                : (isDark
                    ? KonectaColors.darkTextPrimary
                    : KonectaColors.lightTextPrimary),
          ),
        );
      case MessageType.audio:
        return _AudioBubble(isMine: isMine, duration: message.mediaDuration ?? 0);
      case MessageType.image:
        return _ImageBubble(path: message.mediaPath);
      case MessageType.system:
        return Text(
          message.decryptedContent ?? '',
          style: GoogleFonts.inter(fontSize: 12, fontStyle: FontStyle.italic),
          textAlign: TextAlign.center,
        );
      default:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.attach_file_rounded,
                size: 18,
                color: isMine ? Colors.white70 : KonectaColors.primary),
            const SizedBox(width: 6),
            Text(
              message.decryptedContent ?? 'Archivo',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: isMine ? Colors.white : KonectaColors.primary,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        );
    }
  }
}

class _AudioBubble extends StatelessWidget {
  final bool isMine;
  final int duration;
  const _AudioBubble({required this.isMine, required this.duration});

  String get _durationStr {
    final m = duration ~/ 60;
    final s = duration % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.play_circle_rounded,
            color: isMine ? Colors.white : KonectaColors.primary, size: 32),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Onda de audio visual
            Row(
              children: List.generate(
                20,
                (i) => Container(
                  width: 3,
                  height: (4 + (i % 5) * 4).toDouble(),
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: BoxDecoration(
                    color: (isMine ? Colors.white : KonectaColors.primary)
                        .withValues(alpha: 0.6 + (i % 3) * 0.13),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _durationStr,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: isMine ? Colors.white70 : KonectaColors.darkTextSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ImageBubble extends StatelessWidget {
  final String? path;
  const _ImageBubble({this.path});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: path != null
          ? Image.asset(path!, width: 200, fit: BoxFit.cover)
          : Container(
              width: 200,
              height: 150,
              color: KonectaColors.darkSurface3,
              child: const Icon(Icons.image_rounded,
                  size: 40, color: KonectaColors.darkTextSecondary),
            ),
    );
  }
}

class _ReplyPreview extends StatelessWidget {
  final MessageModel replyTo;
  final bool isMine;
  final bool isDark;
  const _ReplyPreview({
    required this.replyTo,
    required this.isMine,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: (isMine ? Colors.white : KonectaColors.primary)
            .withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: isMine ? Colors.white : KonectaColors.primary,
            width: 3,
          ),
        ),
      ),
      child: Text(
        replyTo.decryptedContent ?? '',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.inter(
          fontSize: 12,
          color: isMine ? Colors.white70 : KonectaColors.primary,
        ),
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  final MessageStatus status;
  const _StatusIcon({required this.status});

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case MessageStatus.sending:
        return const Icon(Icons.access_time_rounded, size: 12, color: Colors.white60);
      case MessageStatus.sent:
        return const Icon(Icons.check_rounded, size: 13, color: Colors.white70);
      case MessageStatus.delivered:
        return const Icon(Icons.done_all_rounded, size: 13, color: Colors.white70);
      case MessageStatus.read:
        return const Icon(Icons.done_all_rounded,
            size: 13, color: KonectaColors.primaryLight);
      case MessageStatus.failed:
        return const Icon(Icons.error_outline_rounded,
            size: 13, color: KonectaColors.error);
    }
  }
}

class _MessageContextMenu extends StatelessWidget {
  final MessageModel message;
  final bool isMine;
  final VoidCallback? onReply;
  final VoidCallback? onDelete;
  final VoidCallback? onCopy;
  final VoidCallback? onEdit;
  final VoidCallback? onStar;
  final ValueChanged<String?>? onReact;

  const _MessageContextMenu({
    required this.message,
    required this.isMine,
    this.onReply,
    this.onDelete,
    this.onCopy,
    this.onEdit,
    this.onStar,
    this.onReact,
  });

  static const _emojis = ['👍', '❤️', '😂', '😮', '😢', '🙏'];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            // Reacciones rapidas
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _emojis.map((e) {
                  final isActive = message.reactionEmoji == e;
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      onReact?.call(isActive ? null : e);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isActive
                            ? KonectaColors.primary.withValues(alpha: 0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(e, style: const TextStyle(fontSize: 26)),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.reply_rounded),
              title: const Text('Responder'),
              onTap: () { Navigator.pop(context); onReply?.call(); },
            ),
            if (message.type == MessageType.text)
              ListTile(
                leading: const Icon(Icons.copy_rounded),
                title: const Text('Copiar'),
                onTap: () { Navigator.pop(context); onCopy?.call(); },
              ),
            ListTile(
              leading: Icon(
                message.isStarred ? Icons.star_rounded : Icons.star_outline_rounded,
                color: message.isStarred ? KonectaColors.warning : null,
              ),
              title: Text(message.isStarred ? 'Quitar guardado' : 'Destacar'),
              onTap: () { Navigator.pop(context); onStar?.call(); },
            ),
            if (isMine && !message.isDeleted && message.type == MessageType.text)
              ListTile(
                leading: const Icon(Icons.edit_rounded),
                title: const Text('Editar'),
                onTap: () { Navigator.pop(context); onEdit?.call(); },
              ),
            if (isMine && !message.isDeleted)
              ListTile(
                leading: const Icon(Icons.delete_rounded,
                    color: KonectaColors.error),
                title: const Text('Eliminar',
                    style: TextStyle(color: KonectaColors.error)),
                onTap: () { Navigator.pop(context); onDelete?.call(); },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
