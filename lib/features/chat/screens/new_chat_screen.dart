import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/database/models/chat_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/konecta_footer.dart';
import '../repositories/chat_repository.dart';
import 'chat_screen.dart';

class NewChatScreen extends ConsumerStatefulWidget {
  final int initialTabIndex;
  const NewChatScreen({super.key, this.initialTabIndex = 0});

  @override
  ConsumerState<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends ConsumerState<NewChatScreen>
    with SingleTickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  String _query = '';
  late final TabController _tabCtrl;

  static final _epoch = DateTime.fromMillisecondsSinceEpoch(0);
  // Contactos demo — en Fase 5 vendrán de la DB y del servidor
  static final _demoContacts = [
    ContactModel(id: 'user_alice', displayName: 'Alice Torres', phone: '+1 555 1001', identityPublicKeyHex: '', addedAt: _epoch),
    ContactModel(id: 'user_bob',   displayName: 'Bob Ramírez',  phone: '+1 555 1002', identityPublicKeyHex: '', addedAt: _epoch),
    ContactModel(id: 'user_carol', displayName: 'Carol López',  phone: '+1 555 1003', identityPublicKeyHex: '', addedAt: _epoch),
    ContactModel(id: 'user_diana', displayName: 'Diana Pérez',  phone: '+1 555 1004', identityPublicKeyHex: '', addedAt: _epoch),
    ContactModel(id: 'user_evan',  displayName: 'Evan Morales', phone: '+1 555 1005', identityPublicKeyHex: '', addedAt: _epoch),
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this, initialIndex: widget.initialTabIndex);
    _searchCtrl.addListener(() => setState(() => _query = _searchCtrl.text));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _tabCtrl.dispose();
    super.dispose();
  }

  List<ContactModel> get _filtered => _query.isEmpty
      ? _demoContacts
      : _demoContacts
          .where((c) =>
              c.displayName.toLowerCase().contains(_query.toLowerCase()) ||
              (c.phone?.contains(_query) ?? false))
          .toList();

  Future<void> _openIndividualChat(ContactModel contact) async {
    final repo = ref.read(chatRepositoryProvider);
    final chat = await repo.createIndividualChat(contact);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => ChatScreen(chat: chat)),
    );
  }

  void _openNewGroup() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const _CreateGroupScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor:
          isDark ? KonectaColors.darkBackground : KonectaColors.lightBackground,
      appBar: AppBar(
        backgroundColor:
            isDark ? KonectaColors.darkSurface : KonectaColors.lightSurface,
        elevation: 0,
        title: Text(
          'Nuevo mensaje',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: KonectaColors.primary,
          unselectedLabelColor: isDark
              ? KonectaColors.darkTextSecondary
              : KonectaColors.lightTextSecondary,
          indicatorColor: KonectaColors.primary,
          tabs: const [
            Tab(text: 'Contactos'),
            Tab(text: 'Nuevo grupo'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Buscar contacto o número…',
                hintStyle: GoogleFonts.inter(fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: isDark
                    ? KonectaColors.darkSurface2
                    : KonectaColors.lightSurface,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 0),
              ),
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                // Tab 1: contactos
                _ContactsList(
                  contacts: _filtered,
                  onTap: _openIndividualChat,
                  isDark: isDark,
                ),

                // Tab 2: nuevo grupo
                _NewGroupTab(
                  contacts: _filtered,
                  onCreate: _openNewGroup,
                  isDark: isDark,
                ),
              ],
            ),
          ),

          const KonectaFooter(),
        ],
      ),
    );
  }
}

class _ContactsList extends StatelessWidget {
  final List<ContactModel> contacts;
  final ValueChanged<ContactModel> onTap;
  final bool isDark;
  const _ContactsList({
    required this.contacts,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (contacts.isEmpty) {
      return Center(
        child: Text(
          'No se encontraron contactos',
          style: GoogleFonts.inter(
            color: isDark
                ? KonectaColors.darkTextSecondary
                : KonectaColors.lightTextSecondary,
          ),
        ),
      );
    }
    return ListView.builder(
      itemCount: contacts.length,
      itemBuilder: (_, i) {
        final c = contacts[i];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: KonectaColors.primary.withValues(alpha: 0.12),
            child: Text(
              c.displayName[0].toUpperCase(),
              style: const TextStyle(
                  color: KonectaColors.primary, fontWeight: FontWeight.w700),
            ),
          ),
          title: Text(
            c.displayName,
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            c.phone ?? '',
            style: GoogleFonts.inter(fontSize: 12),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.call_rounded, size: 20),
                color: KonectaColors.accent,
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Llamadas disponibles en Fase 4')),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.videocam_rounded, size: 20),
                color: KonectaColors.secondary,
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Video disponible en Fase 4')),
                ),
              ),
            ],
          ),
          onTap: () => onTap(c),
        );
      },
    );
  }
}

class _NewGroupTab extends StatelessWidget {
  final List<ContactModel> contacts;
  final VoidCallback onCreate;
  final bool isDark;
  const _NewGroupTab({
    required this.contacts,
    required this.onCreate,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: KonectaColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.group_add_rounded,
                size: 40, color: KonectaColors.primary),
          ),
          const SizedBox(height: 16),
          Text(
            'Crear un grupo',
            style: GoogleFonts.inter(
                fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Conecta hasta 1024 personas\ncon cifrado de extremo a extremo',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: isDark
                  ? KonectaColors.darkTextSecondary
                  : KonectaColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.group_add_rounded),
            label: const Text('Crear grupo'),
            style: FilledButton.styleFrom(
              backgroundColor: KonectaColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Pantalla de creación de grupo
class _CreateGroupScreen extends ConsumerStatefulWidget {
  const _CreateGroupScreen();

  @override
  ConsumerState<_CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<_CreateGroupScreen> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _selectedIds = <String>{};
  bool _creating = false;

  static final _epoch = DateTime.fromMillisecondsSinceEpoch(0);
  static final _demoContacts = [
    ContactModel(id: 'user_alice', displayName: 'Alice Torres', identityPublicKeyHex: '', addedAt: _epoch),
    ContactModel(id: 'user_bob',   displayName: 'Bob Ramírez',  identityPublicKeyHex: '', addedAt: _epoch),
    ContactModel(id: 'user_carol', displayName: 'Carol López',  identityPublicKeyHex: '', addedAt: _epoch),
    ContactModel(id: 'user_diana', displayName: 'Diana Pérez',  identityPublicKeyHex: '', addedAt: _epoch),
    ContactModel(id: 'user_evan',  displayName: 'Evan Morales', identityPublicKeyHex: '', addedAt: _epoch),
  ];

  Future<void> _create() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    if (_selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega al menos un participante')),
      );
      return;
    }
    setState(() => _creating = true);
    try {
      final chat = await ref.read(chatRepositoryProvider).createGroup(
            name: _nameCtrl.text.trim(),
            memberIds: _selectedIds.toList(),
            description: _descCtrl.text.trim().isEmpty
                ? null
                : _descCtrl.text.trim(),
          );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => ChatScreen(chat: chat)),
      );
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Text('Nuevo grupo',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        actions: [
          if (_creating)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: KonectaColors.primary),
              ),
            )
          else
            TextButton(
              onPressed: _create,
              child: const Text('Crear',
                  style: TextStyle(color: KonectaColors.primary,
                      fontWeight: FontWeight.w700)),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Nombre del grupo',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.group_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descCtrl,
                  decoration: InputDecoration(
                    labelText: 'Descripción (opcional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.info_outline_rounded),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'Participantes (${_selectedIds.length})',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? KonectaColors.darkTextSecondary
                        : KonectaColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _demoContacts.length,
              itemBuilder: (_, i) {
                final c = _demoContacts[i];
                final selected = _selectedIds.contains(c.id);
                return CheckboxListTile(
                  value: selected,
                  onChanged: (v) {
                    setState(() {
                      if (v == true) {
                        _selectedIds.add(c.id);
                      } else {
                        _selectedIds.remove(c.id);
                      }
                    });
                  },
                  activeColor: KonectaColors.primary,
                  secondary: CircleAvatar(
                    backgroundColor:
                        KonectaColors.primary.withValues(alpha: 0.12),
                    child: Text(
                      c.displayName[0].toUpperCase(),
                      style: const TextStyle(color: KonectaColors.primary),
                    ),
                  ),
                  title: Text(c.displayName,
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                );
              },
            ),
          ),
          const KonectaFooter(),
        ],
      ),
    );
  }
}
