import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/webrtc/call_state.dart';
import '../../../core/webrtc/webrtc_service.dart';
import '../../../features/auth/repositories/auth_repository.dart';

class CallScreen extends ConsumerStatefulWidget {
  final String peerId;
  final String peerName;
  final bool isVideo;
  final bool isOutgoing;

  const CallScreen({
    super.key,
    required this.peerId,
    required this.peerName,
    required this.isVideo,
    required this.isOutgoing,
  });

  @override
  ConsumerState<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends ConsumerState<CallScreen>
    with TickerProviderStateMixin {
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulse;
  Timer? _durationTimer;
  Duration _elapsed = Duration.zero;
  bool _renderersReady = false;

  @override
  void initState() {
    super.initState();
    _initRenderers();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  Future<void> _initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
    if (!mounted) return;
    setState(() => _renderersReady = true);
    if (widget.isOutgoing) {
      final myUserId = ref.read(authProvider).profile?.userId ?? '';
      await ref.read(webRTCProvider.notifier).startCall(
            peerId: widget.peerId,
            peerName: widget.peerName,
            isVideo: widget.isVideo,
            myUserId: myUserId,
          );
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _durationTimer?.cancel();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  void _startTimer() {
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsed += const Duration(seconds: 1));
    });
  }

  String _formatElapsed() {
    final m = _elapsed.inMinutes.toString().padLeft(2, '0');
    final s = (_elapsed.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final webRTC = ref.watch(webRTCProvider);

    // Asignar streams a los renderers
    if (_renderersReady) {
      if (webRTC.localStream != null) {
        _localRenderer.srcObject = webRTC.localStream;
      }
      if (webRTC.remoteStream != null) {
        _remoteRenderer.srcObject = webRTC.remoteStream;
      }
    }

    // Iniciar timer cuando conectado
    if (webRTC.activeCall?.status == CallStatus.connected &&
        _durationTimer == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _startTimer());
    }

    // Cerrar pantalla si la llamada termino
    if (webRTC.activeCall?.status == CallStatus.ended ||
        webRTC.activeCall?.status == CallStatus.rejected ||
        webRTC.activeCall?.status == CallStatus.failed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop();
      });
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Video remoto (fondo completo)
          if (widget.isVideo && webRTC.remoteStream != null && _renderersReady)
            Positioned.fill(
              child: RTCVideoView(
                _remoteRenderer,
                objectFit:
                    RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
              ),
            )
          else
            _AudioBackground(
              peerName: widget.peerName,
              pulse: _pulse,
              status: webRTC.activeCall?.status ?? CallStatus.calling,
            ),

          // Video local (esquina)
          if (widget.isVideo && webRTC.localStream != null && _renderersReady)
            Positioned(
              right: 16,
              top: 60,
              width: 100,
              height: 140,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: RTCVideoView(
                  _localRenderer,
                  mirror: true,
                  objectFit:
                      RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                ),
              ),
            ),

          // Info superior
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  Text(
                    widget.peerName,
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _statusText(webRTC.activeCall?.status),
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  if (webRTC.activeCall?.status == CallStatus.connected) ...[
                    const SizedBox(height: 4),
                    Text(
                      _formatElapsed(),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: KonectaColors.accent,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Controles inferiores
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _CallControls(
              isVideo: widget.isVideo,
              isMuted: webRTC.isMuted,
              isSpeakerOn: webRTC.isSpeakerOn,
              isCameraOff: webRTC.isCameraOff,
              onMute: () =>
                  ref.read(webRTCProvider.notifier).toggleMute(),
              onSpeaker: () =>
                  ref.read(webRTCProvider.notifier).toggleSpeaker(),
              onCamera: () =>
                  ref.read(webRTCProvider.notifier).toggleCamera(),
              onFlip: () =>
                  ref.read(webRTCProvider.notifier).switchCamera(),
              onHangup: () {
                final myId =
                    ref.read(authProvider).profile?.userId ?? '';
                ref.read(webRTCProvider.notifier).endCall(myId: myId);
                Navigator.of(context).pop();
              },
            ),
          ),
        ],
      ),
    );
  }

  String _statusText(CallStatus? status) {
    switch (status) {
      case CallStatus.calling:
        return widget.isOutgoing ? 'Llamando…' : 'Llamada entrante';
      case CallStatus.connecting:
        return 'Conectando…';
      case CallStatus.connected:
        return widget.isVideo ? '📹 Videollamada' : '🔒 Cifrada E2E';
      case CallStatus.ended:
        return 'Llamada terminada';
      case CallStatus.rejected:
        return 'Llamada rechazada';
      default:
        return '';
    }
  }
}

class _AudioBackground extends StatelessWidget {
  final String peerName;
  final Animation<double> pulse;
  final CallStatus status;

  const _AudioBackground({
    required this.peerName,
    required this.pulse,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A0533), Color(0xFF0D1B2A)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: status == CallStatus.calling ? pulse : AlwaysStoppedAnimation(1.0),
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      KonectaColors.primary,
                      KonectaColors.primary.withValues(alpha: 0.6),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: KonectaColors.primary.withValues(alpha: 0.4),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    peerName.isNotEmpty ? peerName[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CallControls extends StatelessWidget {
  final bool isVideo;
  final bool isMuted;
  final bool isSpeakerOn;
  final bool isCameraOff;
  final VoidCallback onMute;
  final VoidCallback onSpeaker;
  final VoidCallback onCamera;
  final VoidCallback onFlip;
  final VoidCallback onHangup;

  const _CallControls({
    required this.isVideo,
    required this.isMuted,
    required this.isSpeakerOn,
    required this.isCameraOff,
    required this.onMute,
    required this.onSpeaker,
    required this.onCamera,
    required this.onFlip,
    required this.onHangup,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: Column(
        children: [
          // Controles secundarios
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ControlButton(
                icon: isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                label: isMuted ? 'Activar mic' : 'Silenciar',
                active: isMuted,
                onTap: onMute,
              ),
              if (isVideo) ...[
                _ControlButton(
                  icon: isCameraOff
                      ? Icons.videocam_off_rounded
                      : Icons.videocam_rounded,
                  label: isCameraOff ? 'Cámara' : 'Apagar cam',
                  active: isCameraOff,
                  onTap: onCamera,
                ),
                _ControlButton(
                  icon: Icons.flip_camera_ios_rounded,
                  label: 'Cambiar',
                  onTap: onFlip,
                ),
              ] else ...[
                _ControlButton(
                  icon: isSpeakerOn
                      ? Icons.volume_up_rounded
                      : Icons.volume_down_rounded,
                  label: 'Altavoz',
                  active: isSpeakerOn,
                  onTap: onSpeaker,
                ),
              ],
              _ControlButton(
                icon: Icons.chat_bubble_outline_rounded,
                label: 'Chat',
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Botón colgar
          GestureDetector(
            onTap: onHangup,
            child: Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.red,
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(Icons.call_end_rounded,
                  color: Colors.white, size: 32),
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  const _ControlButton({
    required this.icon,
    required this.label,
    this.active = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: active
                  ? KonectaColors.primary
                  : Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
