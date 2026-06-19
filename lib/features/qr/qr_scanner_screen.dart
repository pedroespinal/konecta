import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/database/daos/contacts_dao.dart';
import '../../core/database/models/chat_model.dart';
import '../../core/theme/app_colors.dart';
import '../../features/chat/providers/chat_provider.dart';
import '../../features/chat/repositories/chat_repository.dart';
import '../../features/chat/screens/chat_screen.dart';

class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({super.key});

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> {
  late final MobileScannerController _controller;
  bool _detected = false;
  bool _torchOn = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_detected) return;
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue;
      if (value != null && value.startsWith('konecta://add/')) {
        _detected = true;
        _controller.stop();
        _handleKonectaUrl(value);
        return;
      }
    }
  }

  void _handleKonectaUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return;

    // konecta://add/{userId}?name={displayName}
    final userId = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '';
    final name =
        uri.queryParameters['name'] ?? userId;

    if (userId.isEmpty) {
      setState(() => _detected = false);
      _controller.start();
      return;
    }

    _showContactFound(userId, name);
  }

  Future<void> _saveAndChat(String userId, String displayName) async {
    final contact = ContactModel(
      id: userId,
      displayName: displayName,
      identityPublicKeyHex: '',
      addedAt: DateTime.now(),
    );
    await ContactsDao().upsert(contact);
    ref.invalidate(contactsProvider);

    // Crear o abrir chat individual
    final chat = await ref.read(chatRepositoryProvider).createIndividualChat(contact);
    ref.invalidate(chatsProvider);

    if (!mounted) return;
    Navigator.of(context).pop(); // cierra scanner
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ChatScreen(chat: chat)),
    );
  }

  void _showContactFound(String userId, String displayName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Contacto encontrado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: KonectaColors.primary.withValues(alpha: 0.12),
              child: Text(
                displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: KonectaColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 24,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              displayName,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              userId,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: KonectaColors.primary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: KonectaColors.primary),
            onPressed: () {
              Navigator.pop(context);
              _saveAndChat(userId, displayName);
            },
            child: const Text('Agregar y chatear'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          'Escanear QR',
          style: GoogleFonts.inter(
              color: Colors.white, fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _torchOn
                  ? Icons.flashlight_off_rounded
                  : Icons.flashlight_on_rounded,
              color: _torchOn ? KonectaColors.accent : Colors.white,
            ),
            tooltip: 'Linterna',
            onPressed: () {
              _controller.toggleTorch();
              setState(() => _torchOn = !_torchOn);
            },
          ),
        ],
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withValues(alpha: 0.55),
              BlendMode.srcOut,
            ),
            child: Stack(
              children: [
                Container(
                  color: Colors.transparent,
                  child: const SizedBox.expand(),
                ),
                Center(
                  child: Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Center(
            child: SizedBox(
              width: 260,
              height: 260,
              child: CustomPaint(painter: _ScannerFramePainter()),
            ),
          ),
          Positioned(
            bottom: 80,
            left: 32,
            right: 32,
            child: Column(
              children: [
                Text(
                  'Apunta al código QR de Konecta',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    shadows: const [
                      Shadow(color: Colors.black54, blurRadius: 8)
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Escanea el QR de un contacto para agregarlo',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 13,
                    shadows: const [
                      Shadow(color: Colors.black54, blurRadius: 8)
                    ],
                  ),
                ),
              ],
            ),
          ),
          Center(
            child: _ScanLine(isDark: isDark),
          ),
        ],
      ),
    );
  }
}

class _ScannerFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = KonectaColors.primary
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const len = 30.0;
    const r = 16.0;

    canvas.drawLine(Offset(0, r + len), Offset(0, r), paint);
    canvas.drawArc(
        const Rect.fromLTWH(0, 0, r * 2, r * 2), 3.14159, 1.5708, false, paint);
    canvas.drawLine(Offset(r, 0), Offset(r + len, 0), paint);

    canvas.drawLine(
        Offset(size.width - r - len, 0), Offset(size.width - r, 0), paint);
    canvas.drawArc(Rect.fromLTWH(size.width - r * 2, 0, r * 2, r * 2),
        -1.5708, 1.5708, false, paint);
    canvas.drawLine(
        Offset(size.width, r), Offset(size.width, r + len), paint);

    canvas.drawLine(Offset(0, size.height - r - len),
        Offset(0, size.height - r), paint);
    canvas.drawArc(
        Rect.fromLTWH(0, size.height - r * 2, r * 2, r * 2),
        1.5708,
        1.5708,
        false,
        paint);
    canvas.drawLine(
        Offset(r, size.height), Offset(r + len, size.height), paint);

    canvas.drawLine(Offset(size.width - r - len, size.height),
        Offset(size.width - r, size.height), paint);
    canvas.drawArc(
        Rect.fromLTWH(
            size.width - r * 2, size.height - r * 2, r * 2, r * 2),
        0,
        1.5708,
        false,
        paint);
    canvas.drawLine(Offset(size.width, size.height - r - len),
        Offset(size.width, size.height - r), paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

class _ScanLine extends StatefulWidget {
  final bool isDark;
  const _ScanLine({required this.isDark});

  @override
  State<_ScanLine> createState() => _ScanLineState();
}

class _ScanLineState extends State<_ScanLine>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _pos;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pos = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _anim, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      height: 260,
      child: AnimatedBuilder(
        animation: _pos,
        builder: (context, child) => Stack(
          children: [
            Positioned(
              top: _pos.value * 250,
              left: 0,
              right: 0,
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      KonectaColors.primary.withValues(alpha: 0.8),
                      Colors.transparent,
                    ],
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
