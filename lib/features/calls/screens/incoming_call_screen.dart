import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/network/message_payload.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/webrtc/webrtc_service.dart';
import 'call_screen.dart';

class IncomingCallScreen extends ConsumerWidget {
  final CallSignalPayload invite;
  final String peerName;

  const IncomingCallScreen({
    super.key,
    required this.invite,
    required this.peerName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A0533), Color(0xFF0D1B2A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(),
              // Avatar / icono
              Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [KonectaColors.primary, KonectaColors.secondary],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: KonectaColors.primary.withValues(alpha: 0.5),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    peerName.isNotEmpty ? peerName[0].toUpperCase() : '?',
                    style: const TextStyle(
                        fontSize: 52,
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                peerName,
                style: GoogleFonts.inter(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                invite.isVideo
                    ? '📹 Videollamada entrante'
                    : '📞 Llamada de voz entrante',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: Colors.white60,
                ),
              ),
              const Spacer(),
              // Botones rechazar / aceptar
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Rechazar
                    _RoundButton(
                      icon: Icons.call_end_rounded,
                      color: Colors.red,
                      label: 'Rechazar',
                      onTap: () {
                        ref.read(webRTCProvider.notifier).rejectCall(
                              invite: invite,
                              myId: 'me',
                            );
                        Navigator.of(context).pop();
                      },
                    ),

                    // Solo audio (si es videollamada)
                    if (invite.isVideo)
                      _RoundButton(
                        icon: Icons.mic_rounded,
                        color: Colors.blueGrey,
                        label: 'Solo voz',
                        onTap: () {
                          _acceptAndOpen(
                              context, ref, isVideo: false);
                        },
                      ),

                    // Aceptar
                    _RoundButton(
                      icon: invite.isVideo
                          ? Icons.videocam_rounded
                          : Icons.call_rounded,
                      color: Colors.green,
                      label: 'Aceptar',
                      onTap: () =>
                          _acceptAndOpen(context, ref, isVideo: invite.isVideo),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _acceptAndOpen(
      BuildContext context, WidgetRef ref, {required bool isVideo}) async {
    await ref.read(webRTCProvider.notifier).acceptCall(
          invite: invite,
          myUserId: 'me',
        );
    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => CallScreen(
          peerId: invite.from,
          peerName: peerName,
          isVideo: isVideo,
          isOutgoing: false,
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _RoundButton({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.5),
                  blurRadius: 20,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}
