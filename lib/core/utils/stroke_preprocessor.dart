import 'dart:math';

class StrokePreprocessor {
  StrokePreprocessor._();

  static PreprocessedResult preprocessForModel(
    String modelType,
    List<List<Map<String, dynamic>>> rawStrokes,
  ) {
    switch (modelType) {
      case 'digit':
        return _preprocessDigit(rawStrokes);
      case 'math':
        return _preprocessMath(rawStrokes);
      case 'consonant':
      case 'independent_vowel':
      case 'dependent_vowel':
        return _preprocessCharacter(rawStrokes);
      default:
        return _preprocessCharacter(rawStrokes);
    }
  }

  static PreprocessedResult _preprocessDigit(
    List<List<Map<String, dynamic>>> rawStrokes,
  ) {
    final coords = _extractCoordinates(rawStrokes);
    final scaled = _scaleCoordinates(coords);
    final substrokes = _splitToSubstroke(scaled);

    return PreprocessedResult(
      segments: [substrokes],
      shapes: [
        [1, substrokes.length, 16],
      ],
    );
  }

  static PreprocessedResult _preprocessMath(
    List<List<Map<String, dynamic>>> rawStrokes,
  ) {
    final coords = _extractCoordinates(rawStrokes);
    final scaled = _scaleCoordinates(coords);
    final hist = _computeVerticalProjection(scaled);
    final segments = _findSegments(hist);
    final splitSegs = _splitStrokes(scaled, segments);

    final allSegments = <List<List<double>>>[];
    final allShapes = <List<int>>[];

    for (final seg in splitSegs) {
      if (seg.isEmpty) continue;
      final norm = _normalizeSegment(seg);
      final chunked = _chunkSubstrokes(norm);
      if (chunked.isEmpty) continue;
      allSegments.add(chunked);
      allShapes.add([1, chunked.length, 16]);
    }

    if (allSegments.isEmpty) {
      final substrokes = _splitToSubstroke(scaled);
      return PreprocessedResult(
        segments: [substrokes],
        shapes: [
          [1, substrokes.length, 16],
        ],
      );
    }

    return PreprocessedResult(segments: allSegments, shapes: allShapes);
  }

  static PreprocessedResult _preprocessCharacter(
    List<List<Map<String, dynamic>>> rawStrokes,
  ) {
    const int maxSubstrokes = 64;
    const int subLength = 16;

    final rawPoints = <double>[];
    for (int s = 0; s < rawStrokes.length; s++) {
      for (final p in rawStrokes[s]) {
        rawPoints.add((p['x'] as num).toDouble());
        rawPoints.add((p['y'] as num).toDouble());
      }
      if (s < rawStrokes.length - 1) {
        rawPoints.addAll([-1.0, -1.0]);
      }
    }

    if (rawPoints.isEmpty) {
      final zeros = List.generate(
        maxSubstrokes,
        (_) => List.filled(subLength, 0.0),
      );
      return PreprocessedResult(
        segments: [zeros],
        shapes: [
          [1, maxSubstrokes, subLength],
        ],
      );
    }

    final coords = <List<double>>[];
    for (int i = 0; i < rawPoints.length; i += 2) {
      coords.add([rawPoints[i], rawPoints[i + 1]]);
    }

    final validCoords = coords
        .where((c) => !(c[0] == -1 && c[1] == -1))
        .toList();

    double minX = double.infinity, minY = double.infinity;
    double maxX = -double.infinity, maxY = -double.infinity;
    for (final c in validCoords) {
      if (c[0] < minX) minX = c[0];
      if (c[0] > maxX) maxX = c[0];
      if (c[1] < minY) minY = c[1];
      if (c[1] > maxY) maxY = c[1];
    }

    final xRange = (maxX - minX) != 0 ? (maxX - minX) : 1.0;
    final yRange = (maxY - minY) != 0 ? (maxY - minY) : 1.0;

    final scaledList = <double>[];
    for (final c in coords) {
      if (c[0] == -1 && c[1] == -1) {
        scaledList.addAll([-1.0, -1.0]);
      } else {
        scaledList.add((c[0] - minX) / xRange);
        scaledList.add((c[1] - minY) / yRange);
      }
    }

    final substrokes = <List<double>>[];
    for (int i = 0; i < scaledList.length; i += subLength) {
      final end = min(i + subLength, scaledList.length);
      final chunk = scaledList.sublist(i, end).toList();
      while (chunk.length < subLength) {
        chunk.add(0.0);
      }
      substrokes.add(chunk);
    }

    while (substrokes.length < maxSubstrokes) {
      substrokes.add(List.filled(subLength, 0.0));
    }
    final finalSubstrokes = substrokes.take(maxSubstrokes).toList();

    return PreprocessedResult(
      segments: [finalSubstrokes],
      shapes: [
        [1, maxSubstrokes, subLength],
      ],
    );
  }

  static List<double> _extractCoordinates(
    List<List<Map<String, dynamic>>> rawStrokes,
  ) {
    final coords = <double>[];
    for (final stroke in rawStrokes) {
      for (final p in stroke) {
        coords.add((p['x'] as num).toDouble());
        coords.add((p['y'] as num).toDouble());
      }
    }
    return coords;
  }

  static List<double> _scaleCoordinates(List<double> coords) {
    if (coords.length < 2) return coords;

    final xVals = <double>[];
    final yVals = <double>[];
    for (int i = 0; i < coords.length; i += 2) {
      xVals.add(coords[i]);
      yVals.add(coords[i + 1]);
    }

    final minX = xVals.reduce(min);
    final maxX = xVals.reduce(max);
    final minY = yVals.reduce(min);
    final maxY = yVals.reduce(max);

    final width = (maxX - minX) != 0 ? (maxX - minX) : 1.0;
    final height = (maxY - minY) != 0 ? (maxY - minY) : 1.0;

    final normX = xVals.map((x) => (x - minX) / width).toList();
    final normY = yVals.map((y) => (y - minY) / height).toList();

    final result = <double>[];
    for (int i = 0; i < normX.length; i++) {
      result.add(normX[i]);
      result.add(normY[i]);
    }
    return result;
  }

  static List<List<double>> _splitToSubstroke(List<double> coords) {
    final substrokes = <List<double>>[];
    final data = List<double>.from(coords);
    while (data.length >= 16) {
      substrokes.add(data.sublist(0, 16));
      data.removeRange(0, 16);
    }
    if (data.isNotEmpty) {
      final padded = <double>[];
      padded.addAll(List.filled(16 - data.length, 0.0));
      padded.addAll(data);
      substrokes.add(padded);
    }
    return substrokes;
  }

  static List<int> _computeVerticalProjection(
    List<double> strokes, {
    int imgSize = 128,
  }) {
    final hist = List.filled(imgSize, 0);
    for (int i = 0; i < strokes.length; i += 2) {
      final x = (strokes[i] * imgSize).toInt();
      if (x >= 0 && x < imgSize) {
        hist[x]++;
      }
    }
    return hist;
  }

  static List<List<int>> _findSegments(
    List<int> hist, {
    int threshold = 0,
    int minGap = 10,
  }) {
    final segments = <List<int>>[];
    bool inGap = false;
    int start = 0;
    int gapStart = 0;

    for (int i = 0; i < hist.length; i++) {
      if (hist[i] <= threshold) {
        if (!inGap) {
          gapStart = i;
          inGap = true;
        }
      } else {
        if (inGap) {
          final gapEnd = i;
          if (gapEnd - gapStart >= minGap) {
            segments.add([start, gapStart]);
            start = gapEnd;
          }
          inGap = false;
        }
      }
    }
    if (start < hist.length) {
      segments.add([start, hist.length]);
    }
    return segments;
  }

  static List<List<double>> _splitStrokes(
    List<double> flat,
    List<List<int>> segments, {
    int imgSize = 128,
  }) {
    final out = <List<double>>[];
    for (final seg in segments) {
      final segStart = seg[0];
      final segEnd = seg[1];
      final segData = <double>[];
      for (int i = 0; i < flat.length; i += 2) {
        final x = flat[i];
        if (x >= segStart / imgSize && x <= segEnd / imgSize) {
          segData.add(flat[i]);
          segData.add(flat[i + 1]);
        }
      }
      out.add(segData);
    }
    return out;
  }

  static List<double> _normalizeSegment(List<double> segment) {
    if (segment.length < 2) return segment;

    final xs = <double>[];
    final ys = <double>[];
    for (int i = 0; i < segment.length; i += 2) {
      xs.add(segment[i]);
      ys.add(segment[i + 1]);
    }

    final minX = xs.reduce(min);
    final maxX = xs.reduce(max);
    final minY = ys.reduce(min);
    final maxY = ys.reduce(max);

    final rangeX = (maxX - minX) != 0 ? (maxX - minX) : 1.0;
    final rangeY = (maxY - minY) != 0 ? (maxY - minY) : 1.0;

    final normalized = <double>[];
    for (int i = 0; i < segment.length; i += 2) {
      normalized.add((segment[i] - minX) / rangeX);
      normalized.add((segment[i + 1] - minY) / rangeY);
    }
    return normalized;
  }

  static List<List<double>> _chunkSubstrokes(
    List<double> normalized, {
    int chunkSize = 16,
  }) {
    final chunks = <List<double>>[];
    for (int i = 0; i < normalized.length; i += chunkSize) {
      final end = min(i + chunkSize, normalized.length);
      final sub = normalized.sublist(i, end).toList();
      while (sub.length < chunkSize) {
        sub.add(0.0);
      }
      chunks.add(sub.sublist(0, chunkSize));
    }
    return chunks;
  }
}

class PreprocessedResult {
  final List<List<List<double>>> segments;
  final List<List<int>> shapes;

  const PreprocessedResult({required this.segments, required this.shapes});

  bool get isSingleSegment => segments.length == 1;
}
