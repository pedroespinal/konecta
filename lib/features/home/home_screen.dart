import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/services/update_checker.dart';
import '../../shared/widgets/konecta_footer.dart';
import '../../shared/widgets/update_dialog.dart';
import '../chat/screens/new_chat_screen.dart';
import 'widgets/chats_tab.dart';
import 'widgets/calls_tab.dart';
import 'widgets/stories_tab.dart';
import 'widgets/contacts_tab.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _tabs = [
    ChatsTab(),
    CallsTab(),
    StoriesTab(),
    ContactsTab(),
  ];

  @override
  void initState() {
    super.initState();
    // Verificar actualización después del primer frame
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkForUpdate());
  }

  Future<void> _checkForUpdate() async {
    final info = await UpdateChecker.check();
    if (!info.updateAvailable) return;
    if (!mounted) return;

    final accepted = await UpdateDialog.show(context, info);
    if (accepted && info.updateUrl.isNotEmpty) {
      final uri = Uri.tryParse(info.updateUrl);
      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: Column(
        children: [
          Expanded(child: _tabs[_selectedIndex]),
          const Divider(height: 0.5),
          const KonectaFooter(showVersion: false),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            selectedIcon: const Icon(Icons.chat_bubble_rounded),
            label: l10n.navChats,
          ),
          NavigationDestination(
            icon: const Icon(Icons.call_outlined),
            selectedIcon: const Icon(Icons.call_rounded),
            label: l10n.navCalls,
          ),
          NavigationDestination(
            icon: const Icon(Icons.circle_outlined),
            selectedIcon: const Icon(Icons.circle),
            label: l10n.navStories,
          ),
          NavigationDestination(
            icon: const Icon(Icons.people_outline_rounded),
            selectedIcon: const Icon(Icons.people_rounded),
            label: l10n.navContacts,
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NewChatScreen()),
              ),
              tooltip: l10n.newChat,
              child: const Icon(Icons.edit_rounded),
            )
          : null,
    );
  }
}
