import 'dart:math';

import 'package:flutter/material.dart';

class AdventureShadowScore {
  final double iou;
  final int xp;
  final bool isPerfect;

  const AdventureShadowScore({
    required this.iou,
    required this.xp,
    required this.isPerfect,
  });
}

class AdventureShadowScoreUtil {
  AdventureShadowScoreUtil._();

  static const double _perfectIouThreshold = 0.985;

  static AdventureShadowScore calculate({
    required List<List<Map<String, dynamic>>> userRawStrokes,
    required List<List<Offset>> templateStrokesPx,
    required double boardWidth,
    required double boardHeight,
  }) {
    if (templateStrokesPx.isEmpty) {
      return const AdventureShadowScore(iou: 1.0, xp: 100, isPerfect: true);
    }

    final filteredStrokes = _filterMeaningfulStrokes(userRawStrokes);
    if (filteredStrokes.isEmpty) {
      return const AdventureShadowScore(iou: 0.0, xp: 0, isPerfect: false);
    }

    final iou = _computeIou(
      userRawStrokes: filteredStrokes,
      templateStrokesPx: templateStrokesPx,
      boardWidth: boardWidth,
      boardHeight: boardHeight,
    ).clamp(0.0, 1.0).toDouble();

    final isPerfect = iou >= _perfectIouThreshold;
    final xp = isPerfect
        ? 100
        : (iou * 100).round().clamp(0, 100);

    return AdventureShadowScore(iou: iou, xp: xp, isPerfect: isPerfect);
  }

  static List<List<Map<String, dynamic>>> _filterMeaningfulStrokes(
    List<List<Map<String, dynamic>>> userRawStrokes,
  ) {
    return userRawStrokes.where((stroke) {
      if (stroke.length < 3) return false;

      final first = stroke.first;
      final startX = (first['x'] as num).toDouble();
      final startY = (first['y'] as num).toDouble();

      for (int i = 1; i < stroke.length; i++) {
        final p = stroke[i];
        final dx = (p['x'] as num).toDouble() - startX;
        final dy = (p['y'] as num).toDouble() - startY;
        if (sqrt(dx * dx + dy * dy) > 8) {
          return true;
        }
      }

      return false;
    }).toList();
  }

  static double _computeIou({
    required List<List<Map<String, dynamic>>> userRawStrokes,
    required List<List<Offset>> templateStrokesPx,
    required double boardWidth,
    required double boardHeight,
  }) {
    final cols = max(48, min(96, (boardWidth / 4.5).round()));
    final rows = max(48, min(96, (boardHeight / 4.5).round()));
    final cellWidth = boardWidth / cols;
    final cellHeight = boardHeight / rows;
    final sampleStepPx = min(cellWidth, cellHeight) * 0.55;
    final strokeRadiusPx = max(10.0, min(boardWidth, boardHeight) * 0.042);

    final userMask = <int>{};
    final templateMask = <int>{};

    for (final stroke in userRawStrokes) {
      final points = stroke
          .map(
            (p) => Offset(
              (p['x'] as num).toDouble(),
              (p['y'] as num).toDouble(),
            ),
          )
          .toList();
      _rasterizeStroke(
        points: points,
        target: userMask,
        cols: cols,
        rows: rows,
        boardWidth: boardWidth,
        boardHeight: boardHeight,
        cellWidth: cellWidth,
        cellHeight: cellHeight,
        sampleStepPx: sampleStepPx,
        strokeRadiusPx: strokeRadiusPx,
      );
    }

    for (final stroke in templateStrokesPx) {
      _rasterizeStroke(
        points: stroke,
        target: templateMask,
        cols: cols,
        rows: rows,
        boardWidth: boardWidth,
        boardHeight: boardHeight,
        cellWidth: cellWidth,
        cellHeight: cellHeight,
        sampleStepPx: sampleStepPx,
        strokeRadiusPx: strokeRadiusPx,
      );
    }

    if (userMask.isEmpty || templateMask.isEmpty) {
      return 0.0;
    }

    final intersection = userMask.intersection(templateMask).length;
    final union = userMask.union(templateMask).length;

    if (union == 0) return 0.0;
    return intersection / union;
  }

  static void _rasterizeStroke({
    required List<Offset> points,
    required Set<int> target,
    required int cols,
    required int rows,
    required double boardWidth,
    required double boardHeight,
    required double cellWidth,
    required double cellHeight,
    required double sampleStepPx,
    required double strokeRadiusPx,
  }) {
    if (points.isEmpty) return;

    if (points.length == 1) {
      _markDisk(
        target: target,
        point: points.first,
        cols: cols,
        rows: rows,
        boardWidth: boardWidth,
        boardHeight: boardHeight,
        cellWidth: cellWidth,
        cellHeight: cellHeight,
        radiusPx: strokeRadiusPx,
      );
      return;
    }

    for (int i = 1; i < points.length; i++) {
      final a = points[i - 1];
      final b = points[i];
      final distance = (b - a).distance;
      final steps = max(1, (distance / sampleStepPx).ceil());

      for (int step = 0; step <= steps; step++) {
        final t = step / steps;
        final sample = Offset.lerp(a, b, t) ?? a;
        _markDisk(
          target: target,
          point: sample,
          cols: cols,
          rows: rows,
          boardWidth: boardWidth,
          boardHeight: boardHeight,
          cellWidth: cellWidth,
          cellHeight: cellHeight,
          radiusPx: strokeRadiusPx,
        );
      }
    }
  }

  static void _markDisk({
    required Set<int> target,
    required Offset point,
    required int cols,
    required int rows,
    required double boardWidth,
    required double boardHeight,
    required double cellWidth,
    required double cellHeight,
    required double radiusPx,
  }) {
    if (point.dx.isNaN || point.dy.isNaN) return;

    final clampedX = point.dx.clamp(0.0, boardWidth).toDouble();
    final clampedY = point.dy.clamp(0.0, boardHeight).toDouble();

    final centerCol = (clampedX / cellWidth).floor().clamp(0, cols - 1);
    final centerRow =
        (clampedY / cellHeight).floor().clamp(0, rows - 1);

    final radiusCols = max(1, (radiusPx / cellWidth).ceil()).toInt();
    final radiusRows = max(1, (radiusPx / cellHeight).ceil()).toInt();
    final radiusSq = radiusPx * radiusPx;

    for (int row = centerRow - radiusRows; row <= centerRow + radiusRows; row++) {
      if (row < 0 || row >= rows) continue;

      for (int col = centerCol - radiusCols; col <= centerCol + radiusCols; col++) {
        if (col < 0 || col >= cols) continue;

        final cellCenterX = (col + 0.5) * cellWidth;
        final cellCenterY = (row + 0.5) * cellHeight;
        final dx = cellCenterX - clampedX;
        final dy = cellCenterY - clampedY;

        if ((dx * dx) + (dy * dy) <= radiusSq) {
          target.add((row * cols) + col);
        }
      }
    }
  }
}
