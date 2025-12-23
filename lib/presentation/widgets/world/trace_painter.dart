import 'dart:ui';
import 'package:flutter/material.dart';

class TracePainter extends CustomPainter {
  TracePainter({
    required this.strokesNorm,
    required this.toBoardPx,
    this.opacity = 0.35,
    this.strokeWidth = 6,
  });

  final List<List<Offset>> strokesNorm;      // 0..1
  final Offset Function(Offset n) toBoardPx; // your mapping
  final double opacity;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (strokesNorm.isEmpty) return;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = Colors.blue.withOpacity(opacity);

    for (final stroke in strokesNorm) {
      if (stroke.length < 2) continue;

      final path = Path();
      final first = toBoardPx(stroke.first);
      path.moveTo(first.dx, first.dy);

      for (int i = 1; i < stroke.length; i++) {
        final pt = toBoardPx(stroke[i]);
        path.lineTo(pt.dx, pt.dy);
      }

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant TracePainter old) {
    return old.strokesNorm != strokesNorm ||
        old.opacity != opacity ||
        old.strokeWidth != strokeWidth;
  }
}
