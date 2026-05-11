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

  /// How much of the drawing must be inside the shadow (0.0 to 1.0).
  /// means 80% of the user's drawing points must be within the shadow area.
  static const double minOverlapRatio = 0.80;

  /// How much of the SHADOW must be covered by the user's drawing (0.0 to 1.0).
  /// means they must draw over at least 70% of the template's length.
  static const double minCoverageRatio = 0.95;

  /// The thickness of the shadow area relative to the board size.
  /// We relax this slightly so wobbly drawings don't trigger "out of bounds".
  static const double allowedDistanceRatio = 0.10;

  static String? getFeedback({
    required List<List<Map<String, dynamic>>> userRawStrokes,
    required List<List<Offset>> templateStrokesPx,
    required double boardWidth,
    required double boardHeight,
    bool ignoreBounds = false,
  }) {
    if (templateStrokesPx.isEmpty) return null;

    // ── 0. Filter out tiny accidental strokes (taps / jitter) ────────
    // A child may accidentally touch and lift quickly, creating a
    // "stroke" with just 1-2 points and barely any movement.
    final filteredStrokes = userRawStrokes.where((stroke) {
      if (stroke.length < 3) return false;
      final first = stroke.first;
      final startX = (first['x'] as num).toDouble();
      final startY = (first['y'] as num).toDouble();
      for (int i = 1; i < stroke.length; i++) {
        final p = stroke[i];
        final dx = (p['x'] as num).toDouble() - startX;
        final dy = (p['y'] as num).toDouble() - startY;
        if (sqrt(dx * dx + dy * dy) > 8) return true;
      }
      return false;
    }).toList();

    // If filtering removed everything, treat as no meaningful input.
    if (filteredStrokes.isEmpty) {
      return 'feedback_draw_slowly';
    }

    // ── 1. Overlap / Out of bounds ───────────────────────────────────
    // Fails if a large portion of the drawing is outside the template shadow.
    // We check this first because if they are completely off in space,
    // the stroke count doesn't matter yet.
    // Skipped when ignoreBounds is true (blank canvas with no guide).
    if (!ignoreBounds) {
      final overlapHint = _checkOverlap(
        userRawStrokes: filteredStrokes,
        templateStrokesPx: templateStrokesPx,
        boardWidth: boardWidth,
        boardHeight: boardHeight,
      );
      if (overlapHint != null) return overlapHint;
    }

    // ── 2. Stroke count ──────────────────────────────────────────────
    final userCount = filteredStrokes.length;
    final templateCount = templateStrokesPx.length;

    if (userCount != templateCount) {
      return 'feedback_wrong_count';
    }

    // ── 3. Stroke order ──────────────────────────────────────────────
    final orderHint = _checkStrokeOrder(
      userRawStrokes: filteredStrokes,
      templateStrokesPx: templateStrokesPx,
    );
    if (orderHint != null) {
      return orderHint;
    }

    // ── 4. Stroke direction ──────────────────────────────────────────
    final directionHint = _checkStrokeDirection(
      userRawStrokes: filteredStrokes,
      templateStrokesPx: templateStrokesPx,
    );
    if (directionHint != null) {
      return directionHint;
    }

    // ── 5. All structural checks passed ──────────────────────────────
    return null;
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
    final double allowedDist =
        min(boardWidth, boardHeight) * allowedDistanceRatio;
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

    // 1. Check Out of Bounds: Are the user's points staying inside the shadow?
    final double overlapRatio =
        (totalUserPoints - outsidePoints) / totalUserPoints;
    if (overlapRatio < minOverlapRatio) {
      return 'feedback_out_of_bounds';
    }

    // 2. Check Coverage: Did the user draw over enough of the template?
    int uncoveredTemplatePoints = 0;
    // We can use a slightly larger buffer for coverage check so we don't require
    // them to hit every single pixel.
    final double coverageDistSq = allowedDistSq * 1.5;

    for (final tp in tPoints) {
      double minDistSq = double.infinity;
      for (final stroke in userRawStrokes) {
        for (final p in stroke) {
          final ux = (p['x'] as num).toDouble();
          final uy = (p['y'] as num).toDouble();
          final distSq =
              (tp.dx - ux) * (tp.dx - ux) + (tp.dy - uy) * (tp.dy - uy);
          if (distSq < minDistSq) {
            minDistSq = distSq;
          }
        }
      }
      if (minDistSq > coverageDistSq) {
        uncoveredTemplatePoints++;
      }
    }

    final double coverageRatio =
        (tPoints.length - uncoveredTemplatePoints) / tPoints.length;
    if (coverageRatio < minCoverageRatio) {
      return 'feedback_incomplete'; // You may need to ensure this translation key exists, or fallback to something else like 'feedback_wrong_count'
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

      if (uStroke.length < 5 || tStroke.length < 3) continue;

      final uStart = Offset(
        (uStroke.first['x'] as num).toDouble(),
        (uStroke.first['y'] as num).toDouble(),
      );
      final uEnd = Offset(
        (uStroke.last['x'] as num).toDouble(),
        (uStroke.last['y'] as num).toDouble(),
      );
      final tStart = tStroke.first;
      final tEnd = tStroke.last;

      if ((tStart - tEnd).distance > 20) {
        // Open stroke: compare sum of distances for forward vs reverse mapping
        final dForward = (uStart - tStart).distance + (uEnd - tEnd).distance;
        final dReverse = (uStart - tEnd).distance + (uEnd - tStart).distance;
        if (dReverse < dForward) {
          return 'feedback_wrong_direction';
        }
      } else {
        // Closed loop (start and end are near each other)
        // Check structural progression at 25% and 75% marks
        final u25 = Offset(
          (uStroke[uStroke.length ~/ 4]['x'] as num).toDouble(),
          (uStroke[uStroke.length ~/ 4]['y'] as num).toDouble(),
        );
        final t25 = tStroke[tStroke.length ~/ 4];
        final t75 = tStroke[tStroke.length * 3 ~/ 4];

        final dForward = (u25 - t25).distance;
        final dReverse = (u25 - t75).distance;

        if (dReverse < dForward - 10) {
          return 'feedback_wrong_direction';
        }
      }
    }

    return null;
  }

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
      if (bestIdx == previousBestMatch && bestIdx != i) {
        if ((tStarts[i] - tStarts[bestIdx]).distance > 15) {
          return 'feedback_wrong_order';
        }
      }
      previousBestMatch = bestIdx;
    }

    return null;
  }
}
