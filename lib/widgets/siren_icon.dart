import 'package:flutter/material.dart';

/// Reusable Siren Icon matching the Lucide Siren icon
/// (dome, base bar, center filament, and 5 radiating light rays).
class SirenIcon extends StatelessWidget {
  final double size;
  final Color? color;
  final double? strokeWidth;

  const SirenIcon({
    super.key,
    this.size = 24,
    this.color,
    this.strokeWidth,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = color ?? IconTheme.of(context).color ?? Colors.white;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        size: Size(size, size),
        painter: _LucideSirenPainter(
          color: iconColor,
          customStrokeWidth: strokeWidth,
        ),
      ),
    );
  }
}

class _LucideSirenPainter extends CustomPainter {
  final Color color;
  final double? customStrokeWidth;

  const _LucideSirenPainter({
    required this.color,
    this.customStrokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final sw = customStrokeWidth ?? (size.width * (2.0 / 24.0)).clamp(1.5, 4.0);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final sx = size.width / 24.0;
    final sy = size.height / 24.0;

    Offset pt(double x, double y) => Offset(x * sx, y * sy);

    // 1. Dome path: M7 18 v-6 a5 5 0 1 1 10 0 v6
    final domePath = Path();
    domePath.moveTo(7 * sx, 18 * sy);
    domePath.lineTo(7 * sx, 12 * sy);
    domePath.arcToPoint(
      pt(17, 12),
      radius: Radius.circular(5 * sx),
      clockwise: true,
    );
    domePath.lineTo(17 * sx, 18 * sy);
    canvas.drawPath(domePath, paint);

    // 2. Base horizontal outline
    final basePath = Path();
    basePath.moveTo(5 * sx, 20 * sy);
    basePath.arcToPoint(pt(7, 18), radius: Radius.circular(2 * sx), clockwise: true);
    basePath.lineTo(17 * sx, 18 * sy);
    basePath.arcToPoint(pt(19, 20), radius: Radius.circular(2 * sx), clockwise: true);
    basePath.lineTo(19 * sx, 21 * sy);
    basePath.arcToPoint(pt(18, 22), radius: Radius.circular(1 * sx), clockwise: true);
    basePath.lineTo(6 * sx, 22 * sy);
    basePath.arcToPoint(pt(5, 21), radius: Radius.circular(1 * sx), clockwise: true);
    basePath.close();
    canvas.drawPath(basePath, paint);

    // 3. Center filament: M12 12 v6
    canvas.drawLine(pt(12, 12), pt(12, 18), paint);

    // 4. 5 Rays around dome:
    // Top ray
    canvas.drawLine(pt(12, 1.5), pt(12, 3.8), paint);

    // Top-left diagonal ray
    canvas.drawLine(pt(4.5, 4.5), pt(6.2, 6.2), paint);

    // Top-right diagonal ray
    canvas.drawLine(pt(19.5, 4.5), pt(17.8, 6.2), paint);

    // Left ray
    canvas.drawLine(pt(1.5, 12), pt(3.8, 12), paint);

    // Right ray
    canvas.drawLine(pt(20.2, 12), pt(22.5, 12), paint);
  }

  @override
  bool shouldRepaint(covariant _LucideSirenPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.customStrokeWidth != customStrokeWidth;
}
