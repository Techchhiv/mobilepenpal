import 'package:flutter/material.dart';

class LetterPointsPainter extends CustomPainter {
  LetterPointsPainter({
    required this.letterSubpathsNorm,
    required this.toBoardPx,
    this.fillOpacity = 0.12,
    this.strokeOpacity = 0.18,
    this.strokeWidth = 10,
    this.fillEnabled = true,
    this.strokeEnabled = true,
  });

  final List<List<Offset>> letterSubpathsNorm;
  final Offset Function(Offset n) toBoardPx;

  final double fillOpacity;
  final double strokeOpacity;
  final double strokeWidth;
  final bool fillEnabled;
  final bool strokeEnabled;

  @override
  void paint(Canvas canvas, Size size) {
    if (letterSubpathsNorm.isEmpty) return;

    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.grey.withOpacity(fillOpacity)
      ..isAntiAlias = true;

    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = Colors.grey.withOpacity(strokeOpacity)
      ..isAntiAlias = true;

    for (final sub in letterSubpathsNorm) {
      if (sub.length < 2) continue;

      final path = Path();
      final first = toBoardPx(sub.first);
      path.moveTo(first.dx, first.dy);

      for (int i = 1; i < sub.length; i++) {
        final p = toBoardPx(sub[i]);
        path.lineTo(p.dx, p.dy);
      }

      path.close();

      if (fillEnabled) {
        canvas.drawPath(path, fillPaint);
      }

      if (strokeEnabled) {
        canvas.drawPath(path, strokePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant LetterPointsPainter old) {
    return old.letterSubpathsNorm != letterSubpathsNorm ||
        old.fillEnabled != fillEnabled ||
        old.strokeEnabled != strokeEnabled ||
        old.fillOpacity != fillOpacity ||
        old.strokeOpacity != strokeOpacity ||
        old.strokeWidth != strokeWidth;
  }
}
