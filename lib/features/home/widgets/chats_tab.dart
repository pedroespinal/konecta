import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_version.dart';
import '../../../core/database/daos/chats_dao.dart';
import '../../../core/database/models/chat_model.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/providers/decoy_mode_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/chat/providers/chat_provider.dart';
import '../../../features/chat/screens/chat_screen.dart';
import '../../../features/chat/screens/new_chat_screen.dart';
import '../../../features/guide/guide_screen.dart';
import '../screens/chat_search_screen.dart';

class ChatsTab extends ConsumerWidget {
  const ChatsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isDecoy = ref.watch(decoyModeProvider);
    final chatsAsync = isDecoy ? const AsyncValue<List<ChatModel>>.data([]) : ref.watch(chatsProvider);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          snap: true,
          title: Row(
            children: [
              Text(l10n.navChats),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: KonectaColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: KonectaColors.primary.withValues(alpha: 0.25),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  AppVersion.fullVersion,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: KonectaColors.primary,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.qr_code_rounded),
              onPressed: () => context.push(AppRoutes.qr),
              tooltip: 'Mi código QR',
            ),
            IconButton(
              icon: const Icon(Icons.search_rounded),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ChatSearchScreen(),
                ),
              ),
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
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const NewChatScreen(initialTabIndex: 1),
                      ),
                    );
                  case 'archived':
                    _showArchivedChats(context, ref);
                  case 'mark_read':
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Todo marcado como leído'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  case 'settings':
                    context.push(AppRoutes.settings);
                  case 'guide':
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const GuideScreen()),
                    );
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
                    value: 'guide',
                    child: Row(children: [
                      const Icon(Icons.auto_stories_rounded, size: 20),
                      const SizedBox(width: 12),
                      Text('Guía de usuario',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
                    ]),
                  ),
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
              return SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.chat_bubble_outline_rounded,
                          size: 64,
                          color: KonectaColors.primary.withValues(alpha: 0.3)),
                      const SizedBox(height: 16),
                      Text(
                        'Sin chats aún',
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Escanea el QR de un amigo\npara iniciar una conversación',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
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

Future<void> _showArchivedChats(BuildContext ctx, WidgetRef ref) async {
  final all = await ChatsDao().getAll(includeArchived: true);
  final archived = all.where((c) => c.isArchived).toList();
  if (!ctx.mounted) return;
  showModalBottomSheet(
    context: ctx,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (bCtx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (_, sc) => Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text('Chats archivados',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 8),
          if (archived.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.archive_rounded, size: 48,
                        color: KonectaColors.primary.withValues(alpha: 0.3)),
                    const SizedBox(height: 12),
                    Text('No hay chats archivados',
                        style: GoogleFonts.inter(
                            color: Colors.grey, fontSize: 14)),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                controller: sc,
                itemCount: archived.length,
                itemBuilder: (_, i) => _RealChatItem(
                  chat: archived[i],
                  onTap: () {
                    Navigator.pop(bCtx);
                    Navigator.of(ctx).push(MaterialPageRoute(
                      builder: (_) => ChatScreen(chat: archived[i]),
                    ));
                  },
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
