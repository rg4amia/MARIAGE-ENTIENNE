import 'package:flutter/material.dart';

/// Marque de l'application : deux anneaux entrelacés en trait fin.
///
/// Remplace l'icône cœur générique partout où l'app affiche son badge —
/// écran de garde, connexion, inscription, accès invité. Dessinée en
/// [CustomPainter] plutôt qu'importée en SVG : pas de dépendance
/// supplémentaire pour une marque à deux cercles.
class WeddingRingsIcon extends StatelessWidget {
  final double size;
  final Color color;
  final double strokeWidth;

  const WeddingRingsIcon({
    super.key,
    required this.color,
    this.size = 28,
    this.strokeWidth = 2.2,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _WeddingRingsPainter(color: color, strokeWidth: strokeWidth),
    );
  }
}

class _WeddingRingsPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  _WeddingRingsPainter({required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final radius = size.width * 0.30;
    final overlap = radius * 0.60;
    final centerY = size.height * 0.54;
    final leftCenter = Offset(size.width / 2 - overlap / 2, centerY);
    final rightCenter = Offset(size.width / 2 + overlap / 2, centerY);

    canvas.drawCircle(rightCenter, radius, paint);
    canvas.drawCircle(leftCenter, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _WeddingRingsPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}
