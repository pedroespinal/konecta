import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/chat/providers/chat_provider.dart';
import '../../../features/chat/screens/chat_screen.dart';

class ChatSearchScreen extends ConsumerStatefulWidget {
  const ChatSearchScreen({super.key});

  @override
  ConsumerState<ChatSearchScreen> createState() => _ChatSearchScreenState();
}

class _ChatSearchScreenState extends ConsumerState<ChatSearchScreen> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chatsAsync = ref.watch(chatsProvider);

    final filtered = chatsAsync.when(
      data: (chats) => chats
          .where((c) =>
              _query.isEmpty ||
              c.name.toLowerCase().contains(_query.toLowerCase()) ||
              (c.lastMessagePreview ?? '')
                  .toLowerCase()
                  .contains(_query.toLowerCase()))
          .toList(),
      loading: () => [],
      error: (e, st) => [],
    );

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: TextField(
          controller: _controller,
          autofocus: true,
          onChanged: (v) => setState(() => _query = v),
          style: GoogleFonts.inter(fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Buscar chats...',
            hintStyle: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
        ),
        actions: [
          if (_query.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_rounded),
              onPressed: () {
                _controller.clear();
                setState(() => _query = '');
              },
            ),
        ],
      ),
      body: chatsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: KonectaColors.primary),
        ),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (chats) {
          if (_query.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.search_rounded,
                    size: 64,
                    color: isDark
                        ? KonectaColors.darkTextTertiary
                        : KonectaColors.lightTextTertiary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Busca por nombre o mensaje',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: isDark
                          ? KonectaColors.darkTextSecondary
                          : KonectaColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            );
          }
          if (filtered.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.search_off_rounded,
                    size: 64,
                    color: isDark
                        ? KonectaColors.darkTextTertiary
                        : KonectaColors.lightTextTertiary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Sin resultados para "$_query"',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: isDark
                          ? KonectaColors.darkTextSecondary
                          : KonectaColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final chat = filtered[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: KonectaColors.primary.withValues(alpha: 0.15),
                  child: Text(
                    chat.name.isNotEmpty ? chat.name[0].toUpperCase() : '?',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      color: KonectaColors.primary,
                    ),
                  ),
                ),
                title: _HighlightText(text: chat.name, query: _query),
                subtitle: chat.lastMessagePreview != null
                    ? _HighlightText(
                        text: chat.lastMessagePreview!,
                        query: _query,
                        isSubtitle: true,
                      )
                    : null,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(chat: chat),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _HighlightText extends StatelessWidget {
  final String text;
  final String query;
  final bool isSubtitle;

  const _HighlightText({
    required this.text,
    required this.query,
    this.isSubtitle = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (query.isEmpty) {
      return Text(
        text,
        style: GoogleFonts.inter(
          fontSize: isSubtitle ? 13 : 15,
          fontWeight: isSubtitle ? FontWeight.w400 : FontWeight.w600,
          color: isSubtitle
              ? (isDark
                  ? KonectaColors.darkTextSecondary
                  : KonectaColors.lightTextSecondary)
              : null,
        ),
        overflow: TextOverflow.ellipsis,
      );
    }

    final lower = text.toLowerCase();
    final queryLower = query.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;

    while (true) {
      final idx = lower.indexOf(queryLower, start);
      if (idx == -1) {
        spans.add(TextSpan(text: text.substring(start)));
        break;
      }
      if (idx > start) {
        spans.add(TextSpan(text: text.substring(start, idx)));
      }
      spans.add(TextSpan(
        text: text.substring(idx, idx + query.length),
        style: TextStyle(
          color: KonectaColors.primary,
          fontWeight: FontWeight.w700,
          backgroundColor: KonectaColors.primary.withValues(alpha: 0.12),
        ),
      ));
      start = idx + query.length;
    }

    return RichText(
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: GoogleFonts.inter(
          fontSize: isSubtitle ? 13 : 15,
          fontWeight: isSubtitle ? FontWeight.w400 : FontWeight.w600,
          color: isSubtitle
              ? (isDark
                  ? KonectaColors.darkTextSecondary
                  : KonectaColors.lightTextSecondary)
              : Theme.of(context).colorScheme.onSurface,
        ),
        children: spans,
      ),
    );
  }
}
