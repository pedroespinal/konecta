import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart' as p;
import 'package:record/record.dart';
import 'package:sqflite/sqflite.dart' show getDatabasesPath;
import '../../core/database/models/message_model.dart';
import '../../core/theme/app_colors.dart';
import 'media_service.dart';

class VoiceRecorderButton extends StatefulWidget {
  final ValueChanged<MediaFile> onRecorded;

  const VoiceRecorderButton({super.key, required this.onRecorded});

  @override
  State<VoiceRecorderButton> createState() => _VoiceRecorderButtonState();
}

class _VoiceRecorderButtonState extends State<VoiceRecorderButton>
    with SingleTickerProviderStateMixin {
  late final AudioRecorder _recorder;
  late final AnimationController _pulse;
  Timer? _durationTimer;
  Duration _elapsed = Duration.zero;
  bool _isRecording = false;
  bool _isCancelling = false;

  @override
  void initState() {
    super.initState();
    _recorder = AudioRecorder();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    _durationTimer?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    final hasPerm = await MediaService.requestMicPermission();
    if (!hasPerm) return;

    final base = await getDatabasesPath();
    final dir = Directory(p.join(base, 'media', 'audio'));
    if (!dir.existsSync()) dir.createSync(recursive: true);
    final path = p.join(
        dir.path, 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a');

    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 64000),
      path: path,
    );

    HapticFeedback.mediumImpact();
    setState(() {
      _isRecording = true;
      _elapsed = Duration.zero;
    });
    _durationTimer =
        Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsed += const Duration(seconds: 1));
    });
  }

  Future<void> _stopRecording({bool cancel = false}) async {
    _durationTimer?.cancel();
    final path = await _recorder.stop();
    setState(() {
      _isRecording = false;
      _isCancelling = false;
    });

    if (cancel || path == null) {
      if (path != null) File(path).deleteSync();
      return;
    }

    HapticFeedback.lightImpact();
    final file = File(path);
    widget.onRecorded(MediaFile(
      localPath: path,
      type: MessageType.audio,
      mimeType: 'audio/aac',
      fileSizeBytes: await file.length(),
      durationSeconds: _elapsed.inSeconds,
    ));
  }

  String _formatDuration() {
    final m = _elapsed.inMinutes.toString().padLeft(2, '0');
    final s = (_elapsed.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    if (_isRecording) {
      return _RecordingBar(
        elapsed: _formatDuration(),
        isCancelling: _isCancelling,
        pulse: _pulse,
        onStop: () => _stopRecording(),
        onCancel: () => _stopRecording(cancel: true),
        onDrag: (offset) {
          setState(() {
            _isCancelling = offset.dx < -60;
          });
        },
      );
    }

    return GestureDetector(
      onLongPressStart: (_) => _startRecording(),
      onLongPressEnd: (d) {
        if (_isCancelling) {
          _stopRecording(cancel: true);
        } else {
          _stopRecording();
        }
      },
      onLongPressMoveUpdate: (d) {
        setState(() {
          _isCancelling = d.offsetFromOrigin.dx < -60;
        });
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [KonectaColors.primary, KonectaColors.secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.mic_rounded, color: Colors.white, size: 22),
      ),
    );
  }
}

class _RecordingBar extends StatelessWidget {
  final String elapsed;
  final bool isCancelling;
  final AnimationController pulse;
  final VoidCallback onStop;
  final VoidCallback onCancel;
  final ValueChanged<Offset> onDrag;

  const _RecordingBar({
    required this.elapsed,
    required this.isCancelling,
    required this.pulse,
    required this.onStop,
    required this.onCancel,
    required this.onDrag,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Boton cancelar
          GestureDetector(
            onTap: onCancel,
            child: const Icon(Icons.delete_rounded,
                color: KonectaColors.error, size: 26),
          ),
          const SizedBox(width: 12),

          // Indicador de grabacion
          AnimatedBuilder(
            animation: pulse,
            builder: (context, child) => Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: KonectaColors.error
                    .withValues(alpha: 0.5 + pulse.value * 0.5),
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 8),

          Text(
            elapsed,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isCancelling ? KonectaColors.error : null,
            ),
          ),

          const Spacer(),

          if (isCancelling)
            Text(
              '← Suelta para cancelar',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: KonectaColors.error,
              ),
            )
          else
            Text(
              '← Desliza para cancelar',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: isDark
                    ? KonectaColors.darkTextSecondary
                    : KonectaColors.lightTextSecondary,
              ),
            ),

          const SizedBox(width: 12),

          // Boton enviar
          GestureDetector(
            onTap: onStop,
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [KonectaColors.primary, KonectaColors.secondary],
                ),
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
