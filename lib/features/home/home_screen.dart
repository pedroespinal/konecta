import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/network/message_payload.dart';
import '../../core/network/socket_client.dart';
import '../../core/notifications/fcm_service.dart';
import '../../core/services/update_checker.dart';
import '../../shared/widgets/konecta_footer.dart';
import '../../shared/widgets/update_dialog.dart';
import '../auth/repositories/auth_repository.dart';
import '../chat/providers/chat_provider.dart';
import '../chat/repositories/chat_repository.dart';
import '../chat/screens/chat_screen.dart';
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

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  int _selectedIndex = 0;
  StreamSubscription? _msgSub;

  static const List<Widget> _tabs = [
    ChatsTab(),
    CallsTab(),
    StoriesTab(),
    ContactsTab(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _connectWebSocket();
      _checkForUpdate();
      _handlePendingFcm();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _msgSub?.cancel();
    ref.read(socketProvider.notifier).disconnect();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final status = ref.read(socketProvider).status;
      if (status == SocketStatus.disconnected || status == SocketStatus.error) {
        _connectWebSocket();
      }
    }
  }

  /// Conecta el WebSocket relay y activa el listener global de mensajes entrantes.
  void _connectWebSocket() {
    final profile = ref.read(authProvider).profile;
    if (profile == null) return;

    final fcmToken = FcmService.pendingFcmToken;
    ref.read(socketProvider.notifier).connect(
          profile.userId,
          profile.userId,
          fcmToken: fcmToken,
        );

    // Registrar el token FCM en el relay también via HTTP, independientemente
    // del WebSocket. Esto resuelve dos problemas:
    // 1. Race condition: si el token FCM llegó después de la conexión WS.
    // 2. Relay restart: el relay pierde los tokens en memoria al reiniciar.
    if (fcmToken != null) {
      FcmService.registerTokenWithRelay(profile.userId, fcmToken);
    }

    _msgSub?.cancel();
    _msgSub = ref
        .read(socketProvider.notifier)
        .messages
        .listen(_onSocketMessage);
  }

  Future<void> _onSocketMessage(MessagePayload payload) async {
    final myUserId = ref.read(authProvider).profile?.userId ?? '';
    // Usar chatId del payload cuando está disponible (v1.2.1+).
    // Fallback: derivar de from + myUserId para chats individuales.
    final chatId = payload.chatId.isNotEmpty
        ? payload.chatId
        : 'chat_${([payload.from, myUserId]..sort()).join('_')}';
    try {
      await ref.read(chatRepositoryProvider).receiveMessage(payload, chatId);
      ref.invalidate(chatsProvider);
    } catch (_) {}
  }

  /// Procesa mensajes recibidos via FCM cuando el usuario estaba offline,
  /// y navega al chat pendiente si lo hay.
  Future<void> _handlePendingFcm() async {
    final repo = ref.read(chatRepositoryProvider);
    bool didReceive = false;

    // 1. Mensajes guardados por onBackgroundMessage (app estaba cerrada).
    //    Se guardaron en SharedPreferences; los procesamos aquí en el hilo
    //    principal donde sqflite sí funciona.
    final bgMessages = await FcmService.popPendingBackgroundMessages();
    for (final data in bgMessages) {
      try {
        await repo.receiveFcmMessage(data);
        didReceive = true;
      } catch (_) {}
    }

    // 2. Mensaje guardado al tocar una notificación (onMessageOpenedApp /
    //    getInitialMessage).
    final msgData = FcmService.pendingMessageData;
    if (msgData != null) {
      FcmService.clearPendingMessageData();
      try {
        await repo.receiveFcmMessage(msgData);
        didReceive = true;
      } catch (_) {}
    }

    if (didReceive) ref.invalidate(chatsProvider);

    // 3. Navegar al chat pendiente (si el usuario tocó la notificación).
    final chatId = FcmService.pendingChatId;
    if (chatId == null) return;
    FcmService.clearPendingChatId();
    final chats = await repo.loadChats();
    final chat = chats.where((c) => c.id == chatId).firstOrNull;
    if (chat != null && mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ChatScreen(chat: chat)),
      );
    }
  }

  Future<void> _checkForUpdate() async {
    final info = await UpdateChecker.check();
    if (!info.updateAvailable) return;
    if (!mounted) return;

    final accepted = await UpdateDialog.show(context, info);
    if (accepted && info.updateUrl.isNotEmpty) {
      final uri = Uri.tryParse(info.updateUrl);
      if (uri != null) {
        try {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } catch (_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Descarga en: ${info.updateUrl}')),
            );
          }
        }
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
          const KonectaFooter(showVersion: true),
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
