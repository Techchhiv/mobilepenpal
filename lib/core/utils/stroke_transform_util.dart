import 'dart:math';
import 'dart:ui';

class StrokeTransformUtil {
  static List<List<Map<String, dynamic>>> autoCenterStrokes(
    List<List<Map<String, dynamic>>> rawStrokes,
    List<List<Offset>> templateStrokesPx,
  ) {
    if (rawStrokes.isEmpty || templateStrokesPx.isEmpty) return rawStrokes;

    double uMinX = double.infinity, uMinY = double.infinity;
    double uMaxX = -double.infinity, uMaxY = -double.infinity;
    for (final stroke in rawStrokes) {
      for (final p in stroke) {
        final x = (p['x'] as num).toDouble();
        final y = (p['y'] as num).toDouble();
        if (x < uMinX) uMinX = x;
        if (x > uMaxX) uMaxX = x;
        if (y < uMinY) uMinY = y;
        if (y > uMaxY) uMaxY = y;
      }
    }

    double tMinX = double.infinity, tMinY = double.infinity;
    double tMaxX = -double.infinity, tMaxY = -double.infinity;
    for (final stroke in templateStrokesPx) {
      for (final p in stroke) {
        if (p.dx < tMinX) tMinX = p.dx;
        if (p.dx > tMaxX) tMaxX = p.dx;
        if (p.dy < tMinY) tMinY = p.dy;
        if (p.dy > tMaxY) tMaxY = p.dy;
      }
    }

    final uW = uMaxX - uMinX;
    final uH = uMaxY - uMinY;
    final tW = tMaxX - tMinX;
    final tH = tMaxY - tMinY;

    if (uW <= 0 || uH <= 0 || tW <= 0 || tH <= 0) return rawStrokes;

    final uCx = (uMinX + uMaxX) / 2;
    final uCy = (uMinY + uMaxY) / 2;
    final tCx = (tMinX + tMaxX) / 2;
    final tCy = (tMinY + tMaxY) / 2;

    final s = min(tW / uW, tH / uH);

    return rawStrokes.map((stroke) {
      return stroke.map((p) {
        final x = (p['x'] as num).toDouble();
        final y = (p['y'] as num).toDouble();
        return <String, dynamic>{
          'x': (x - uCx) * s + tCx,
          'y': (y - uCy) * s + tCy,
          if (p.containsKey('time')) 'time': p['time'],
        };
      }).toList();
    }).toList();
  }

  static List<List<Offset>> readSubpathsPx(List<dynamic> raw) {
    final out = <List<Offset>>[];
    for (final sub in raw) {
      final pts = <Offset>[];
      for (final p in (sub as List)) {
        pts.add(Offset((p[0] as num).toDouble(), (p[1] as num).toDouble()));
      }
      if (pts.isNotEmpty) out.add(pts);
    }
    return out;
  }

  static List<List<Offset>> autoFitGlyphPx(
    List<List<Offset>> paths, {
    required double boardW,
    required double boardH,
    double pad = 18,
    double minWidthFill = 0.72,
    double minHeightFill = 0.78,
  }) {
    if (paths.isEmpty) return paths;

    double minX = double.infinity, minY = double.infinity;
    double maxX = -double.infinity, maxY = -double.infinity;

    for (final sub in paths) {
      for (final p in sub) {
        if (p.dx < minX) minX = p.dx;
        if (p.dy < minY) minY = p.dy;
        if (p.dx > maxX) maxX = p.dx;
        if (p.dy > maxY) maxY = p.dy;
      }
    }

    final w = maxX - minX;
    final h = maxY - minY;
    if (w <= 0 || h <= 0) return paths;

    final innerW = boardW - 2 * pad;
    final innerH = boardH - 2 * pad;

    final sMax = min(innerW / w, innerH / h);
    final sWantW = (innerW * minWidthFill) / w;
    final sWantH = (innerH * minHeightFill) / h;

    final s = min(max(1.0, max(sWantW, sWantH)), sMax);

    final cx = (minX + maxX) / 2;
    final cy = (minY + maxY) / 2;
    final boardCx = boardW / 2;
    final boardCy = boardH / 2;

    return paths
        .map(
          (sub) => sub
              .map(
                (p) => Offset(
                  (p.dx - cx) * s + boardCx,
                  (p.dy - cy) * s + boardCy,
                ),
              )
              .toList(),
        )
        .toList();
  }
}
