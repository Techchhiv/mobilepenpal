import 'dart:math';
import 'package:flutter/material.dart';

/// Dedicated stroke feedback validator for Free Handwriting in AI Writing practice page.
/// Uses Enhanced Length-normalized Dynamic Time Warping (LDTW) with:
/// 1. Micro-tap / noise filtering
/// 2. Stroke count validation
/// 3. Resampling to equidistant points (40 pts)
/// 4. Centroid & bounding span normalization
/// 5. Direction enforcement via forward vs. reverse LDTW costs
/// 6. Stroke order alignment
/// 7. Sakoe-Chiba windowed DTW with tangent angle penalties
/// 8. Maximum point-to-trajectory outlier deviation check (rejects inner lines/stray marks)
/// 9. Per-stroke strictness enforcement (every stroke must pass)
class AiStrokeFeedbackUtil {
  AiStrokeFeedbackUtil._();

  /// Target equidistant points per stroke for DTW alignment
  static const int numResamplePoints = 40;

  /// Sakoe-Chiba warping window (limits how far DTW can warp time)
  static const int warpingWindow = 10;

  /// Maximum LDTW threshold for accepting free handwriting.
  static const double maxAcceptableLdtw = 0.088;

  /// Maximum allowed point-to-trajectory deviation in normalized span units.
  /// Catches extra lines, inner bars (like in 'ក'), or stray diagonal lines (like in 'ង').
  static const double maxAllowedOutlierDev = 0.13;

  /// Threshold separating attached scribbles/loops from completely wrong characters.
  static const double maxScribbleLdtw = 0.18;

  static String? getFeedback({
    required List<List<Map<String, dynamic>>> userRawStrokes,
    required List<List<Offset>> templateStrokesPx,
    required double boardWidth,
    required double boardHeight,
  }) {
    if (templateStrokesPx.isEmpty) return null;

    // ── 0. Filter out accidental tiny taps / noise (< 3 pts or length < 10px) ──
    final filteredStrokes = userRawStrokes.where((stroke) {
      if (stroke.length < 3) return false;
      double totalLen = 0.0;
      for (int i = 1; i < stroke.length; i++) {
        final p1 = stroke[i - 1];
        final p2 = stroke[i];
        final dx = (p2['x'] as num).toDouble() - (p1['x'] as num).toDouble();
        final dy = (p2['y'] as num).toDouble() - (p1['y'] as num).toDouble();
        totalLen += sqrt(dx * dx + dy * dy);
      }
      return totalLen > 10.0;
    }).toList();

    if (filteredStrokes.isEmpty) {
      return 'feedback_incomplete';
    }

    final userCount = filteredStrokes.length;
    final templateCount = templateStrokesPx.length;

    // ── 1. Stroke count check ─────────────────────────────────────────
    if (userCount != templateCount) {
      if (userCount > templateCount) {
        return 'feedback_wrong_count';
      } else {
        return 'feedback_incomplete';
      }
    }

    // Convert user raw strokes to List<List<Offset>>
    final uOffsetStrokes = filteredStrokes.map((stroke) {
      return stroke.map((p) {
        return Offset((p['x'] as num).toDouble(), (p['y'] as num).toDouble());
      }).toList();
    }).toList();

    // ── 2. Stroke order check (for multi-stroke characters) ───────────
    final orderHint = _checkStrokeOrder(
      userStrokes: uOffsetStrokes,
      templateStrokesPx: templateStrokesPx,
    );
    if (orderHint != null) {
      return orderHint;
    }

    // ── 3. Resample strokes to equidistant points ─────────────────────
    final uResampled = uOffsetStrokes
        .map((s) => resampleStroke(s, numResamplePoints))
        .toList();
    final tResampled = templateStrokesPx
        .map((s) => resampleStroke(s, numResamplePoints))
        .toList();

    // ── 4. Centroid & Span Normalization ──────────────────────────────
    final uNorm = normalizeStrokes(uResampled);
    final tNorm = normalizeStrokes(tResampled);

    // ── 5. Direction & Per-Stroke Evaluation ─────────────────────────
    double maxLdtw = 0.0;
    double maxOutlierDev = 0.0;
    bool hasWrongDirection = false;

    for (int i = 0; i < templateCount; i++) {
      final uStroke = uNorm[i];
      final tStroke = tNorm[i];

      final evalFwd = computeEnhancedLdtw(uStroke, tStroke);
      final evalRev = computeEnhancedLdtw(uStroke.reversed.toList(), tStroke);

      if (evalRev.ldtw < evalFwd.ldtw - 0.035) {
        hasWrongDirection = true;
      }

      if (evalFwd.ldtw > maxLdtw) {
        maxLdtw = evalFwd.ldtw;
      }
      if (evalFwd.maxDeviation > maxOutlierDev) {
        maxOutlierDev = evalFwd.maxDeviation;
      }
    }

    if (hasWrongDirection) {
      return 'feedback_wrong_direction';
    }

    // ── 6. LDTW & Max Local Deviation Decision ───────────────────────
    // Every stroke must be within acceptable LDTW and not have stray marks/bars
    if (maxLdtw <= maxAcceptableLdtw && maxOutlierDev <= maxAllowedOutlierDev) {
      return null; // Passed! Clean shape match.
    } else if (maxLdtw <= maxScribbleLdtw ||
        maxOutlierDev <= maxAllowedOutlierDev * 1.8) {
      return 'feedback_scribble_detected';
    } else {
      return 'feedback_wrong_character';
    }
  }

  /// Resample a polyline to [numPts] equidistant points along its cumulative arc length.
  static List<Offset> resampleStroke(List<Offset> pts, int numPts) {
    if (pts.length < 2) {
      return List<Offset>.filled(
        numPts,
        pts.isNotEmpty ? pts.first : Offset.zero,
      );
    }

    final dists = <double>[0.0];
    double totalLen = 0.0;
    for (int i = 1; i < pts.length; i++) {
      totalLen += (pts[i] - pts[i - 1]).distance;
      dists.add(totalLen);
    }

    if (totalLen < 1e-4) {
      return List<Offset>.filled(numPts, pts.first);
    }

    final resampled = <Offset>[];
    final step = totalLen / (numPts - 1);

    for (int i = 0; i < numPts; i++) {
      final targetD = (i * step).clamp(0.0, totalLen);

      int lo = 0, hi = dists.length - 1;
      while (lo < hi) {
        final mid = (lo + hi) >> 1;
        if (dists[mid] >= targetD) {
          hi = mid;
        } else {
          lo = mid + 1;
        }
      }

      if (lo == 0) {
        resampled.add(pts.first);
      } else if (lo >= pts.length) {
        resampled.add(pts.last);
      } else {
        final d0 = dists[lo - 1];
        final d1 = dists[lo];
        final segLen = d1 - d0;
        final t = segLen > 0 ? ((targetD - d0) / segLen).clamp(0.0, 1.0) : 0.0;
        final p0 = pts[lo - 1];
        final p1 = pts[lo];
        resampled.add(
          Offset(p0.dx + (p1.dx - p0.dx) * t, p0.dy + (p1.dy - p0.dy) * t),
        );
      }
    }

    return resampled;
  }

  /// Normalizes a set of strokes by translating to the global centroid and scaling to unit span.
  static List<List<Offset>> normalizeStrokes(List<List<Offset>> strokes) {
    double sumX = 0.0, sumY = 0.0;
    int totalPts = 0;
    double minX = double.infinity, minY = double.infinity;
    double maxX = -double.infinity, maxY = -double.infinity;

    for (final s in strokes) {
      for (final p in s) {
        sumX += p.dx;
        sumY += p.dy;
        totalPts++;
        if (p.dx < minX) minX = p.dx;
        if (p.dx > maxX) maxX = p.dx;
        if (p.dy < minY) minY = p.dy;
        if (p.dy > maxY) maxY = p.dy;
      }
    }

    if (totalPts == 0) return strokes;

    final centroidX = sumX / totalPts;
    final centroidY = sumY / totalPts;
    final span = max(maxX - minX, maxY - minY);
    final scale = span < 1e-4 ? 1.0 : 1.0 / span;

    return strokes.map((s) {
      return s.map((p) {
        return Offset((p.dx - centroidX) * scale, (p.dy - centroidY) * scale);
      }).toList();
    }).toList();
  }

  /// Computes tangent unit vectors for a point sequence.
  static List<Offset> _computeTangents(List<Offset> pts) {
    final n = pts.length;
    if (n < 2) return List.filled(n, Offset.zero);

    final tangents = <Offset>[];
    for (int i = 0; i < n; i++) {
      Offset diff;
      if (i == 0) {
        diff = pts[1] - pts[0];
      } else if (i == n - 1) {
        diff = pts[n - 1] - pts[n - 2];
      } else {
        diff = pts[i + 1] - pts[i - 1];
      }
      final len = diff.distance;
      tangents.add(len > 1e-5 ? Offset(diff.dx / len, diff.dy / len) : Offset.zero);
    }
    return tangents;
  }

  /// Computes Length-normalized Dynamic Time Warping (LDTW) with Sakoe-Chiba window & tangent penalty,
  /// as well as the maximum local point-to-trajectory deviation.
  static LdtwResult computeEnhancedLdtw(
    List<Offset> X,
    List<Offset> Y, {
    int window = warpingWindow,
    double angleWeight = 0.12,
  }) {
    final n = X.length;
    final m = Y.length;
    if (n == 0 || m == 0) {
      return const LdtwResult(ldtw: double.infinity, maxDeviation: double.infinity);
    }

    final tX = _computeTangents(X);
    final tY = _computeTangents(Y);

    final d = List.generate(n, (_) => List<double>.filled(m, double.infinity));
    final cost = List.generate(n, (_) => List<double>.filled(m, 0.0));

    for (int i = 0; i < n; i++) {
      final minJ = max(0, i - window);
      final maxJ = min(m - 1, i + window);
      final xi = X[i];
      final txi = tX[i];

      for (int j = minJ; j <= maxJ; j++) {
        final posDist = (xi - Y[j]).distance;
        final tyj = tY[j];
        final dot = (txi.dx * tyj.dx + txi.dy * tyj.dy).clamp(-1.0, 1.0);
        final angDist = 1.0 - dot;
        cost[i][j] = posDist + angleWeight * angDist;
      }
    }

    d[0][0] = cost[0][0];

    for (int i = 1; i < min(n, window + 1); i++) {
      d[i][0] = d[i - 1][0] + cost[i][0];
    }
    for (int j = 1; j < min(m, window + 1); j++) {
      d[0][j] = d[0][j - 1] + cost[0][j];
    }

    for (int i = 1; i < n; i++) {
      final minJ = max(1, i - window);
      final maxJ = min(m - 1, i + window);

      for (int j = minJ; j <= maxJ; j++) {
        final dDiag = d[i - 1][j - 1];
        final dUp = d[i - 1][j];
        final dLeft = d[i][j - 1];
        final minPrev = min(dDiag, min(dUp, dLeft));
        if (!minPrev.isInfinite) {
          d[i][j] = cost[i][j] + minPrev;
        }
      }
    }

    // Traceback to find warping path length K
    int i = n - 1;
    int j = m - 1;
    int k = 1;

    while (i > 0 || j > 0) {
      k++;
      if (i == 0) {
        j--;
      } else if (j == 0) {
        i--;
      } else {
        final dDiag = d[i - 1][j - 1];
        final dUp = d[i - 1][j];
        final dLeft = d[i][j - 1];
        if (dDiag <= dUp && dDiag <= dLeft) {
          i--;
          j--;
        } else if (dUp <= dLeft) {
          i--;
        } else {
          j--;
        }
      }
    }

    final ldtw = d[n - 1][m - 1] / k;

    // Compute maximum local deviation from every user point to the template trajectory
    double maxDeviation = 0.0;
    for (final px in X) {
      double minD = double.infinity;
      for (final py in Y) {
        final dist = (px - py).distance;
        if (dist < minD) minD = dist;
      }
      if (minD > maxDeviation) {
        maxDeviation = minD;
      }
    }

    return LdtwResult(ldtw: ldtw, maxDeviation: maxDeviation);
  }

  /// Validates a drawing that may be completely empty, partial (mid-stroke), or multi-stroke in progress.
  /// Used specifically for determining whether the Hint button should be active/clickable.
  static PartialValidationResult validatePartialDrawing({
    required List<List<Map<String, dynamic>>> userRawStrokes,
    required List<List<Offset>> templateStrokesPx,
    required double boardWidth,
    required double boardHeight,
  }) {
    if (templateStrokesPx.isEmpty) {
      return const PartialValidationResult(isValid: true);
    }

    // 0. Empty canvas is always valid for hint (allows guiding the very first stroke)
    final filteredStrokes = userRawStrokes.where((stroke) {
      if (stroke.length < 3) return false;
      double totalLen = 0.0;
      for (int i = 1; i < stroke.length; i++) {
        final p1 = stroke[i - 1];
        final p2 = stroke[i];
        final dx = (p2['x'] as num).toDouble() - (p1['x'] as num).toDouble();
        final dy = (p2['y'] as num).toDouble() - (p1['y'] as num).toDouble();
        totalLen += sqrt(dx * dx + dy * dy);
      }
      return totalLen > 8.0;
    }).toList();

    if (filteredStrokes.isEmpty) {
      return const PartialValidationResult(isValid: true);
    }

    final userCount = filteredStrokes.length;
    final templateCount = templateStrokesPx.length;

    // 1. Exceeded total stroke count for this character
    if (userCount > templateCount) {
      return const PartialValidationResult(
        isValid: false,
        reason: 'feedback_wrong_count',
      );
    }

    // 2. Stroke-by-stroke Multi-Scale Prefix Shape Validation
    for (int i = 0; i < userCount; i++) {
      final uRaw = filteredStrokes[i];
      final tStroke = templateStrokesPx[i];
      if (uRaw.length < 2 || tStroke.length < 2) continue;

      final uStroke = uRaw
          .map((p) => Offset((p['x'] as num).toDouble(), (p['y'] as num).toDouble()))
          .toList();

      // Arc-length scribble check
      double uLen = 0.0;
      for (int j = 1; j < uStroke.length; j++) {
        uLen += (uStroke[j] - uStroke[j - 1]).distance;
      }
      double tLen = 0.0;
      for (int j = 1; j < tStroke.length; j++) {
        tLen += (tStroke[j] - tStroke[j - 1]).distance;
      }

      if (tLen > 15.0 && uLen > tLen * 1.85) {
        return const PartialValidationResult(
          isValid: false,
          reason: 'feedback_scribble_detected',
        );
      }

      // Multi-scale prefix trajectory evaluation
      final eval = evaluatePartialStroke(uStroke, tStroke);
      if (eval.isWrongDirection) {
        return const PartialValidationResult(
          isValid: false,
          reason: 'feedback_wrong_direction',
        );
      }

      if (eval.score > 0.088) {
        return const PartialValidationResult(
          isValid: false,
          reason: 'feedback_scribble_detected',
        );
      }
    }

    return const PartialValidationResult(isValid: true);
  }

  /// Evaluates an incomplete / partial stroke against a template stroke using
  /// Multi-Scale Prefix LDTW search. Position-, scale-, and start-invariant.
  static PrefixEvaluationResult evaluatePartialStroke(
    List<Offset> uPts,
    List<Offset> tPts,
  ) {
    if (uPts.length < 2 || tPts.length < 2) {
      return const PrefixEvaluationResult(score: 0.0, isWrongDirection: false);
    }

    final uRes = resampleStroke(uPts, 30);
    final uNorm = normalizeStrokes([uRes])[0];
    final uNormRev = uNorm.reversed.toList();

    final tEq = resampleStroke(tPts, 60);

    double bestFwd = double.infinity;
    double bestRev = double.infinity;

    for (int m = 15; m <= 60; m += 3) {
      final tSub = resampleStroke(tEq.sublist(0, m), 30);
      final tNorm = normalizeStrokes([tSub])[0];

      final dFwd = computeEnhancedLdtw(uNorm, tNorm).ldtw;
      final dRev = computeEnhancedLdtw(uNormRev, tNorm).ldtw;

      if (dFwd < bestFwd) bestFwd = dFwd;
      if (dRev < bestRev) bestRev = dRev;
    }

    final isWrongDirection = (bestRev < bestFwd - 0.045);
    return PrefixEvaluationResult(
      score: bestFwd,
      isWrongDirection: isWrongDirection,
    );
  }

  /// Checks stroke order for multi-stroke characters.
  static String? _checkStrokeOrder({
    required List<List<Offset>> userStrokes,
    required List<List<Offset>> templateStrokesPx,
  }) {
    final count = min(userStrokes.length, templateStrokesPx.length);
    if (count < 2) return null;

    final tStarts = templateStrokesPx
        .map((s) => s.isNotEmpty ? s.first : Offset.zero)
        .toList();

    int previousBestMatch = -1;
    for (int i = 0; i < count; i++) {
      final uStroke = userStrokes[i];
      if (uStroke.isEmpty) continue;

      final uStart = uStroke.first;

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
        if ((tStarts[i] - tStarts[bestIdx]).distance > 15.0) {
          return 'feedback_wrong_order';
        }
      }
      previousBestMatch = bestIdx;
    }

    return null;
  }
}

class LdtwResult {
  final double ldtw;
  final double maxDeviation;

  const LdtwResult({required this.ldtw, required this.maxDeviation});
}

class PrefixEvaluationResult {
  final double score;
  final bool isWrongDirection;

  const PrefixEvaluationResult({
    required this.score,
    required this.isWrongDirection,
  });
}

class PartialValidationResult {
  final bool isValid;
  final String? reason;

  const PartialValidationResult({required this.isValid, this.reason});
}
