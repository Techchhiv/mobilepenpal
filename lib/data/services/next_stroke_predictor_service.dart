import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:onnxruntime_v2/onnxruntime_v2.dart';

class NextStrokePredictorService {
  NextStrokePredictorService._();
  static final NextStrokePredictorService instance = NextStrokePredictorService._();

  bool _initialized = false;
  bool get isReady => _initialized;

  OrtSession? _session;
  Map<String, dynamic>? _stats;
  Map<String, dynamic>? _charToId;
  Map<String, dynamic>? _sourceToId;

  Future<void> init() async {
    if (_initialized) return;

    try {
      OrtEnv.instance.init();

      // Load mappings and stats configs
      final statsStr = await rootBundle.loadString('assets/models/bigru_runtime_stats.json');
      _stats = jsonDecode(statsStr) as Map<String, dynamic>;

      final charToIdStr = await rootBundle.loadString('assets/models/bigru_char_to_id.json');
      _charToId = jsonDecode(charToIdStr) as Map<String, dynamic>;

      final sourceToIdStr = await rootBundle.loadString('assets/models/bigru_source_to_id.json');
      _sourceToId = jsonDecode(sourceToIdStr) as Map<String, dynamic>;

      // Load ONNX model session
      final modelBytes = await rootBundle.load('assets/models/bigru_strokes.onnx');
      final options = OrtSessionOptions();
      _session = OrtSession.fromBuffer(modelBytes.buffer.asUint8List(), options);

      _initialized = true;
      dev.log('NextStrokePredictorService initialized successfully!', name: 'NextStrokePredictor');
    } catch (e, stack) {
      dev.log('Failed to initialize NextStrokePredictorService: $e', error: e, stackTrace: stack, name: 'NextStrokePredictor');
    }
  }

  void dispose() {
    _session?.release();
    _session = null;
    _initialized = false;
  }

  // ──────────────────────────────────────────────
  //  CORE PREPROCESSING PIPELINE
  // ──────────────────────────────────────────────

  List<Offset> weightedMovingAverageStroke(List<Offset> stroke, int iterations) {
    if (stroke.length < 4 || iterations <= 0) {
      return List<Offset>.from(stroke);
    }
    List<Offset> pts = List<Offset>.from(stroke);
    for (int iter = 0; iter < iterations; iter++) {
      final next = List<Offset>.from(pts);
      for (int i = 1; i < pts.length - 1; i++) {
        final dx = (pts[i - 1].dx + 2.0 * pts[i].dx + pts[i + 1].dx) / 4.0;
        final dy = (pts[i - 1].dy + 2.0 * pts[i].dy + pts[i + 1].dy) / 4.0;
        next[i] = Offset(dx, dy);
      }
      pts = next;
    }
    return pts;
  }

  Map<String, dynamic> normalizeStrokesWithTransform(List<List<Offset>> strokes, double inputScale) {
    final allPoints = strokes.expand((s) => s).toList();
    if (allPoints.isEmpty) {
      return {
        'normalized': <List<Offset>>[],
        'centroid': Offset.zero,
        'scale': 1.0,
      };
    }

    double sumX = 0;
    double sumY = 0;
    for (final p in allPoints) {
      sumX += p.dx;
      sumY += p.dy;
    }
    final centroid = Offset(sumX / allPoints.length, sumY / allPoints.length);

    double maxDist = 0.0;
    for (final p in allPoints) {
      final dx = (p.dx - centroid.dx).abs();
      final dy = (p.dy - centroid.dy).abs();
      if (dx > maxDist) maxDist = dx;
      if (dy > maxDist) maxDist = dy;
    }

    final baseScale = maxDist < 1e-5 ? 1.0 : 1.0 / maxDist;
    final scale = baseScale * inputScale;

    final normalized = strokes.map((stroke) {
      return stroke.map((p) => Offset((p.dx - centroid.dx) * scale, (p.dy - centroid.dy) * scale)).toList();
    }).toList();

    return {
      'normalized': normalized,
      'centroid': centroid,
      'scale': scale,
      'first_raw_point': allPoints.first,
      'last_raw_point': allPoints.last,
    };
  }

  List<Offset> removeClosePoints(List<Offset> stroke, double step) {
    if (stroke.length < 2) return stroke;
    final output = [stroke[0]];
    for (int i = 1; i < stroke.length; i++) {
      final p = stroke[i];
      final prev = output.last;
      final dist = (p - prev).distance;
      if (dist > step) {
        output.add(p);
      }
    }
    return output;
  }

  List<Offset> resamplePoints(List<Offset> stroke, double step) {
    if (stroke.length < 2) return stroke;

    final cumulative = <double>[0.0];
    double acc = 0.0;
    for (int i = 1; i < stroke.length; i++) {
      acc += (stroke[i] - stroke[i - 1]).distance;
      cumulative.add(acc);
    }

    final total = cumulative.last;
    if (total < 1e-8) {
      return [stroke.first];
    }

    final numSteps = (total / step).toInt().clamp(1, 10000);
    final resampled = <Offset>[];

    for (int s = 0; s <= numSteps; s++) {
      final target = (total * s) / numSteps;
      int lo = 0, hi = cumulative.length - 1;
      while (lo < hi) {
        final mid = (lo + hi) >> 1;
        if (cumulative[mid] >= target) {
          hi = mid;
        } else {
          lo = mid + 1;
        }
      }
      final idx = lo;
      if (idx == 0) {
        resampled.add(stroke.first);
      } else {
        final prevDist = cumulative[idx - 1];
        final nextDist = cumulative[idx];
        final segLen = nextDist - prevDist;
        final t = segLen <= 0 ? 0.0 : (target - prevDist) / segLen;
        final a = stroke[idx - 1];
        final b = stroke[idx];
        resampled.add(Offset(
          a.dx + (b.dx - a.dx) * t,
          a.dy + (b.dy - a.dy) * t,
        ));
      }
    }
    return resampled;
  }

  List<List<double>> strokesToDeltas(List<List<Offset>> strokes, {bool includeEnd = true}) {
    if (strokes.isEmpty) return [];

    final seqData = <List<double>>[];
    Offset prev = strokes.first.first;

    for (int strokeIdx = 0; strokeIdx < strokes.length; strokeIdx++) {
      final stroke = strokes[strokeIdx];
      if (stroke.isEmpty) continue;

      for (int pointIdx = 0; pointIdx < stroke.length; pointIdx++) {
        if (strokeIdx == 0 && pointIdx == 0) continue;

        final p = stroke[pointIdx];
        final dx = p.dx - prev.dx;
        final dy = p.dy - prev.dy;
        final penState = pointIdx == 0 ? [0.0, 1.0, 0.0] : [1.0, 0.0, 0.0];
        seqData.add([dx, dy, ...penState]);
        prev = p;
      }
      if (stroke.length == 1) {
        seqData.add([0.0, 0.0, 1.0, 0.0, 0.0]);
      }
    }

    if (includeEnd) {
      seqData.add([0.0, 0.0, 0.0, 0.0, 1.0]);
    }
    return seqData;
  }

  List<List<double>> standardizeDeltas(List<List<double>> seq, List<double> mean, List<double> std) {
    return seq.map((row) {
      final dx = (row[0] - mean[0]) / (std[0] + 1e-6);
      final dy = (row[1] - mean[1]) / (std[1] + 1e-6);
      return [dx, dy, row[2], row[3], row[4]];
    }).toList();
  }

  void processStrokeIntoChunks(
    List<List<double>> strokePoints,
    List<List<List<double>>> outputList,
    int chunkSize,
    List<int> countList,
  ) {
    for (int i = 0; i < strokePoints.length; i += chunkSize) {
      final end = (i + chunkSize < strokePoints.length) ? i + chunkSize : strokePoints.length;
      final chunk = strokePoints.sublist(i, end);
      final realCount = chunk.length;
      final paddedChunk = List<List<double>>.from(chunk);
      while (paddedChunk.length < chunkSize) {
        paddedChunk.add([0.0, 0.0, 0.0, 0.0, 0.0]);
      }
      outputList.add(paddedChunk);
      countList.add(realCount);
    }
  }

  SplitResult splitAndPadStrokes(List<List<double>> seq, int chunkSize) {
    final substrokes = <List<List<double>>>[];
    final validCounts = <int>[];

    if (seq.isEmpty) return SplitResult(substrokes, validCounts);

    var currentStroke = <List<double>>[];

    for (final row in seq) {
      final isLift = row[3] == 1.0;
      if (isLift && currentStroke.isNotEmpty) {
        processStrokeIntoChunks(currentStroke, substrokes, chunkSize, validCounts);
        currentStroke = [];
      }
      currentStroke.add(row);
      if (row[4] == 1.0) {
        break;
      }
    }

    if (currentStroke.isNotEmpty) {
      processStrokeIntoChunks(currentStroke, substrokes, chunkSize, validCounts);
    }

    return SplitResult(substrokes, validCounts);
  }

  Map<String, dynamic> canvasStrokesToSeed({
    required List<List<Offset>> rawStrokes,
    required Map<String, dynamic> stats,
    required bool smoothInput,
    required String smoothingStrength,
  }) {
    final cleanStrokes = <List<Offset>>[];
    for (final stroke in rawStrokes) {
      if (stroke.length >= 2) {
        cleanStrokes.add(stroke);
      }
    }
    if (cleanStrokes.isEmpty) {
      throw Exception("Please draw at least one stroke first.");
    }

    final smoothedStrokes = <List<Offset>>[];
    if (smoothInput) {
      final iterations = smoothingStrength == "Light" ? 1 : smoothingStrength == "Strong" ? 3 : 2;
      for (final s in cleanStrokes) {
        smoothedStrokes.add(weightedMovingAverageStroke(s, iterations));
      }
    } else {
      smoothedStrokes.addAll(cleanStrokes);
    }

    final resampleStep = (stats["resample_step"] as num).toDouble();
    final chunkSize = stats["chunk_size"] as int;
    final deltaMean = List<double>.from((stats["delta_mean"] as List).map((e) => (e as num).toDouble()));
    final deltaStd = List<double>.from((stats["delta_std"] as List).map((e) => (e as num).toDouble()));
    final inputScale = (stats["gui_partial_input_scale"] as num).toDouble();

    final normData = normalizeStrokesWithTransform(smoothedStrokes, inputScale);
    final normalized = normData["normalized"] as List<List<Offset>>;

    final resampled = <List<Offset>>[];
    for (final s in normalized) {
      final r1 = removeClosePoints(s, resampleStep);
      final r2 = resamplePoints(r1, resampleStep);
      resampled.add(r2);
    }

    final seq = strokesToDeltas(resampled, includeEnd: false);
    if (seq.length < 2) {
      throw Exception("The input is too short. Please draw a little more.");
    }

    final scaled = standardizeDeltas(seq, deltaMean, deltaStd);
    final split = splitAndPadStrokes(scaled, chunkSize);

    final totalResampledDeltas = seq.length;
    final keptChunks = split.chunks.length;
    final validLastCount = split.validCounts.isNotEmpty ? split.validCounts.last : chunkSize;
    final keptDeltas = (keptChunks > 1 && validLastCount == chunkSize)
        ? keptChunks * chunkSize
        : (keptChunks == 1 ? validLastCount : totalResampledDeltas);
    final keptRatio = totalResampledDeltas > 0
        ? (keptDeltas / totalResampledDeltas).clamp(0.0, 1.0)
        : 1.0;

    final transform = {
      'scale': normData['scale'],
      'centroid': normData['centroid'],
      'first_raw_point': normData['first_raw_point'],
      'last_raw_point': normData['last_raw_point'],
    };

    return {
      'chunks': split.chunks,
      'valid_counts': split.validCounts,
      'transform': transform,
      'kept_ratio': keptRatio,
    };
  }

  Map<String, dynamic> chooseModelSeed({
    required List<List<List<double>>> seed,
    required List<int> validCounts,
    required String mode,
    required int chunkSize,
  }) {
    final seedChunks = seed.length;
    final lastValid = validCounts.isNotEmpty ? validCounts.last : chunkSize;

    final result = {
      "model_seed": seed,
      "mode_used": "direct",
      "start_row": seedChunks * chunkSize,
      "anchor_row": seedChunks * chunkSize - 1,
      "align_to_user_end": false,
      "context_chunks": seedChunks,
      "skipped_rows_in_predicted_chunk": 0,
    };

    final shouldComplete = mode == "Auto complete current chunk" &&
        seedChunks >= 2 &&
        lastValid > 0 &&
        lastValid < chunkSize;

    if (shouldComplete) {
      final contextSeed = seed.sublist(0, seedChunks - 1);
      final contextChunks = contextSeed.length;
      final startRow = contextChunks * chunkSize + lastValid;
      result["model_seed"] = contextSeed;
      result["mode_used"] = "complete_current_chunk";
      result["start_row"] = startRow;
      result["anchor_row"] = startRow - 1;
      result["align_to_user_end"] = true;
      result["context_chunks"] = contextChunks;
      result["skipped_rows_in_predicted_chunk"] = lastValid;
    }

    return result;
  }

  // ──────────────────────────────────────────────
  //  MODEL RUN & AUTOREGRESSIVE GENERATION
  // ──────────────────────────────────────────────

  List<double> softmax(List<double> logits) {
    double maxVal = logits[0];
    for (int i = 1; i < logits.length; i++) {
      if (logits[i] > maxVal) maxVal = logits[i];
    }
    final expVals = logits.map((val) => math.exp(val - maxVal)).toList();
    final sumExp = expVals.reduce((a, b) => a + b);
    return expVals.map((val) => val / sumExp).toList();
  }

  List<List<double>> extractLastXy(dynamic predXy, int T, int L) {
    final batch = predXy as List;
    final seq = batch[0] as List;
    final lastStep = seq[T - 1] as List;
    final out = <List<double>>[];
    for (int i = 0; i < L; i++) {
      final xy = lastStep[i] as List;
      out.add([
        (xy[0] as num).toDouble(),
        (xy[1] as num).toDouble(),
      ]);
    }
    return out;
  }

  List<List<double>> extractLastPen(dynamic predPen, int T, int L) {
    final batch = predPen as List;
    final seq = batch[0] as List;
    final lastStep = seq[T - 1] as List;
    final out = <List<double>>[];
    for (int i = 0; i < L; i++) {
      final pen = lastStep[i] as List;
      out.add([
        (pen[0] as num).toDouble(),
        (pen[1] as num).toDouble(),
        (pen[2] as num).toDouble(),
      ]);
    }
    return out;
  }

  Future<List<List<List<double>>>> generateCharacter({
    required OrtSession session,
    required List<List<List<double>>> seedSequence,
    required int charId,
    required int sourceId,
    required int chunkSize,
    int maxNewSubstrokes = 30,
  }) async {
    final currentSeq = List<List<List<double>>>.from(seedSequence);
    final fullGeneration = List<List<List<double>>>.from(seedSequence);

    final liftThreshold = 0.25;
    final endThreshold = 0.40;

    for (int step = 0; step < maxNewSubstrokes; step++) {
      final seqLen = currentSeq.length;

      final substrokesFlat = <double>[];
      for (final chunk in currentSeq) {
        for (final row in chunk) {
          substrokesFlat.addAll(row);
        }
      }

      final substrokesTensor = OrtValueTensor.createTensorWithDataList(
        Float32List.fromList(substrokesFlat),
        [1, seqLen, chunkSize, 5],
      );

      final lengthsTensor = OrtValueTensor.createTensorWithDataList(
        Int64List.fromList([seqLen]),
        [1],
      );

      final charIdsTensor = OrtValueTensor.createTensorWithDataList(
        Int64List.fromList([charId]),
        [1],
      );

      final sourceIdsTensor = OrtValueTensor.createTensorWithDataList(
        Int64List.fromList([sourceId]),
        [1],
      );

      final inputs = {
        'substrokes': substrokesTensor,
        'lengths': lengthsTensor,
        'char_ids': charIdsTensor,
        'source_ids': sourceIdsTensor,
      };

      final runOptions = OrtRunOptions();
      final outputs = await session.runAsync(runOptions, inputs);

      substrokesTensor.release();
      lengthsTensor.release();
      charIdsTensor.release();
      sourceIdsTensor.release();
      runOptions.release();

      if (outputs == null || outputs.isEmpty) {
        throw Exception('Model returned no output');
      }

      final predXyVal = outputs[0]?.value;
      final predPenVal = outputs[1]?.value;

      final lastXy = extractLastXy(predXyVal, seqLen, chunkSize);
      final lastPenLogits = extractLastPen(predPenVal, seqLen, chunkSize);

      final newSubstroke = <List<double>>[];
      int? endPos;

      for (int i = 0; i < chunkSize; i++) {
        final xy = lastXy[i];
        final logits = lastPenLogits[i];
        final probs = softmax(logits);

        int penIdx = 0;
        double maxProb = probs[0];
        for (int p = 1; p < 3; p++) {
          if (probs[p] > maxProb) {
            maxProb = probs[p];
            penIdx = p;
          }
        }

        if (probs[1] > liftThreshold) {
          penIdx = 1;
        }
        if (probs[2] > endThreshold) {
          penIdx = 2;
        }

        if (penIdx == 2 && endPos == null) {
          endPos = i;
        }

        final penOneHot = [0.0, 0.0, 0.0];
        penOneHot[penIdx] = 1.0;

        newSubstroke.add([xy[0], xy[1], ...penOneHot]);
      }

      if (endPos != null) {
        for (int i = endPos + 1; i < chunkSize; i++) {
          newSubstroke[i] = [0.0, 0.0, 0.0, 0.0, 0.0];
        }
        fullGeneration.add(newSubstroke);
        break;
      }

      fullGeneration.add(newSubstroke);
      currentSeq.add(newSubstroke);
    }

    return fullGeneration;
  }

  // ──────────────────────────────────────────────
  //  POST-PROCESSING & ALIGNMENT
  // ──────────────────────────────────────────────

  CanvasPointsResult tensorToCanvasPoints({
    required List<List<List<double>>> generated,
    required List<double> deltaMean,
    required List<double> deltaStd,
    required Map<String, dynamic> transform,
  }) {
    final flat = <List<double>>[];
    for (final chunk in generated) {
      for (final row in chunk) {
        flat.add(row);
      }
    }

    final points = <Offset>[];
    final states = <List<double>>[];

    final scale = transform['scale'] as double;
    final normScale = scale < 1e-6 ? 1e-6 : scale;
    final startOffset = transform['first_raw_point'] as Offset;

    Offset runningPoint = startOffset;

    for (final row in flat) {
      final state = [row[2], row[3], row[4]];
      states.add(state);

      final isPadding = (state[0].abs() + state[1].abs() + state[2].abs()) < 1e-6;

      double dx = 0.0;
      double dy = 0.0;

      if (!isPadding) {
        dx = (row[0] * (deltaStd[0] + 1e-6) + deltaMean[0]) / normScale;
        dy = (row[1] * (deltaStd[1] + 1e-6) + deltaMean[1]) / normScale;
      }

      runningPoint = Offset(runningPoint.dx + dx, runningPoint.dy + dy);
      points.add(runningPoint);
    }

    return CanvasPointsResult(points, states);
  }

  List<Offset> alignPredictionToUserEnd({
    required List<Offset> points,
    required Map<String, dynamic> startInfo,
    required Map<String, dynamic> transform,
  }) {
    final alignToUserEnd = startInfo["align_to_user_end"] as bool;
    if (!alignToUserEnd) return points;

    final anchorRow = startInfo["anchor_row"] as int;
    if (anchorRow < 0 || anchorRow >= points.length) return points;

    final userEnd = (transform["last_raw_point"] ?? transform["first_raw_point"]) as Offset;
    final offset = userEnd - points[anchorRow];

    final aligned = List<Offset>.from(points);
    for (int i = anchorRow; i < aligned.length; i++) {
      aligned[i] = aligned[i] + offset;
    }

    return aligned;
  }

  List<List<Offset>> makeSegments({
    required List<Offset> points,
    required List<List<double>> states,
    required int startI,
    required int endI,
    bool stopAtEnd = true,
  }) {
    final segments = <List<Offset>>[];
    var current = <Offset>[];

    final limit = endI < points.length ? endI : points.length;

    for (int i = startI; i < limit; i++) {
      final cur = points[i];
      final prev = i == 0 ? Offset.zero : points[i - 1];
      final state = states[i];

      final sumState = state[0].abs() + state[1].abs() + state[2].abs();
      if (sumState < 1e-6) continue;

      int pen = 0;
      double maxVal = state[0];
      for (int p = 1; p < 3; p++) {
        if (state[p] > maxVal) {
          maxVal = state[p];
          pen = p;
        }
      }

      if (pen == 0) {
        if (current.isEmpty) {
          current = [prev, cur];
        } else {
          current.add(cur);
        }
      } else if (pen == 1) {
        if (current.length > 1) {
          segments.add(current);
        }
        current = [];
      } else if (pen == 2) {
        if (current.length > 1) {
          segments.add(current);
        }
        current = [];
        if (stopAtEnd) {
          break;
        }
      }
    }

    if (current.length > 1) {
      segments.add(current);
    }

    return segments;
  }

  // ──────────────────────────────────────────────
  //  PUBLIC ENDPOINT
  // ──────────────────────────────────────────────

  Future<List<List<Offset>>> predictNextStrokes({
    required List<List<Offset>> userStrokes,
    required String char,
    String source = "synthetic",
    bool smoothInput = true,
    String smoothingStrength = "Medium",
    String mode = "Auto complete current chunk",
    double canvasSize = 320.0,
    void Function(double keptRatio)? onKeptRatio,
  }) async {
    if (!_initialized) {
      await init();
      if (!_initialized) {
        throw Exception("Predictor service is not ready.");
      }
    }

    final charIdVal = _charToId?[char.trim()];
    if (charIdVal == null) {
      throw Exception("Selected character '$char' is not in mapping database.");
    }
    final charId = charIdVal as int;

    final sourceIdVal = _sourceToId?[source.trim()];
    if (sourceIdVal == null) {
      throw Exception("Selected style/source '$source' is not in database.");
    }
    final sourceId = sourceIdVal as int;

    final chunkSize = _stats?["chunk_size"] as int;
    final deltaMean = List<double>.from((_stats?["delta_mean"] as List).map((e) => (e as num).toDouble()));
    final deltaStd = List<double>.from((_stats?["delta_std"] as List).map((e) => (e as num).toDouble()));

    // 1. Process canvas inputs to model seed format
    final seedData = canvasStrokesToSeed(
      rawStrokes: userStrokes,
      stats: _stats!,
      smoothInput: smoothInput,
      smoothingStrength: smoothingStrength,
    );

    final seed = seedData['chunks'] as List<List<List<double>>>;
    final validCounts = seedData['valid_counts'] as List<int>;
    final transform = seedData['transform'] as Map<String, dynamic>;
    final keptRatio = (seedData['kept_ratio'] as num?)?.toDouble() ?? 1.0;
    onKeptRatio?.call(keptRatio);

    // 2. Select starting sequence seed
    final startInfo = chooseModelSeed(
      seed: seed,
      validCounts: validCounts,
      mode: mode,
      chunkSize: chunkSize,
    );

    final modelSeed = startInfo["model_seed"] as List<List<List<double>>>;

    // 3. Autoregressive prediction
    final generated = await generateCharacter(
      session: _session!,
      seedSequence: modelSeed,
      charId: charId,
      sourceId: sourceId,
      chunkSize: chunkSize,
    );

    // 4. Transform back to screen coordinates
    final canvasResult = tensorToCanvasPoints(
      generated: generated,
      deltaMean: deltaMean,
      deltaStd: deltaStd,
      transform: transform,
    );

    final alignedPoints = alignPredictionToUserEnd(
      points: canvasResult.points,
      startInfo: startInfo,
      transform: transform,
    );

    final startRow = startInfo["start_row"] as int;
    final anchorPoint = (startRow > 0 && startRow - 1 < alignedPoints.length)
        ? alignedPoints[startRow - 1]
        : (alignedPoints.isNotEmpty ? alignedPoints.first : Offset.zero);

    // 5. Build segments from predictions (row start_row to end)
    final predSegments = makeSegments(
      points: alignedPoints,
      states: canvasResult.states,
      startI: startRow,
      endI: alignedPoints.length,
      stopAtEnd: true,
    );

    return fitSegmentsToBox(predSegments, anchorPoint, canvasSize, canvasSize, 15.0);
  }

  List<List<Offset>> fitSegmentsToBox(
    List<List<Offset>> segments,
    Offset anchor,
    double width,
    double height,
    double padding,
  ) {
    if (segments.isEmpty) return segments;

    final allPoints = segments.expand((s) => s).toList();
    if (allPoints.isEmpty) return segments;

    double overallScale = 1.0;

    for (final p in allPoints) {
      // X boundary check
      final dx = p.dx - anchor.dx;
      if (dx > 0) {
        final limit = width - padding - anchor.dx;
        if (limit > 0 && dx > limit) {
          overallScale = math.min(overallScale, limit / dx);
        }
      } else if (dx < 0) {
        final limit = padding - anchor.dx;
        if (limit < 0 && dx < limit) {
          overallScale = math.min(overallScale, limit / dx);
        }
      }

      // Y boundary check
      final dy = p.dy - anchor.dy;
      if (dy > 0) {
        final limit = height - padding - anchor.dy;
        if (limit > 0 && dy > limit) {
          overallScale = math.min(overallScale, limit / dy);
        }
      } else if (dy < 0) {
        final limit = padding - anchor.dy;
        if (limit < 0 && dy < limit) {
          overallScale = math.min(overallScale, limit / dy);
        }
      }
    }

    // Apply scaling relative to anchor point to keep prediction connected
    if (overallScale < 0.999) {
      return segments.map((stroke) {
        return stroke.map((p) {
          return Offset(
            anchor.dx + (p.dx - anchor.dx) * overallScale,
            anchor.dy + (p.dy - anchor.dy) * overallScale,
          );
        }).toList();
      }).toList();
    }

    return segments;
  }
}

class SplitResult {
  final List<List<List<double>>> chunks;
  final List<int> validCounts;
  SplitResult(this.chunks, this.validCounts);
}

class CanvasPointsResult {
  final List<Offset> points;
  final List<List<double>> states;
  CanvasPointsResult(this.points, this.states);
}
