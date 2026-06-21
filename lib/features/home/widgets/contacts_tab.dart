import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/database/models/chat_model.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/providers/decoy_mode_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/auth/repositories/auth_repository.dart';
import '../../../features/chat/providers/chat_provider.dart';
import '../../../features/chat/repositories/chat_repository.dart';
import '../../../features/chat/screens/chat_screen.dart';
import '../../qr/qr_scanner_screen.dart';

class ContactsTab extends ConsumerStatefulWidget {
  const ContactsTab({super.key});

  @override
  ConsumerState<ContactsTab> createState() => _ContactsTabState();
}

class _ContactsTabState extends ConsumerState<ContactsTab> {
  List<Contact>? _phoneContacts;
  bool _phonePermissionDenied = false;

  @override
  void initState() {
    super.initState();
    _loadPhoneContacts();
  }

  Future<void> _loadPhoneContacts() async {
    final granted = await FlutterContacts.requestPermission(readonly: true);
    if (!granted) {
      if (mounted) setState(() => _phonePermissionDenied = true);
      return;
    }
    final contacts = await FlutterContacts.getContacts(withProperties: true);
    if (mounted) setState(() => _phoneContacts = contacts);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDecoy = ref.watch(decoyModeProvider);

    if (isDecoy) {
      return CustomScrollView(
        slivers: [
          SliverAppBar(
              floating: true, snap: true, title: Text(l10n.navContacts)),
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.people_outline_rounded,
                      size: 56,
                      color: KonectaColors.primary.withValues(alpha: 0.4)),
                  const SizedBox(height: 12),
                  Text('Sin contactos',
                      style: GoogleFonts.inter(
                          fontSize: 15,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant)),
                ],
              ),
            ),
          ),
        ],
      );
    }

    final contactsAsync = ref.watch(contactsProvider);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          snap: true,
          title: Text(l10n.navContacts),
          actions: [
            IconButton(
              icon: const Icon(Icons.qr_code_scanner_rounded),
              tooltip: 'Escanear QR',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const QrScannerScreen()),
              ),
            ),
          ],
        ),

        // Invitar amigos
        const SliverToBoxAdapter(child: _InviteTile()),

        // Contactos Konecta
        contactsAsync.when(
          loading: () => const SliverToBoxAdapter(
            child: Center(
                child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(color: KonectaColors.primary),
            )),
          ),
          error: (e, _) => SliverToBoxAdapter(
            child: Center(child: Text('Error: $e')),
          ),
          data: (contacts) {
            if (contacts.isEmpty && (_phoneContacts == null || _phoneContacts!.isEmpty)) {
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.qr_code_rounded,
                            size: 64,
                            color: KonectaColors.primary.withValues(alpha: 0.3)),
                        const SizedBox(height: 16),
                        Text(
                          'Sin contactos de Konecta aún',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Escanea el código QR de un amigo\npara agregarlo',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const QrScannerScreen()),
                          ),
                          icon: const Icon(Icons.qr_code_scanner_rounded),
                          label: const Text('Escanear QR'),
                          style: FilledButton.styleFrom(
                            backgroundColor: KonectaColors.primary,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 28, vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            if (contacts.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

            return SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index == 0) {
                    return _SectionHeader(
                      icon: Icons.lock_rounded,
                      label: 'En Konecta',
                      color: KonectaColors.primary,
                    );
                  }
                  final c = contacts[index - 1];
                  return _ContactItem(
                    contact: c,
                    onChat: () => _openChat(context, ref, c),
                    onCall: (isVideo) => _startCall(context, ref, c, isVideo),
                  );
                },
                childCount: contacts.length + 1,
              ),
            );
          },
        ),

        // Sección: Directorio telefónico
        if (!_phonePermissionDenied && _phoneContacts != null)
          _PhoneContactsSection(
            contacts: _phoneContacts!,
            konectaIds: contactsAsync.value?.map((c) => c.id).toSet() ?? {},
          ),

        if (_phonePermissionDenied)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: OutlinedButton.icon(
                onPressed: _loadPhoneContacts,
                icon: const Icon(Icons.contacts_rounded),
                label: const Text('Permitir acceso al directorio'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: KonectaColors.primary,
                  side: const BorderSide(color: KonectaColors.primary),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _openChat(
      BuildContext context, WidgetRef ref, ContactModel contact) async {
    final chat =
        await ref.read(chatRepositoryProvider).createIndividualChat(contact);
    ref.invalidate(chatsProvider);
    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ChatScreen(chat: chat)),
    );
  }

  void _startCall(BuildContext context, WidgetRef ref, ContactModel contact,
      bool isVideo) {
    context.push(AppRoutes.call, extra: {
      'peerId': contact.id,
      'peerName': contact.displayName,
      'isVideo': isVideo,
      'isOutgoing': true,
    });
  }
}

class _InviteTile extends StatelessWidget {
  const _InviteTile();

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: KonectaColors.primary.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.share_rounded, color: KonectaColors.primary),
      ),
      title: const Text('Invitar amigos a Konecta'),
      subtitle: const Text('Comparte el enlace de descarga'),
      onTap: () async {
        const link =
            'https://github.com/pedroespinal/konecta/releases/latest';
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

class _ContactItem extends ConsumerWidget {
  final ContactModel contact;
  final VoidCallback onChat;
  final void Function(bool isVideo) onCall;

  const _ContactItem({
    required this.contact,
    required this.onChat,
    required this.onCall,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final myUserId = ref.watch(authProvider).profile?.userId ?? '';
    final isMe = contact.id == myUserId;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: KonectaColors.primary.withValues(alpha: 0.12),
        child: Text(
          contact.displayName.isNotEmpty
              ? contact.displayName[0].toUpperCase()
              : '?',
          style: const TextStyle(
              color: KonectaColors.primary, fontWeight: FontWeight.w700),
        ),
      ),
      title: Text(
        contact.displayName,
        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        isMe
            ? 'Tú'
            : contact.phone ?? contact.id,
        style: TextStyle(
          fontSize: 12,
          color: isMe
              ? KonectaColors.accent
              : (isDark
                  ? KonectaColors.darkTextSecondary
                  : KonectaColors.lightTextSecondary),
        ),
      ),
      trailing: isMe
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.call_outlined, size: 20),
                  color: KonectaColors.primary,
                  onPressed: () => onCall(false),
                ),
                IconButton(
                  icon: const Icon(Icons.videocam_outlined, size: 20),
                  color: KonectaColors.primary,
                  onPressed: () => onCall(true),
                ),
              ],
            ),
      onTap: isMe ? null : onChat,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _SectionHeader({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Divider(
              color: isDark ? KonectaColors.darkBorder : KonectaColors.lightBorder,
              thickness: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _PhoneContactsSection extends StatelessWidget {
  final List<Contact> contacts;
  final Set<String> konectaIds;
  const _PhoneContactsSection({required this.contacts, required this.konectaIds});

  @override
  Widget build(BuildContext context) {
    if (contacts.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (ctx, index) {
          if (index == 0) {
            return _SectionHeader(
              icon: Icons.contacts_rounded,
              label: 'Directorio telefónico',
              color: KonectaColors.accent,
            );
          }
          final c = contacts[index - 1];
          final phone = c.phones.isNotEmpty ? c.phones.first.number : '';
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: KonectaColors.accent.withValues(alpha: 0.12),
              child: Text(
                c.displayName.isNotEmpty ? c.displayName[0].toUpperCase() : '?',
                style: const TextStyle(
                    color: KonectaColors.accent, fontWeight: FontWeight.w700),
              ),
            ),
            title: Text(c.displayName,
                style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
            subtitle: phone.isNotEmpty
                ? Text(phone,
                    style: const TextStyle(fontSize: 12, color: Colors.grey))
                : null,
            trailing: TextButton(
              style: TextButton.styleFrom(
                foregroundColor: KonectaColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              ),
              onPressed: () {
                Share.share(
                  '¡Descarga Konecta! Mensajería privada y segura.\nhttps://github.com/pedroespinal/konecta/releases/latest',
                  subject: 'Konecta — Mensajería segura',
                );
              },
              child: const Text('Invitar'),
            ),
          );
        },
        childCount: contacts.length + 1,
      ),
    );
  }
}
