import 'package:flutter/material.dart';

/// Paints guide-card stroke-order paths with progressive fill.
///
/// • Completed strokes → solid dark.
/// • Current partial stroke → dark up to [currentStrokeFraction], then light gray.
/// • Future strokes → light gray.
class ProgressiveStrokesPainter extends CustomPainter {
  ProgressiveStrokesPainter({
    required this.guideStrokes,
    required this.completedStrokeCount,
    required this.currentStrokeFraction,
  });

  final List<List<Offset>> guideStrokes;
  final int completedStrokeCount;
  final double currentStrokeFraction;

  @override
  void paint(Canvas canvas, Size size) {
    if (guideStrokes.isEmpty) return;

    final completedPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = Colors.black.withValues(alpha: 0.75)
      ..isAntiAlias = true;

    final remainingPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = Colors.grey.withValues(alpha: 0.22)
      ..isAntiAlias = true;

    for (int i = 0; i < guideStrokes.length; i++) {
      final stroke = guideStrokes[i];
      if (stroke.length < 2) continue;

      if (i < completedStrokeCount) {
        _drawPath(canvas, stroke, completedPaint);
      } else if (i == completedStrokeCount) {
        _drawPartialStroke(canvas, stroke, currentStrokeFraction,
            completedPaint, remainingPaint);
      } else {
        _drawPath(canvas, stroke, remainingPaint);
      }
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────

  void _drawPath(Canvas canvas, List<Offset> pts, Paint paint) {
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (int i = 1; i < pts.length; i++) {
      path.lineTo(pts[i].dx, pts[i].dy);
    }
    canvas.drawPath(path, paint);
  }

  void _drawPartialStroke(
    Canvas canvas,
    List<Offset> stroke,
    double fraction,
    Paint completedPaint,
    Paint remainingPaint,
  ) {
    if (fraction <= 0.01) {
      _drawPath(canvas, stroke, remainingPaint);
      return;
    }
    if (fraction >= 0.99) {
      _drawPath(canvas, stroke, completedPaint);
      return;
    }

    // Build cumulative arc-lengths
    final cumLen = <double>[0.0];
    for (int i = 1; i < stroke.length; i++) {
      cumLen.add(cumLen.last + (stroke[i] - stroke[i - 1]).distance);
    }
    final totalLen = cumLen.last;
    if (totalLen <= 0) return;

    final targetLen = fraction * totalLen;

    // Binary-search for the segment containing targetLen
    int splitSeg = 1;
    for (int i = 1; i < cumLen.length; i++) {
      if (cumLen[i] >= targetLen) {
        splitSeg = i;
        break;
      }
    }

    final segStart = cumLen[splitSeg - 1];
    final segEnd = cumLen[splitSeg];
    final segLen = segEnd - segStart;
    final localT = segLen > 0 ? (targetLen - segStart) / segLen : 0.0;
    final splitPt = Offset(
      stroke[splitSeg - 1].dx +
          (stroke[splitSeg].dx - stroke[splitSeg - 1].dx) * localT,
      stroke[splitSeg - 1].dy +
          (stroke[splitSeg].dy - stroke[splitSeg - 1].dy) * localT,
    );

    // Completed portion
    final compPath = Path()..moveTo(stroke.first.dx, stroke.first.dy);
    for (int i = 1; i < splitSeg; i++) {
      compPath.lineTo(stroke[i].dx, stroke[i].dy);
    }
    compPath.lineTo(splitPt.dx, splitPt.dy);
    canvas.drawPath(compPath, completedPaint);

    // Remaining portion
    final remPath = Path()..moveTo(splitPt.dx, splitPt.dy);
    for (int i = splitSeg; i < stroke.length; i++) {
      remPath.lineTo(stroke[i].dx, stroke[i].dy);
    }
    canvas.drawPath(remPath, remainingPaint);
  }

  @override
  bool shouldRepaint(covariant ProgressiveStrokesPainter old) {
    return old.completedStrokeCount != completedStrokeCount ||
        old.currentStrokeFraction != currentStrokeFraction ||
        old.guideStrokes != guideStrokes;
  }
}
