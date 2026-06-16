import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class KonectaLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final Color? color;

  const KonectaLogo({
    super.key,
    this.size = 48,
    this.showText = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _LogoIcon(size: size, color: color),
        if (showText) ...[
          const SizedBox(height: 8),
          Text(
            'Konecta',
            style: TextStyle(
              fontSize: size * 0.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              color: color ?? KonectaColors.primary,
            ),
          ),
        ],
      ],
    );
  }
}

class _LogoIcon extends StatelessWidget {
  final double size;
  final Color? color;
  const _LogoIcon({required this.size, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? KonectaColors.primary;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _KonectaLogoPainter(color: c)),
    );
  }
}

// Logo vectorial de Konecta: una K estilizada con un rayo de conexion
class _KonectaLogoPainter extends CustomPainter {
  final Color color;
  const _KonectaLogoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Fondo redondeado
    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(w * 0.22)),
      bgPaint,
    );

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.09
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Palo vertical de la K
    final path = Path();
    path.moveTo(w * 0.28, h * 0.22);
    path.lineTo(w * 0.28, h * 0.78);

    // Brazo superior de K
    path.moveTo(w * 0.28, h * 0.5);
    path.lineTo(w * 0.72, h * 0.22);

    // Brazo inferior de K
    path.moveTo(w * 0.28, h * 0.5);
    path.lineTo(w * 0.72, h * 0.78);

    canvas.drawPath(path, paint);

    // Punto de conexion (circulo en el centro)
    final dotPaint = Paint()
      ..color = KonectaColors.secondary
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.28, h * 0.5), w * 0.07, dotPaint);
  }

  @override
  bool shouldRepaint(_KonectaLogoPainter old) => old.color != color;
}
