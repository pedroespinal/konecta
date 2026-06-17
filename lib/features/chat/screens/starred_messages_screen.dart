import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/database/models/message_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/konecta_footer.dart';
import '../repositories/chat_repository.dart';

class StarredMessagesScreen extends ConsumerWidget {
  const StarredMessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mensajes guardados'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<MessageModel>>(
              future: ref.read(chatRepositoryProvider).getStarredMessages(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: KonectaColors.primary),
                  );
                }
                final messages = snapshot.data ?? [];
                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: KonectaColors.warning.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.star_outline_rounded,
                            size: 48,
                            color: KonectaColors.warning,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Sin mensajes guardados',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? KonectaColors.darkTextSecondary
                                : KonectaColors.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Mantén presionado un mensaje\ny toca "Destacar"',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            height: 1.5,
                            color: isDark
                                ? KonectaColors.darkTextTertiary
                                : KonectaColors.lightTextTertiary,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: messages.length,
                  separatorBuilder: (context, index) => Divider(
                    indent: 72,
                    height: 0.5,
                    color: isDark ? KonectaColors.darkDivider : KonectaColors.lightDivider,
                  ),
                  itemBuilder: (context, i) {
                    final msg = messages[i];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      leading: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: KonectaColors.warning.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.star_rounded,
                            color: KonectaColors.warning, size: 22),
                      ),
                      title: Text(
                        msg.decryptedContent ?? '[Mensaje cifrado]',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: isDark
                              ? KonectaColors.darkTextPrimary
                              : KonectaColors.lightTextPrimary,
                        ),
                      ),
                      subtitle: Text(
                        _formatDate(msg.sentAt),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isDark
                              ? KonectaColors.darkTextTertiary
                              : KonectaColors.lightTextTertiary,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const KonectaFooter(showVersion: false),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year}  '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }
}
