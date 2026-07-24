import 'package:flutter/widgets.dart';

class DrawingPointsUtil {
  static List<List<dynamic>> getPointsJson({
    required List<List<Map<String, dynamic>>> rawStrokes,
    required double scale,
  }) {
    final points = <List<dynamic>>[];
    int timeStep = 0;

    int? firstTimestamp;
    for (final stroke in rawStrokes) {
      for (final p in stroke) {
        final t = (p['time'] as num?)?.toInt();
        if (t != null && (firstTimestamp == null || t < firstTimestamp)) {
          firstTimestamp = t;
        }
      }
    }
    firstTimestamp ??= 0;

    for (int si = 0; si < rawStrokes.length; si++) {
      final stroke = rawStrokes[si];
      final isLastStroke = si == rawStrokes.length - 1;

      for (int pi = 0; pi < stroke.length; pi++) {
        final p = stroke[pi];
        timeStep++;
        final isLastPoint = pi == stroke.length - 1;

        int penState;
        if (isLastPoint && isLastStroke) {
          penState = 2; // end of entire drawing
        } else if (isLastPoint) {
          penState = 1; // lifting hand to draw another stroke
        } else {
          penState = 0; // drawing
        }

        final rawTime = (p['time'] as num?)?.toInt() ?? 0;
        points.add([
          timeStep,
          double.parse(
            ((p['x'] as num).toDouble() / scale).toStringAsFixed(1),
          ),
          double.parse(
            ((p['y'] as num).toDouble() / scale).toStringAsFixed(1),
          ),
          penState,
          rawTime - firstTimestamp,
          null,
        ]);
      }
    }

    return points;
  }

  static String getDeviceType() {
    final shortestSide = MediaQueryData.fromView(
      WidgetsBinding.instance.platformDispatcher.views.first,
    ).size.shortestSide;
    return shortestSide >= 600 ? 'tablet' : 'phone';
  }
}
