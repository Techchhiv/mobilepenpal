import 'package:flutter/material.dart';

class StitchDebugSegment {
  final Offset from;
  final Offset to;
  final double radius;

  StitchDebugSegment({
    required this.from,
    required this.to,
    required this.radius,
  });
}

class StitchDebugPainter extends CustomPainter {
  final List<StitchDebugSegment> segments;

  StitchDebugPainter({required this.segments});

  @override
  void paint(Canvas canvas, Size size) {
    if (segments.isEmpty) return;

    final linePaint = Paint()
      ..color = const Color(0xFFFFC107) // Yellow / Amber
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final circlePaint = Paint()
      ..color = const Color(0xFFFFC107).withValues(alpha: 0.15) // Soft yellow aura
      ..style = PaintingStyle.fill;

    final circleBorderPaint = Paint()
      ..color = const Color(0xFFFFC107).withValues(alpha: 0.5)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final startPointPaint = Paint()
      ..color = const Color(0xFFEF4444) // Red dot at stitch origin (end of previous stroke)
      ..style = PaintingStyle.fill;

    final endPointPaint = Paint()
      ..color = const Color(0xFFFFC107) // Yellow dot at stitch target (start of new stroke)
      ..style = PaintingStyle.fill;

    for (final seg in segments) {
      // 1. Draw threshold radius circle around previous stroke's last point
      canvas.drawCircle(seg.from, seg.radius, circlePaint);
      canvas.drawCircle(seg.from, seg.radius, circleBorderPaint);

      // 2. Draw yellow connecting line between stitched points
      canvas.drawLine(seg.from, seg.to, linePaint);

      // 3. Draw endpoint dots
      canvas.drawCircle(seg.from, 4.5, startPointPaint);
      canvas.drawCircle(seg.to, 4.5, endPointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant StitchDebugPainter oldDelegate) => true;
}
