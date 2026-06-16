import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/webrtc/call_state.dart';
import '../../../core/webrtc/webrtc_service.dart';
import '../../../features/calls/screens/call_screen.dart';

class CallsTab extends ConsumerWidget {
  const CallsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
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
              onPressed: () => _showNewCallDialog(context, ref),
            ),
          ],
        ),
        // Demo call history — en Fase 5 se leerá desde la DB
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _CallItem(
              index: index,
              onCall: (name, isVideo) => _startCall(
                  context, ref, peerId: 'user_$index', peerName: name, isVideo: isVideo),
            ),
            childCount: _demoRecords.length,
          ),
        ),
      ],
    );
  }

  static final _demoRecords = [
    _Demo('Maria Garcia',    '5 min 23s', CallStatus.connected, false, 'Hoy, 10:42'),
    _Demo('Carlos Lopez',    '',          CallStatus.missed,    false, 'Hoy, 09:15'),
    _Demo('Juan Perez',      '2 min 08s', CallStatus.connected, true,  'Ayer, 20:30'),
    _Demo('Sofia Chen',      '18 min',    CallStatus.connected, false, 'Ayer, 18:00'),
    _Demo('Diego Morales',   '',          CallStatus.missed,    true,  'Lun, 15:45'),
    _Demo('Laura Martinez',  '1 min 45s', CallStatus.ended,     false, 'Dom, 12:00'),
    _Demo('Roberto Silva',   '8 min 12s', CallStatus.connected, true,  'Sab, 09:30'),
    _Demo('Ana Jimenez',     '',          CallStatus.rejected,  false, 'Vie, 22:00'),
    _Demo('Fernando Vega',   '30 min',    CallStatus.connected, false, 'Jue, 11:15'),
    _Demo('Valentina Ruiz',  '4 min 55s', CallStatus.connected, true,  'Mié, 08:45'),
  ];

  void _startCall(BuildContext context, WidgetRef ref, {
    required String peerId,
    required String peerName,
    required bool isVideo,
  }) async {
    final service = ref.read(webRTCProvider.notifier);
    await service.startCall(
      peerId: peerId,
      peerName: peerName,
      isVideo: isVideo,
      myUserId: 'me',
    );
    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CallScreen(
          peerId: peerId,
          peerName: peerName,
          isVideo: isVideo,
          isOutgoing: true,
        ),
      ),
    );
  }

  void _showNewCallDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(ctx).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Text('Nueva llamada',
                  style: GoogleFonts.inter(
                      fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              ..._demoRecords.take(5).map((d) => ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          KonectaColors.primary.withValues(alpha: 0.12),
                      child: Text(d.name[0],
                          style: const TextStyle(
                              color: KonectaColors.primary,
                              fontWeight: FontWeight.w700)),
                    ),
                    title: Text(d.name),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.call_rounded,
                              color: KonectaColors.accent),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _startCall(context, ref,
                                peerId: 'demo_${d.name}',
                                peerName: d.name,
                                isVideo: false);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.video_call_rounded,
                              color: KonectaColors.secondary),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _startCall(context, ref,
                                peerId: 'demo_${d.name}',
                                peerName: d.name,
                                isVideo: true);
                          },
                        ),
                      ],
                    ),
                  )),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _Demo {
  final String name;
  final String duration;
  final CallStatus status;
  final bool isVideo;
  final String time;
  const _Demo(this.name, this.duration, this.status, this.isVideo, this.time);
}

class _CallItem extends StatelessWidget {
  final int index;
  final Function(String name, bool isVideo) onCall;
  const _CallItem({required this.index, required this.onCall});

  static final _records = CallsTab._demoRecords;

  @override
  Widget build(BuildContext context) {
    final d = _records[index];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMissed = d.status == CallStatus.missed;
    final isRejected = d.status == CallStatus.rejected;

    Color statusColor;
    IconData statusIcon;
    if (isMissed) {
      statusColor = KonectaColors.error;
      statusIcon = Icons.call_missed_rounded;
    } else if (isRejected) {
      statusColor = Colors.orange;
      statusIcon = Icons.call_missed_outgoing_rounded;
    } else {
      statusColor = KonectaColors.success;
      statusIcon = Icons.call_made_rounded;
    }

    return ListTile(
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: KonectaColors.primary.withValues(alpha: 0.12),
        child: Text(
          d.name[0],
          style: const TextStyle(
              color: KonectaColors.primary, fontWeight: FontWeight.w700, fontSize: 18),
        ),
      ),
      title: Text(
        d.name,
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
            d.isVideo ? Icons.videocam_rounded : Icons.call_rounded,
            size: 13,
            color: isDark
                ? KonectaColors.darkTextSecondary
                : KonectaColors.lightTextSecondary,
          ),
          const SizedBox(width: 4),
          Text(
            d.time,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: isDark
                  ? KonectaColors.darkTextSecondary
                  : KonectaColors.lightTextSecondary,
            ),
          ),
          if (d.duration.isNotEmpty) ...[
            const SizedBox(width: 6),
            Text(
              '• ${d.duration}',
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
            onPressed: () => onCall(d.name, false),
          ),
          if (d.isVideo)
            IconButton(
              icon: const Icon(Icons.video_call_rounded, size: 22),
              color: KonectaColors.secondary,
              onPressed: () => onCall(d.name, true),
            ),
        ],
      ),
      onTap: () => onCall(d.name, d.isVideo),
    );
  }
}
