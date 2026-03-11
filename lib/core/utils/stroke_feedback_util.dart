import 'dart:math';
import 'package:flutter/material.dart';

/// Utility that compares a user's raw drawing strokes against the
/// reference / template strokes and returns a human-readable hint
/// describing what they drew incorrectly.
///
/// Checks are run in priority order – the first failing check wins:
///   1. Stroke count
///   2. Out-of-bounds (drawing far from the guide shadow)
///   3. Stroke direction (reversed start↔end)
///   4. Stroke order (wrong sequence)
class StrokeFeedbackUtil {
  StrokeFeedbackUtil._();

  /// Compare the user's raw strokes against the fitted template strokes.
  ///
  /// [userRawStrokes] – the per-stroke list of `{x, y, time}` maps collected
  /// by the pointer handlers (in board-pixel coordinates).
  ///
  /// [templateStrokesPx] – the `strokeStrokesNorm` list from the controller,
  /// already scaled to board-pixel space via `_autoFitGlyphPx`.
  ///
  /// [boardWidth] / [boardHeight] – current board dimensions, used for
  /// relative thresholds.
  ///
  /// Returns a feedback string if an issue is detected, or `null` when
  /// no specific feedback can be given.
  static String? getFeedback({
    required List<List<Map<String, dynamic>>> userRawStrokes,
    required List<List<Offset>> templateStrokesPx,
    required double boardWidth,
    required double boardHeight,
  }) {
    if (templateStrokesPx.isEmpty) return null;

    // ── 0. Filter out tiny accidental strokes (taps / jitter) ────────
    // A child may accidentally touch and lift quickly, creating a
    // "stroke" with just 1-2 points and barely any movement.
    final filteredStrokes = userRawStrokes.where((stroke) {
      if (stroke.length < 3) return false;
      final first = stroke.first;
      final last = stroke.last;
      final dx = (last['x'] as num).toDouble() - (first['x'] as num).toDouble();
      final dy = (last['y'] as num).toDouble() - (first['y'] as num).toDouble();
      return sqrt(dx * dx + dy * dy) > 8; // ignore strokes < 8px
    }).toList();

    // If filtering removed everything, treat as no meaningful input.
    if (filteredStrokes.isEmpty) {
      return 'feedback_draw_slowly';
    }

    // ── 1. Overlap / Out of bounds ───────────────────────────────────
    // Fails if a large portion of the drawing is outside the template shadow.
    // We check this first because if they are completely off in space,
    // the stroke count doesn't matter yet.
    final overlapHint = _checkOverlap(
      userRawStrokes: filteredStrokes,
      templateStrokesPx: templateStrokesPx,
      boardWidth: boardWidth,
      boardHeight: boardHeight,
    );
    if (overlapHint != null) return overlapHint;

    // ── 2. Stroke count ──────────────────────────────────────────────
    final userCount = filteredStrokes.length;
    final templateCount = templateStrokesPx.length;

    if (userCount != templateCount) {
      // If the user only drew 1 stroke when the template expects 2+,
      // it's likely a casual scribble rather than a real attempt.
      // Give the generic guidance instead of the specific count error.
      if (userCount == 1 && templateCount >= 2) {
        return 'feedback_draw_slowly';
      }
      return 'feedback_wrong_count';
    }

    // ── 3. Stroke order ──────────────────────────────────────────────
    final orderHint = _checkStrokeOrder(
      userRawStrokes: filteredStrokes,
      templateStrokesPx: templateStrokesPx,
    );
    if (orderHint != null) return orderHint;

    // ── 4. Stroke direction ──────────────────────────────────────────
    final directionHint = _checkStrokeDirection(
      userRawStrokes: filteredStrokes,
      templateStrokesPx: templateStrokesPx,
    );
    if (directionHint != null) return directionHint;

    // ── 5. Default fallback ──────────────────────────────────────────
    return 'feedback_draw_slowly';
  }

  /// Check if the user's drawing sufficiently overlaps the template.
  /// If too many of the user's drawing points are far away from any
  /// template point, it means they are drawing outside the shadow.
  static String? _checkOverlap({
    required List<List<Map<String, dynamic>>> userRawStrokes,
    required List<List<Offset>> templateStrokesPx,
    required double boardWidth,
    required double boardHeight,
  }) {
    // Flatten template points into a single list for easy distance checking.
    final List<Offset> tPoints = [];
    for (final stroke in templateStrokesPx) {
      tPoints.addAll(stroke);
    }
    if (tPoints.isEmpty) return null;

    int totalUserPoints = 0;
    int outsidePoints = 0;

    // Define the "shadow thickness" threshold.
    // 0.12 * boardSize allows them to be within ~12% of the board's edge
    // from the template center line.
    final double allowedDist = min(boardWidth, boardHeight) * 0.12;
    final double allowedDistSq = allowedDist * allowedDist;

    for (final stroke in userRawStrokes) {
      for (final p in stroke) {
        totalUserPoints++;
        final ux = (p['x'] as num).toDouble();
        final uy = (p['y'] as num).toDouble();

        // Find distance to the closest template point.
        double minDistSq = double.infinity;
        for (final tp in tPoints) {
          final distSq =
              (tp.dx - ux) * (tp.dx - ux) + (tp.dy - uy) * (tp.dy - uy);
          if (distSq < minDistSq) {
            minDistSq = distSq.toDouble();
          }
        }

        // If this point is too far from the template, count it as outside.
        if (minDistSq > allowedDistSq) {
          outsidePoints++;
        }
      }
    }

    if (totalUserPoints == 0) return null;

    // If more than 40% of the user's drawing points are outside the shadow,
    // they are not following the guide well enough.
    if ((outsidePoints / totalUserPoints) > 0.40) {
      return 'feedback_out_of_bounds';
    }

    return null;
  }

  /// Check whether any user stroke is drawn in the reverse direction
  /// compared to the corresponding template stroke.
  static String? _checkStrokeDirection({
    required List<List<Map<String, dynamic>>> userRawStrokes,
    required List<List<Offset>> templateStrokesPx,
  }) {
    final count = min(userRawStrokes.length, templateStrokesPx.length);

    for (int i = 0; i < count; i++) {
      final uStroke = userRawStrokes[i];
      final tStroke = templateStrokesPx[i];

      if (uStroke.length < 2 || tStroke.length < 2) continue;

      Offset getDirUser(List<Map<String, dynamic>> pts) {
        final s = Offset((pts.first['x'] as num).toDouble(), (pts.first['y'] as num).toDouble());
        for (int j = 1; j < pts.length; j++) {
          final p = Offset((pts[j]['x'] as num).toDouble(), (pts[j]['y'] as num).toDouble());
          if ((p - s).distance > 15) return p - s;
        }
        final e = Offset((pts.last['x'] as num).toDouble(), (pts.last['y'] as num).toDouble());
        return e - s;
      }

      Offset getDirTemplate(List<Offset> pts) {
        final s = pts.first;
        for (int j = 1; j < pts.length; j++) {
          if ((pts[j] - s).distance > 15) return pts[j] - s;
        }
        return pts.last - s;
      }

      final uDir = getDirUser(uStroke);
      final tDir = getDirTemplate(tStroke);

      // Skip very short strokes (dots / taps).
      if (uDir.distance < 5 || tDir.distance < 5) continue;

      // Dot product < 0 means the vectors point in opposite directions.
      final dot = uDir.dx * tDir.dx + uDir.dy * tDir.dy;
      if (dot < 0) {
        return 'feedback_wrong_direction';
      }
    }

    return null;
  }

  /// Check whether the user drew the strokes in the wrong order.
  ///
  /// Strategy: for each user stroke, find which template stroke has the
  /// closest starting point. If the resulting mapping is not monotonically
  /// increasing, the user likely drew the strokes out of order.
  static String? _checkStrokeOrder({
    required List<List<Map<String, dynamic>>> userRawStrokes,
    required List<List<Offset>> templateStrokesPx,
  }) {
    final count = min(userRawStrokes.length, templateStrokesPx.length);
    if (count < 2) return null;

    // Build list of template stroke starting points.
    final tStarts = templateStrokesPx
        .map((s) => s.isNotEmpty ? s.first : Offset.zero)
        .toList();

    int previousBestMatch = -1;
    for (int i = 0; i < count; i++) {
      final uStroke = userRawStrokes[i];
      if (uStroke.isEmpty) continue;

      final uStart = Offset(
        (uStroke.first['x'] as num).toDouble(),
        (uStroke.first['y'] as num).toDouble(),
      );

      // Find the closest template stroke start.
      int bestIdx = 0;
      double bestDist = double.infinity;
      for (int j = 0; j < tStarts.length; j++) {
        final d = (uStart - tStarts[j]).distance;
        if (d < bestDist) {
          bestDist = d;
          bestIdx = j;
        }
      }

      if (bestIdx < previousBestMatch) {
        return 'feedback_wrong_order';
      }
      previousBestMatch = bestIdx;
    }

    return null;
  }
}
