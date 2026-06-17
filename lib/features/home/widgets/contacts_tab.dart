import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/providers/decoy_mode_provider.dart';
import '../../../core/theme/app_colors.dart';

class ContactsTab extends ConsumerWidget {
  const ContactsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isDecoy = ref.watch(decoyModeProvider);

    if (isDecoy) {
      return CustomScrollView(
        slivers: [
          SliverAppBar(floating: true, snap: true, title: Text(l10n.navContacts)),
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.people_outline_rounded,
                      size: 56, color: KonectaColors.primary.withValues(alpha: 0.4)),
                  const SizedBox(height: 12),
                  Text('Sin contactos',
                      style: GoogleFonts.inter(
                          fontSize: 15, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          snap: true,
          title: Text(l10n.navContacts),
          actions: [
            IconButton(
              icon: const Icon(Icons.person_add_rounded),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Agregar contacto por teléfono o QR — próximamente'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
            IconButton(icon: const Icon(Icons.search_rounded), onPressed: () {}),
          ],
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (index == 0) {
                return _InviteTile();
              }
              return _ContactItem(index: index - 1);
            },
            childCount: 13,
          ),
        ),
      ],
    );
  }
}

class _InviteTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 52, height: 52,
        decoration: BoxDecoration(
          color: KonectaColors.primary.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.share_rounded, color: KonectaColors.primary),
      ),
      title: const Text('Invitar amigos a Konecta'),
      subtitle: const Text('Comparte el enlace de descarga'),
      onTap: () async {
        const link = 'https://github.com/pedroespinal/konecta/releases/latest';
        await Clipboard.setData(const ClipboardData(text: link));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Enlace copiado! Compártelo con tus amigos'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      },
    );
  }
}

class _ContactItem extends StatelessWidget {
  final int index;
  const _ContactItem({required this.index});

  static const _contacts = [
    'Ana Jimenez', 'Carlos Lopez', 'Diego Morales', 'Fernando Vega',
    'Juan Perez', 'Laura Martinez', 'Maria Garcia', 'Miguel Torres',
    'Roberto Silva', 'Sofia Chen', 'Valentina Ruiz', 'Ximena Castro',
  ];

  @override
  Widget build(BuildContext context) {
    if (index >= _contacts.length) return const SizedBox.shrink();
    final name = _contacts[index];
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _color(index).withValues(alpha: 0.15),
        child: Text(
          name[0],
          style: TextStyle(color: _color(index), fontWeight: FontWeight.w700),
        ),
      ),
      title: Text(name),
      subtitle: Text('En Konecta',
          style: TextStyle(color: KonectaColors.accent, fontSize: 12)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.call_outlined, size: 20),
            color: KonectaColors.primary,
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.videocam_outlined, size: 20),
            color: KonectaColors.primary,
            onPressed: () {},
          ),
        ],
      ),
      onTap: () {},
    );
  }

  Color _color(int i) {
    const colors = [
      KonectaColors.primary, KonectaColors.secondary, KonectaColors.accent,
      Color(0xFFEC4899), Color(0xFFF59E0B), Color(0xFF8B5CF6),
    ];
    return colors[i % colors.length];
  }
}
