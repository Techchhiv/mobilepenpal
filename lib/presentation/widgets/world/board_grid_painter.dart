import 'package:flutter/material.dart';

class BoardGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const int numCells = 8;
    final double cellWidth = size.width / numCells;
    final double cellHeight = size.height / numCells;

    final Paint gridPaint = Paint()
      ..color = Colors.blueGrey.withValues(alpha: 0.25)
      ..strokeWidth = 1.2;

    // Draw vertical lines
    for (int i = 1; i < numCells; i++) {
      double x = i * cellWidth;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    // Draw horizontal lines
    for (int i = 1; i < numCells; i++) {
      double y = i * cellHeight;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Draw a thin border to frame the grid within the drawing area properly
    final Paint borderPaint = Paint()
      ..color = Colors.blueGrey.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawRect(Offset.zero & size, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
