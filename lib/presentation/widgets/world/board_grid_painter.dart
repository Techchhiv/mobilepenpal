import 'package:flutter/material.dart';

class BoardGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const int numCellsMin = 8;
    final double cellSize =
        (size.width < size.height ? size.width : size.height) / numCellsMin;

    final Paint gridPaint = Paint()
      ..color = Colors.blueGrey.withValues(alpha: 0.25)
      ..strokeWidth = 1.2;

    // Draw vertical lines
    for (double x = cellSize; x < size.width; x += cellSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    // Draw horizontal lines
    for (double y = cellSize; y < size.height; y += cellSize) {
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
