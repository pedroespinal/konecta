import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/daos/calls_dao.dart';
import '../../../core/database/daos/contacts_dao.dart';
import '../../../core/database/models/call_record_model.dart';
import '../../../core/database/models/chat_model.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/webrtc/webrtc_service.dart';
import '../../../features/auth/repositories/auth_repository.dart';
import '../../../features/calls/screens/call_screen.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

final _callsRefreshProvider = StateProvider<int>((ref) => 0);

final callsListProvider =
    FutureProvider.autoDispose.family<List<CallRecord>, int>(
  (ref, _) => CallsDao().getAll(),
);

final _contactsProvider =
    FutureProvider.autoDispose<List<ContactModel>>((ref) => ContactsDao().getAll());

// ── Widget ────────────────────────────────────────────────────────────────────

class CallsTab extends ConsumerStatefulWidget {
  const CallsTab({super.key});

  @override
  ConsumerState<CallsTab> createState() => _CallsTabState();
}

class _CallsTabState extends ConsumerState<CallsTab> {
  final _dao = CallsDao();
  final _uuid = const Uuid();

  void _refresh() =>
      ref.read(_callsRefreshProvider.notifier).update((n) => n + 1);

  Future<void> _startCall(
    String peerId,
    String peerName, {
    required bool isVideo,
  }) async {
    final myUserId = ref.read(authProvider).profile?.userId ?? '';
    final recordId = _uuid.v4();
    final record = CallRecord(
      id: recordId,
      peerId: peerId,
      peerName: peerName,
      isVideo: isVideo,
      direction: CallDirection.outgoing,
      outcome: CallOutcome.missed, // se actualiza al colgar
      startedAt: DateTime.now().toUtc(),
    );
    await _dao.insert(record);

    await ref.read(webRTCProvider.notifier).startCall(
          peerId: peerId,
          peerName: peerName,
          isVideo: isVideo,
          myUserId: myUserId,
        );

    if (!mounted) return;
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => CallScreen(
          peerId: peerId,
          peerName: peerName,
          isVideo: isVideo,
          isOutgoing: true,
        ),
      ),
    );

    // Actualizar outcome según resultado
    if (result != null) {
      final status = result['status'] as String? ?? 'ended';
      final duration = result['durationSeconds'] as int? ?? 0;
      final outcome = _outcomeFromStatus(status, duration);
      await _dao.updateOutcome(recordId, outcome, duration);
    }
    _refresh();
  }

  CallOutcome _outcomeFromStatus(String status, int durationSeconds) {
    if (status == 'rejected') return CallOutcome.rejected;
    if (status == 'failed') return CallOutcome.failed;
    return durationSeconds > 0 ? CallOutcome.connected : CallOutcome.missed;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final refresh = ref.watch(_callsRefreshProvider);
    final callsAsync = ref.watch(callsListProvider(refresh));

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          snap: true,
          title: Text(l10n.navCalls),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_call),
              tooltip: 'Nueva llamada',
              onPressed: () => _showNewCallDialog(context),
            ),
          ],
        ),
        callsAsync.when(
          loading: () => const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, st) => const SliverFillRemaining(
            child: Center(child: Text('Error cargando llamadas')),
          ),
          data: (calls) {
            if (calls.isEmpty) {
              return SliverFillRemaining(
                child: _EmptyCallsState(
                  onNewCall: () => _showNewCallDialog(context),
                ),
              );
            }
            return SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => _CallItem(
                  record: calls[i],
                  onCall: (peerId, name, isVideo) =>
                      _startCall(peerId, name, isVideo: isVideo),
                  onDelete: () async {
                    await _dao.delete(calls[i].id);
                    _refresh();
                  },
                ),
                childCount: calls.length,
              ),
            );
          },
        ),
      ],
    );
  }

  void _showNewCallDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _NewCallSheet(onCall: _startCall),
    );
  }
}

// ── Nueva llamada — muestra contactos de la BD ─────────────────────────────

class _NewCallSheet extends ConsumerWidget {
  final Future<void> Function(String peerId, String name,
      {required bool isVideo}) onCall;

  const _NewCallSheet({required this.onCall});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactsAsync = ref.watch(_contactsProvider);

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
            Text(
              'Nueva llamada',
              style: GoogleFonts.inter(
                  fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            contactsAsync.when(
              loading: () =>
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
              error: (e, st) =>
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Error cargando contactos'),
                  ),
              data: (contacts) {
                if (contacts.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'No hay contactos. Añade uno desde la pestaña de Contactos.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: contacts.take(8).map((c) => ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          KonectaColors.primary.withValues(alpha: 0.12),
                      child: Text(
                        c.displayName.isNotEmpty ? c.displayName[0] : '?',
                        style: const TextStyle(
                          color: KonectaColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    title: Text(c.displayName),
                    subtitle: c.username != null
                        ? Text('@${c.username}',
                            style: GoogleFonts.inter(fontSize: 12))
                        : null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.call_rounded,
                              color: KonectaColors.accent),
                          onPressed: () {
                            Navigator.pop(context);
                            onCall(c.id, c.displayName, isVideo: false);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.video_call_rounded,
                              color: KonectaColors.secondary),
                          onPressed: () {
                            Navigator.pop(context);
                            onCall(c.id, c.displayName, isVideo: true);
                          },
                        ),
                      ],
                    ),
                  )).toList(),
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ── Item de llamada ────────────────────────────────────────────────────────────

class _CallItem extends StatelessWidget {
  final CallRecord record;
  final void Function(String peerId, String name, bool isVideo) onCall;
  final VoidCallback onDelete;

  const _CallItem({
    required this.record,
    required this.onCall,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMissed = record.outcome == CallOutcome.missed;
    final isRejected = record.outcome == CallOutcome.rejected;
    final isFailed = record.outcome == CallOutcome.failed;
    final isIncoming = record.direction == CallDirection.incoming;

    Color statusColor;
    IconData statusIcon;
    if (isMissed || isFailed) {
      statusColor = KonectaColors.error;
      statusIcon = isIncoming
          ? Icons.call_missed_rounded
          : Icons.call_missed_outgoing_rounded;
    } else if (isRejected) {
      statusColor = Colors.orange;
      statusIcon = Icons.call_missed_outgoing_rounded;
    } else {
      statusColor = KonectaColors.success;
      statusIcon =
          isIncoming ? Icons.call_received_rounded : Icons.call_made_rounded;
    }

    final timeLabel = _formatTime(record.startedAt);
    final durationLabel = record.durationSeconds > 0
        ? _formatDuration(record.durationSeconds)
        : null;

    return Dismissible(
      key: ValueKey(record.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: KonectaColors.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: ListTile(
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: KonectaColors.primary.withValues(alpha: 0.12),
          child: Text(
            record.peerName.isNotEmpty ? record.peerName[0].toUpperCase() : '?',
            style: const TextStyle(
                color: KonectaColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 18),
          ),
        ),
        title: Text(
          record.peerName,
          style: GoogleFonts.inter(
            fontWeight: isMissed ? FontWeight.w700 : FontWeight.w500,
            color: isMissed ? KonectaColors.error : null,
          ),
        ),
        subtitle: Row(
          children: [
            Icon(statusIcon, size: 13, color: statusColor),
            const SizedBox(width: 4),
            Icon(
              record.isVideo ? Icons.videocam_rounded : Icons.call_rounded,
              size: 13,
              color: isDark
                  ? KonectaColors.darkTextSecondary
                  : KonectaColors.lightTextSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              timeLabel,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: isDark
                    ? KonectaColors.darkTextSecondary
                    : KonectaColors.lightTextSecondary,
              ),
            ),
            if (durationLabel != null) ...[
              const SizedBox(width: 6),
              Text(
                '• $durationLabel',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: isDark
                      ? KonectaColors.darkTextTertiary
                      : KonectaColors.lightTextTertiary,
                ),
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.call_rounded, size: 22),
              color: KonectaColors.primary,
              onPressed: () =>
                  onCall(record.peerId, record.peerName, false),
            ),
            if (record.isVideo)
              IconButton(
                icon: const Icon(Icons.video_call_rounded, size: 22),
                color: KonectaColors.secondary,
                onPressed: () =>
                    onCall(record.peerId, record.peerName, true),
              ),
          ],
        ),
        onTap: () => onCall(record.peerId, record.peerName, record.isVideo),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final d = DateTime(dt.toLocal().year, dt.toLocal().month, dt.toLocal().day);
    final h = dt.toLocal().hour.toString().padLeft(2, '0');
    final m = dt.toLocal().minute.toString().padLeft(2, '0');
    if (d == today) return 'Hoy, $h:$m';
    if (d == yesterday) return 'Ayer, $h:$m';
    return '${dt.toLocal().day}/${dt.toLocal().month}, $h:$m';
  }

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

// ── Estado vacío ───────────────────────────────────────────────────────────────

class _EmptyCallsState extends StatelessWidget {
  final VoidCallback onNewCall;
  const _EmptyCallsState({required this.onNewCall});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.call_outlined,
              size: 64,
              color: isDark
                  ? KonectaColors.darkTextSecondary
                  : KonectaColors.lightTextSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'Sin llamadas',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tu historial de llamadas aparecerá aquí.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: isDark
                    ? KonectaColors.darkTextSecondary
                    : KonectaColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onNewCall,
              icon: const Icon(Icons.add_call),
              label: const Text('Nueva llamada'),
            ),
          ],
        ),
      ),
    );
  }
}
