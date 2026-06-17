import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/database/models/chat_model.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/chat/providers/chat_provider.dart';
import '../../../features/chat/screens/chat_screen.dart';

class ChatsTab extends ConsumerWidget {
  const ChatsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final chatsAsync = ref.watch(chatsProvider);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          snap: true,
          title: Text(l10n.navChats),
          actions: [
            IconButton(
              icon: const Icon(Icons.qr_code_scanner_rounded),
              onPressed: () {},
              tooltip: 'Escanear QR',
            ),
            IconButton(
              icon: const Icon(Icons.search_rounded),
              onPressed: () {},
              tooltip: l10n.search,
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              onSelected: (value) {
                switch (value) {
                  case 'new_group':
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Grupos: próximamente'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  case 'archived':
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Archivados: próximamente'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  case 'mark_read':
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Todo marcado como leído'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  case 'settings':
                    context.push(AppRoutes.settings);
                }
              },
              itemBuilder: (ctx) {
                final l10n = AppLocalizations.of(ctx);
                return [
                  PopupMenuItem(
                    value: 'new_group',
                    child: Row(children: [
                      const Icon(Icons.group_add_rounded, size: 20),
                      const SizedBox(width: 12),
                      Text(l10n.newGroup,
                          style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
                    ]),
                  ),
                  PopupMenuItem(
                    value: 'mark_read',
                    child: Row(children: [
                      const Icon(Icons.done_all_rounded, size: 20),
                      const SizedBox(width: 12),
                      Text(l10n.markAllRead,
                          style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
                    ]),
                  ),
                  PopupMenuItem(
                    value: 'archived',
                    child: Row(children: [
                      const Icon(Icons.archive_rounded, size: 20),
                      const SizedBox(width: 12),
                      Text(l10n.archivedChats,
                          style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
                    ]),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'settings',
                    child: Row(children: [
                      const Icon(Icons.settings_rounded, size: 20),
                      const SizedBox(width: 12),
                      Text(l10n.settings,
                          style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
                    ]),
                  ),
                ];
              },
            ),
          ],
        ),
        // Banner de encriptacion E2E
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: KonectaColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: KonectaColors.primary.withValues(alpha: 0.2),
                width: 0.5,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.lock_rounded,
                    size: 16, color: KonectaColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.encryptedMsg,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: KonectaColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Lista real de chats (desde DB) + fallback demo
        chatsAsync.when(
          loading: () => const SliverFillRemaining(
            child: Center(
              child: CircularProgressIndicator(color: KonectaColors.primary),
            ),
          ),
          error: (e, _) => SliverFillRemaining(
            child: Center(child: Text('Error: $e')),
          ),
          data: (chats) {
            if (chats.isEmpty) {
              // Si no hay chats reales, muestra la demo
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _DemoChatItem(index: index),
                  childCount: 15,
                ),
              );
            }
            return SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final chat = chats[index];
                  return _RealChatItem(
                    chat: chat,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => ChatScreen(chat: chat)),
                    ),
                  );
                },
                childCount: chats.length,
              ),
            );
          },
        ),
      ],
    );
  }
}

// Item de chat real desde la base de datos
class _RealChatItem extends StatelessWidget {
  final ChatModel chat;
  final VoidCallback onTap;

  const _RealChatItem({required this.chat, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasUnread = chat.unreadCount > 0;
    final lastMsg = chat.lastMessagePreview ?? '(Sin mensajes)';
    final lastTime = chat.lastMessageAt != null
        ? _formatTime(chat.lastMessageAt!)
        : '';

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: KonectaColors.primary.withValues(alpha: 0.15),
                  backgroundImage: chat.avatarPath != null
                      ? AssetImage(chat.avatarPath!)
                      : null,
                  child: chat.avatarPath == null
                      ? Text(
                          chat.name.isNotEmpty ? chat.name[0].toUpperCase() : '?',
                          style: const TextStyle(
                            color: KonectaColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        )
                      : null,
                ),
                if (chat.type == ChatType.group)
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: KonectaColors.secondary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark
                              ? KonectaColors.darkBackground
                              : KonectaColors.lightBackground,
                          width: 2,
                        ),
                      ),
                      child: const Icon(Icons.group_rounded,
                          size: 10, color: Colors.white),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (chat.isPinned)
                        const Padding(
                          padding: EdgeInsets.only(right: 4),
                          child: Icon(Icons.push_pin_rounded,
                              size: 12, color: KonectaColors.primary),
                        ),
                      Expanded(
                        child: Text(
                          chat.name,
                          style: GoogleFonts.inter(
                            fontWeight:
                                hasUnread ? FontWeight.w700 : FontWeight.w600,
                            fontSize: 15,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        lastTime,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: hasUnread
                              ? KonectaColors.primary
                              : (isDark
                                  ? KonectaColors.darkTextTertiary
                                  : KonectaColors.lightTextTertiary),
                          fontWeight: hasUnread
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          lastMsg,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: hasUnread
                                ? FontWeight.w500
                                : FontWeight.w400,
                            color: isDark
                                ? KonectaColors.darkTextSecondary
                                : KonectaColors.lightTextSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (chat.isMuted)
                        const Icon(Icons.volume_off_rounded,
                            size: 14, color: KonectaColors.darkTextTertiary),
                      if (hasUnread) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: chat.isMuted
                                ? KonectaColors.darkTextTertiary
                                : KonectaColors.primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            chat.unreadCount > 99
                                ? '99+'
                                : chat.unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Ayer';
    } else if (diff.inDays < 7) {
      const days = ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];
      return days[dt.weekday % 7];
    } else {
      return '${dt.day}/${dt.month}';
    }
  }
}

// Item demo (cuando no hay chats en la DB)
class _DemoChatItem extends StatelessWidget {
  final int index;
  const _DemoChatItem({required this.index});

  static final List<Map<String, String>> _demoData = [
    {'name': 'Maria Garcia',   'msg': 'Hola! Como estas?',           'time': '10:42', 'unread': '3'},
    {'name': 'Carlos Lopez',   'msg': 'Te mando los archivos ahora', 'time': '10:15', 'unread': ''},
    {'name': 'Familia 🏠',     'msg': 'Ana: Nos vemos el sabado',    'time': '09:30', 'unread': '7'},
    {'name': 'Juan Perez',     'msg': 'Perfecto, gracias!',          'time': 'Ayer',  'unread': ''},
    {'name': 'Trabajo Dev',    'msg': 'Pedro: Revisamos mañana',     'time': 'Ayer',  'unread': '2'},
    {'name': 'Laura Martinez', 'msg': '🎵 Audio (0:34)',             'time': 'Ayer',  'unread': ''},
    {'name': 'Roberto Silva',  'msg': 'Foto',                        'time': 'Mar',   'unread': ''},
    {'name': 'Amigos 🎉',      'msg': 'Carlos: jaja exacto!',        'time': 'Mar',   'unread': '12'},
    {'name': 'Sofia Chen',     'msg': 'Llamada de voz • 5 min',      'time': 'Lun',   'unread': ''},
    {'name': 'Diego Morales',  'msg': 'Ok confirmo',                 'time': 'Dom',   'unread': ''},
    {'name': 'Valentina Ruiz', 'msg': 'Video (0:15)',                'time': 'Sab',   'unread': ''},
    {'name': 'Proyecto Konecta','msg': 'Build aprobado ✅',          'time': 'Vie',   'unread': ''},
    {'name': 'Miguel Torres',  'msg': 'Hablamos luego',              'time': 'Jue',   'unread': ''},
    {'name': 'Ana Jimenez',    'msg': 'Documento.pdf',               'time': 'Mie',   'unread': ''},
    {'name': 'Fernando Vega',  'msg': 'Encriptado 🔒',               'time': 'Mar',   'unread': '1'},
  ];

  @override
  Widget build(BuildContext context) {
    if (index >= _demoData.length) return const SizedBox.shrink();
    final data = _demoData[index];
    final hasUnread = data['unread']!.isNotEmpty;

    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Toca el botón + para iniciar un chat real'),
            duration: Duration(seconds: 2),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: _avatarColor(index),
                  child: Text(
                    data['name']![0],
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ),
                if (index < 3)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 13,
                      height: 13,
                      decoration: BoxDecoration(
                        color: KonectaColors.online,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          data['name']!,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(
                                fontWeight: hasUnread
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        data['time']!,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: hasUnread ? KonectaColors.primary : null,
                              fontWeight: hasUnread
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          data['msg']!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: hasUnread
                                    ? FontWeight.w500
                                    : FontWeight.w400,
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (hasUnread) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: KonectaColors.primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            data['unread']!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _avatarColor(int i) {
    const colors = [
      KonectaColors.primary,
      KonectaColors.secondary,
      KonectaColors.accent,
      Color(0xFFEC4899),
      Color(0xFFF59E0B),
      Color(0xFF8B5CF6),
    ];
    return colors[i % colors.length];
  }
}
