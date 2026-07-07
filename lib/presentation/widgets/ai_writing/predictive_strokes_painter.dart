import 'package:flutter/material.dart';

class PredictiveStrokesPainter extends CustomPainter {
  final List<List<Offset>> predictedSegments;

  PredictiveStrokesPainter({required this.predictedSegments});

  @override
  void paint(Canvas canvas, Size size) {
    if (predictedSegments.isEmpty) return;

    final paint = Paint()
      ..color = const Color(0xFFFF3B30) // vibrant red
      ..strokeWidth = 4.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (final segment in predictedSegments) {
      if (segment.length < 2) continue;
      final path = Path()..moveTo(segment.first.dx, segment.first.dy);
      for (int i = 1; i < segment.length; i++) {
        path.lineTo(segment[i].dx, segment[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant PredictiveStrokesPainter oldDelegate) {
    return oldDelegate.predictedSegments != predictedSegments;
  }
}
