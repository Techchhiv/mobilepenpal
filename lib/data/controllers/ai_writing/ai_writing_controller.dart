import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_drawing_board/flutter_drawing_board.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mobilepenpal/core/utils/ai_stroke_feedback_util.dart';
import 'package:mobilepenpal/core/utils/drawing_points_util.dart';
import 'package:mobilepenpal/core/utils/stroke_transform_util.dart';
import 'package:mobilepenpal/data/controllers/home/home_controller.dart';
import 'package:mobilepenpal/data/controllers/shop/shop_controller.dart';
import 'package:mobilepenpal/data/controllers/world/stage_audio_controller.dart';
import 'package:mobilepenpal/data/controllers/world/stage_animation_controller.dart';
import 'package:mobilepenpal/data/models/api_response.dart';
import 'package:mobilepenpal/data/models/student/student.dart';
import 'package:mobilepenpal/data/services/drawing_evaluation_service.dart';
import 'package:mobilepenpal/data/services/next_stroke_predictor_service.dart';
import 'package:mobilepenpal/data/services/onnx_inference_service.dart';
import 'package:mobilepenpal/data/services/world_service.dart';
import 'package:mobilepenpal/presentation/widgets/ai_writing/stitch_debug_painter.dart';

class AiWritingController extends GetxController
    with GetTickerProviderStateMixin {
  AiWritingController({required this.characters, required this.repeatCount});

  // ── Config: guide progress behaviour ───────────────────────────────────
  // true  → guide fill updates automatically after every pen-lift
  // false → guide fill only updates when the user taps Hint or has AI toggle ON
  static const bool alwaysUpdateGuideProgress = true;

  final List<String> characters;
  final int repeatCount;

  // ── Session state ──────────────────────────────────────────────────────
  final charIndex = 0.obs;
  final rep = 0.obs;
  final isSubmitting = false.obs;
  final isLoading = true.obs;
  final attemptLeft = 3.obs;
  final repResults = <bool?>[].obs;

  // ── Session-wide statistics & rewards ──────────────────────────────
  final totalCorrect = 0.obs;
  final totalAttempted = 0.obs;
  final earnedCoins = 0.obs;
  static const int _coinsPerCorrect = 2;

  final attempts = <Map<String, dynamic>>[].obs;
  final _charToExerciseId = <String, int>{};

  final GetStorage _box = GetStorage();
  final WorldService _worldService = WorldService();
  final DrawingEvaluationService _evalService = DrawingEvaluationService();

  // ── Drawing state ──────────────────────────────────────────────────────
  final drawingController = DrawingController();

  // ── Raw strokes coordinate capture ─────────────────────────────────────
  final List<List<Map<String, dynamic>>> _rawStrokes = [];
  List<Map<String, dynamic>>? _currentStroke;

  // ── Canvas size ────────────────────────────────────────────────────────
  double _canvasSize = 340.0;
  double _lastCanvasSizeForTemplate = 0.0;
  double get canvasSize => _canvasSize;
  set canvasSize(double value) {
    _canvasSize = value;
    // Recompute canvas-sized template when canvas size changes significantly
    if ((_canvasSize - _lastCanvasSizeForTemplate).abs() > 1) {
      _refreshCanvasTemplate();
    }
  }

  // ── Canvas-sized template strokes (for validation) ─────────────────────
  List<List<Offset>> canvasTemplateStrokesPx = [];

  // ── Strokes database ───────────────────────────────────────────────────
  Map<String, dynamic>? _strokesDb;

  // ── Mini shadow guide paths ────────────────────────────────────────────
  final miniGuidePaths = <List<Offset>>[].obs;
  final guideStrokesPx = <List<Offset>>[].obs;

  // ── Animated guide circle ──────────────────────────────────────────────
  final guideCirclePx = Rxn<Offset>();
  late final AnimationController guideController;
  final currentGuideStrokeIndex = 0.obs;
  final isGuiding = true.obs;

  // ── Visual Feedback / Shaking Animation ────────────────────────────────
  final feedbackState = DrawFeedback.none.obs;
  final shakeOffset = 0.0.obs;
  final praiseText = ''.obs;
  final praiseFeedback = DrawFeedback.none.obs;

  // ── Progress tracking via model predictions ────────────────────────────
  final drawingProgress = 0.0.obs;
  final completedGuideStrokeCount = 0.obs;
  final currentGuideStrokeFraction = 0.0.obs;

  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  // Constants for guide animation
  final guideTotalDurationMs = 4000;
  final pauseBetweenStrokesMs = 180;
  final minStrokeDurationMs = 1500;
  final maxStrokeDurationMs = 3000;

  final List<int> _durationMsByStroke = [];
  final List<double> _lenByStroke = [];
  double _totalLenAll = 0.0;
  final List<List<double>> _cumLenByStroke = [];
  final List<double> _totalLenByStroke = [];
  Timer? _betweenStrokeTimer;
  final showStitchDebug = false.obs;

  String get currentChar => characters[charIndex.value];

  @override
  void onInit() {
    super.onInit();
    repResults.assignAll(List<bool?>.filled(repeatCount, null));
    drawingController.setStyle(color: Colors.black, strokeWidth: 6);

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _shakeAnimation =
        TweenSequence<double>([
            TweenSequenceItem(
              tween: Tween<double>(begin: 0.0, end: 12.0),
              weight: 1,
            ),
            TweenSequenceItem(
              tween: Tween<double>(begin: 12.0, end: -12.0),
              weight: 2,
            ),
            TweenSequenceItem(
              tween: Tween<double>(begin: -12.0, end: 12.0),
              weight: 2,
            ),
            TweenSequenceItem(
              tween: Tween<double>(begin: 12.0, end: 0.0),
              weight: 1,
            ),
          ]).animate(
            CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut),
          )
          ..addListener(() {
            shakeOffset.value = _shakeAnimation.value;
          });

    guideController =
        AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 1000),
          )
          ..addListener(_updateGuideCircle)
          ..addStatusListener((status) {
            if (status != AnimationStatus.completed) return;

            _advanceGuideStroke();
            if (!isGuiding.value) return;

            _betweenStrokeTimer?.cancel();
            final pause = pauseBetweenStrokesMs;

            if (pause <= 0) {
              guideController.forward(from: _guideStartFraction());
              return;
            }

            _betweenStrokeTimer = Timer(Duration(milliseconds: pause), () {
              if (!isGuiding.value) return;
              guideController.forward(from: _guideStartFraction());
            });
          });

    _loadStrokesDb();
    _loadExercisesMap();
    NextStrokePredictorService.instance.init();
  }

  Future<void> _loadExercisesMap() async {
    try {
      final response = await _worldService.getExercises();
      if (response.code == 200 && response.data != null) {
        for (final ex in response.data!) {
          _charToExerciseId[ex.character.trim()] = ex.id;
        }
      }
    } catch (e) {
      dev.log('Failed to load exercises map: $e', name: 'AiWritingController');
    }
  }

  @override
  void onClose() {
    _betweenStrokeTimer?.cancel();
    _betweenStrokeTimer = null;
    drawingController.dispose();
    guideController.dispose();
    _shakeController.dispose();
    NextStrokePredictorService.instance.dispose();
    super.onClose();
  }

  Future<void> waitForLoading() async {
    while (isLoading.value) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
    while (!NextStrokePredictorService.instance.isReady) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  // ── Load strokes.json ──────────────────────────────────────────────────
  Future<void> _loadStrokesDb() async {
    try {
      final raw = await rootBundle.loadString('assets/strokes/strokes.json');
      _strokesDb = jsonDecode(raw) as Map<String, dynamic>;
      _refreshGuide();
    } catch (e) {
      dev.log(
        'Failed to load strokes database: $e',
        name: 'AiWritingController',
      );
    } finally {
      isLoading.value = false;
    }
  }

  // ── Fit guide paths for the current character ──────────────────────────
  void _refreshGuide() {
    final items = _strokesDb?['items'] as Map<String, dynamic>?;
    final entry = items?[currentChar.trim()] as Map<String, dynamic>?;

    if (entry == null) {
      _setGuideStrokes([], []);
      _refreshCanvasTemplate();
      return;
    }

    final textPx = entry['text_px'] as List<dynamic>? ?? [];
    final pathsPx = entry['paths_px'] as List<dynamic>? ?? [];

    final letterOut = StrokeTransformUtil.readSubpathsPx(textPx);
    final strokesOut = StrokeTransformUtil.readSubpathsPx(pathsPx);

    if (letterOut.isEmpty && strokesOut.isEmpty) {
      _setGuideStrokes([], []);
      _refreshCanvasTemplate();
      return;
    }

    // ── Fit for mini guide box (100×100) ──
    final combined = <List<Offset>>[...letterOut, ...strokesOut];
    final fitted = StrokeTransformUtil.autoFitGlyphPx(
      combined,
      boardW: 100,
      boardH: 100,
      pad: 12,
      minWidthFill: 0.72,
      minHeightFill: 0.78,
    );

    final fittedLetter = fitted.take(letterOut.length).toList();
    final fittedStrokes = fitted.skip(letterOut.length).toList();

    _setGuideStrokes(fittedLetter, fittedStrokes);
    _refreshCanvasTemplate();
  }

  // ── Compute template strokes scaled to the actual drawing canvas ───────
  void _refreshCanvasTemplate() {
    _lastCanvasSizeForTemplate = _canvasSize;
    final items = _strokesDb?['items'] as Map<String, dynamic>?;
    final entry = items?[currentChar.trim()] as Map<String, dynamic>?;

    if (entry == null) {
      canvasTemplateStrokesPx = [];
      return;
    }

    final pathsPx = entry['paths_px'] as List<dynamic>? ?? [];
    final strokesOut = StrokeTransformUtil.readSubpathsPx(pathsPx);
    if (strokesOut.isEmpty) {
      canvasTemplateStrokesPx = [];
      return;
    }

    canvasTemplateStrokesPx = StrokeTransformUtil.autoFitGlyphPx(
      strokesOut,
      boardW: _canvasSize,
      boardH: _canvasSize,
      pad: 24,
      minWidthFill: 0.72,
      minHeightFill: 0.78,
    );
  }

  void _setGuideStrokes(
    List<List<Offset>> letterPx,
    List<List<Offset>> strokesPx,
  ) {
    drawingProgress.value = 0.0;
    completedGuideStrokeCount.value = 0;
    currentGuideStrokeFraction.value = 0.0;
    miniGuidePaths.assignAll(letterPx);
    final cleaned = strokesPx.where((s) => s.length >= 2).toList();
    guideStrokesPx.assignAll(cleaned);

    if (cleaned.isEmpty) {
      guideCirclePx.value = null;
      currentGuideStrokeIndex.value = 0;
      stopGuide();

      _cumLenByStroke.clear();
      _totalLenByStroke.clear();
      _durationMsByStroke.clear();
      _lenByStroke.clear();
      _totalLenAll = 0.0;
      _betweenStrokeTimer?.cancel();
      _betweenStrokeTimer = null;
      return;
    }

    _cumLenByStroke
      ..clear()
      ..addAll(cleaned.map(_buildCumLen));
    _totalLenByStroke
      ..clear()
      ..addAll(_cumLenByStroke.map((c) => c.isEmpty ? 0.0 : c.last));

    _lenByStroke
      ..clear()
      ..addAll(_totalLenByStroke);

    _totalLenAll = _lenByStroke.fold(0.0, (a, b) => a + b);

    _durationMsByStroke
      ..clear()
      ..addAll(_buildStrokeDurationsConstantTotal());

    currentGuideStrokeIndex.value = 0;
    guideCirclePx.value = cleaned.first.first;

    startGuide();
  }

  List<double> _buildCumLen(List<Offset> stroke) {
    final n = stroke.length;
    if (n == 0) return const [];
    final cum = List<double>.filled(n, 0.0);
    double acc = 0.0;
    for (int i = 1; i < n; i++) {
      acc += (stroke[i] - stroke[i - 1]).distance;
      cum[i] = acc;
    }
    return cum;
  }

  List<int> _buildStrokeDurationsConstantTotal() {
    final totalMs = guideTotalDurationMs;

    if (_lenByStroke.isEmpty || _totalLenAll <= 0) {
      return <int>[totalMs.clamp(minStrokeDurationMs, maxStrokeDurationMs)];
    }

    final out = <int>[];
    int assigned = 0;

    for (int i = 0; i < _lenByStroke.length; i++) {
      final share = _lenByStroke[i] / _totalLenAll;
      int ms = (totalMs * share).round();

      ms = ms.clamp(minStrokeDurationMs, maxStrokeDurationMs);

      out.add(ms);
      assigned += ms;
    }

    if (out.isNotEmpty) {
      final fix = totalMs - assigned;
      out[out.length - 1] = (out.last + fix).clamp(
        minStrokeDurationMs,
        maxStrokeDurationMs,
      );
    }

    return out;
  }

  int _strokeDurationMs(int idx) {
    if (idx < 0 || idx >= _durationMsByStroke.length) {
      return minStrokeDurationMs;
    }
    return _durationMsByStroke[idx];
  }

  void startGuide() {
    if (guideStrokesPx.isEmpty) return;

    _betweenStrokeTimer?.cancel();
    _betweenStrokeTimer = null;

    isGuiding.value = true;

    guideController.duration = Duration(
      milliseconds: _strokeDurationMs(currentGuideStrokeIndex.value),
    );

    guideController.forward(from: _guideStartFraction());
  }

  void stopGuide() {
    isGuiding.value = false;
    _betweenStrokeTimer?.cancel();
    _betweenStrokeTimer = null;
    guideController.stop();
  }

  void restartGuideFromStart() {
    if (guideStrokesPx.isEmpty) return;
    currentGuideStrokeIndex.value = 0;
    guideCirclePx.value = guideStrokesPx.first.isNotEmpty
        ? guideStrokesPx.first.first
        : null;
    startGuide();
  }

  void _advanceGuideStroke() {
    if (guideStrokesPx.isEmpty) return;

    final next = currentGuideStrokeIndex.value + 1;
    final minStroke = completedGuideStrokeCount.value.clamp(
      0,
      guideStrokesPx.length - 1,
    );
    currentGuideStrokeIndex.value = (next >= guideStrokesPx.length)
        ? minStroke
        : next;

    final idx = currentGuideStrokeIndex.value;
    final stroke = guideStrokesPx[idx];

    // When landing on the partially completed stroke, start from progress
    if (idx == completedGuideStrokeCount.value &&
        currentGuideStrokeFraction.value > 0.01 &&
        stroke.length >= 2 &&
        idx < _cumLenByStroke.length) {
      guideCirclePx.value = _pointAtByCumLen(
        stroke,
        _cumLenByStroke[idx],
        _totalLenByStroke[idx],
        currentGuideStrokeFraction.value,
      );
    } else {
      guideCirclePx.value = stroke.isNotEmpty ? stroke.first : null;
    }

    guideController.duration = Duration(milliseconds: _strokeDurationMs(idx));
  }

  void _updateGuideCircle() {
    if (!isGuiding.value) return;

    final idx = currentGuideStrokeIndex.value;
    if (idx < 0 || idx >= guideStrokesPx.length) return;

    final stroke = guideStrokesPx[idx];
    if (stroke.length < 2) return;

    final cum = _cumLenByStroke[idx];
    final total = _totalLenByStroke[idx];
    if (cum.length != stroke.length || total <= 0) {
      guideCirclePx.value = stroke.first;
      return;
    }

    guideCirclePx.value = _pointAtByCumLen(
      stroke,
      cum,
      total,
      guideController.value,
    );
  }

  Offset _pointAtByCumLen(
    List<Offset> pts,
    List<double> cum,
    double total,
    double t,
  ) {
    final target = total * t.clamp(0.0, 1.0);

    int lo = 0, hi = cum.length - 1;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (cum[mid] >= target) {
        hi = mid;
      } else {
        lo = mid + 1;
      }
    }

    final i = lo;
    if (i <= 0) return pts.first;

    final prevLen = cum[i - 1];
    final segLen = cum[i] - prevLen;
    if (segLen <= 0) return pts[i];

    final localT = (target - prevLen) / segLen;
    final a = pts[i - 1];
    final b = pts[i];
    return Offset(a.dx + (b.dx - a.dx) * localT, a.dy + (b.dy - a.dy) * localT);
  }

  final autoPredict = false.obs;
  final predictedSegments = <List<Offset>>[].obs;
  final hintMessage = ''.obs;
  final isHintValid = true.obs;
  final hintIssueReason = ''.obs;

  int get rawStrokesCount => _rawStrokes.length;

  void showHint() {
    _validateRealtimeHandwriting();

    if (!isHintValid.value) {
      // Drawing is messy / invalid -> do not run ONNX model, show clear guidance message
      autoPredict.value = false;
      predictedSegments.clear();
      final reason = hintIssueReason.value.isNotEmpty
          ? hintIssueReason.value.tr
          : 'feedback_scribble_detected'.tr;
      hintMessage.value = reason;
      return;
    }

    // Valid drawing -> enable hint and predict next strokes
    autoPredict.value = true;
    predictNextStrokes();
  }

  Future<void> predictNextStrokes() async {
    final validStrokes = _filterValidStrokes();

    if (validStrokes.isEmpty) {
      predictedSegments.clear();
      drawingProgress.value = 0.0;
      completedGuideStrokeCount.value = 0;
      currentGuideStrokeFraction.value = 0.0;
      _updateGuideCirclePosition();
      return;
    }

    try {
      final userStrokes = validStrokes.map((stroke) {
        return stroke
            .map(
              (p) => Offset(
                (p["x"] as num).toDouble(),
                (p["y"] as num).toDouble(),
              ),
            )
            .toList();
      }).toList();

      final predictor = NextStrokePredictorService.instance;
      final segments = await predictor.predictNextStrokes(
        userStrokes: userStrokes,
        char: currentChar,
        canvasSize: canvasSize,
      );

      // Calculate the predicted remaining path length from ONNX model
      double fullPredictedLength = 0.0;
      for (final segment in segments) {
        for (int i = 1; i < segment.length; i++) {
          fullPredictedLength += (segment[i] - segment[i - 1]).distance;
        }
      }

      List<List<Offset>> filteredSegments = [];
      if (segments.isNotEmpty) {
        final firstSeg = segments.first;
        double pathLen = 0.0;
        for (int i = 0; i < firstSeg.length - 1; i++) {
          pathLen += (firstSeg[i + 1] - firstSeg[i]).distance;
        }

        const double threshold = 30.0;
        if (pathLen < threshold) {
          if (segments.length > 1) {
            if (pathLen < 8.0) {
              filteredSegments = [segments[1]];
            } else {
              filteredSegments = [firstSeg, segments[1]];
            }
          } else {
            filteredSegments = [];
          }
        } else {
          filteredSegments = [firstSeg];
        }
      }

      predictedSegments.assignAll(filteredSegments);
      _updateProgressFromValidStrokesAndPrediction(
        validStrokes,
        fullPredictedLength,
      );
    } catch (e) {
      dev.log("Next-stroke prediction failed: $e", name: "AiWritingController");
      predictedSegments.clear();
      _updateProgressFromValidStrokesAndPrediction(validStrokes, 0.0);
    }
  }

  /// Returns user strokes that have meaningful drawn length (> 10px) and fit within
  /// the character's template stroke count, without rigid canvas pixel constraints.
  List<List<Map<String, dynamic>>> _filterValidStrokes() {
    if (_rawStrokes.isEmpty || canvasTemplateStrokesPx.isEmpty) return [];

    final validStrokes = <List<Map<String, dynamic>>>[];
    final maxCount = canvasTemplateStrokesPx.length;

    for (final stroke in _rawStrokes) {
      if (stroke.length < 3) continue;
      if (validStrokes.length >= maxCount) break;

      double uStrokeLen = 0.0;
      for (int i = 1; i < stroke.length; i++) {
        final p1 = stroke[i - 1];
        final p2 = stroke[i];
        final dx = (p2['x'] as num).toDouble() - (p1['x'] as num).toDouble();
        final dy = (p2['y'] as num).toDouble() - (p1['y'] as num).toDouble();
        uStrokeLen += Offset(dx, dy).distance;
      }

      if (uStrokeLen >= 10.0) {
        validStrokes.add(stroke);
      }
    }

    return validStrokes;
  }

  void _updateProgressFromValidStrokesAndPrediction(
    List<List<Map<String, dynamic>>> validStrokes,
    double fullPredictedLength,
  ) {
    if (validStrokes.isEmpty ||
        guideStrokesPx.isEmpty ||
        _totalLenByStroke.isEmpty) {
      drawingProgress.value = 0.0;
      completedGuideStrokeCount.value = 0;
      currentGuideStrokeFraction.value = 0.0;
      _updateGuideCirclePosition();
      return;
    }

    // Calculate drawn length across VALID user strokes
    double validUserLength = 0.0;
    for (final stroke in validStrokes) {
      for (int i = 1; i < stroke.length; i++) {
        final x1 = (stroke[i - 1]['x'] as num).toDouble();
        final y1 = (stroke[i - 1]['y'] as num).toDouble();
        final x2 = (stroke[i]['x'] as num).toDouble();
        final y2 = (stroke[i]['y'] as num).toDouble();
        validUserLength += Offset(x2 - x1, y2 - y1).distance;
      }
    }

    if (validUserLength < 15.0) {
      drawingProgress.value = 0.0;
      _syncGuideToProgress();
      return;
    }

    final totalGuideLen = _totalLenByStroke.fold(0.0, (a, b) => a + b);

    // Safeguard: fullPredictedLength < 20 only marks complete if valid user length >= 50% of character
    if (fullPredictedLength < 20.0 && validUserLength >= totalGuideLen * 0.50) {
      drawingProgress.value = 1.0;
    } else if (validUserLength + fullPredictedLength > 0) {
      drawingProgress.value =
          (validUserLength / (validUserLength + fullPredictedLength)).clamp(
            0.0,
            1.0,
          );
    } else {
      drawingProgress.value = 0.0;
    }

    _syncGuideToProgress();
  }

  void _syncGuideToProgress() {
    if (guideStrokesPx.isEmpty || _totalLenByStroke.isEmpty) {
      completedGuideStrokeCount.value = 0;
      currentGuideStrokeFraction.value = 0.0;
      _updateGuideCirclePosition();
      return;
    }

    final totalGuideLen = _totalLenByStroke.fold(0.0, (a, b) => a + b);
    if (totalGuideLen <= 0) {
      completedGuideStrokeCount.value = 0;
      currentGuideStrokeFraction.value = 0.0;
      _updateGuideCirclePosition();
      return;
    }

    final targetLen = drawingProgress.value * totalGuideLen;

    double accumulated = 0.0;
    int completed = 0;
    double fraction = 0.0;

    for (int i = 0; i < _totalLenByStroke.length; i++) {
      final strokeLen = _totalLenByStroke[i];
      if (accumulated + strokeLen <= targetLen) {
        accumulated += strokeLen;
        completed = i + 1;
      } else {
        fraction = strokeLen > 0
            ? ((targetLen - accumulated) / strokeLen).clamp(0.0, 1.0)
            : 0.0;
        break;
      }
    }

    completedGuideStrokeCount.value = completed.clamp(0, guideStrokesPx.length);
    currentGuideStrokeFraction.value = fraction;

    _updateGuideCirclePosition();
  }

  void _updateGuideCirclePosition() {
    final completed = completedGuideStrokeCount.value;
    final fraction = currentGuideStrokeFraction.value;

    if (completed < guideStrokesPx.length) {
      _betweenStrokeTimer?.cancel();
      guideController.stop();
      isGuiding.value = true;
      currentGuideStrokeIndex.value = completed;

      final stroke = guideStrokesPx[completed];
      if (stroke.length >= 2 && completed < _cumLenByStroke.length) {
        guideCirclePx.value = _pointAtByCumLen(
          stroke,
          _cumLenByStroke[completed],
          _totalLenByStroke[completed],
          fraction,
        );
      }

      guideController.duration = Duration(
        milliseconds: _strokeDurationMs(completed),
      );
      guideController.forward(from: fraction);
    } else {
      // All strokes completed – hide guide circle
      guideController.stop();
      guideCirclePx.value = null;
    }
  }

  double _guideStartFraction() {
    final idx = currentGuideStrokeIndex.value;
    if (idx == completedGuideStrokeCount.value &&
        currentGuideStrokeFraction.value > 0.01) {
      return currentGuideStrokeFraction.value;
    }
    return 0.0;
  }

  List<List<dynamic>> getPointsJson() {
    final validStrokes = _rawStrokes.where((s) => s.length >= 2).toList();
    return DrawingPointsUtil.getPointsJson(
      rawStrokes: validStrokes,
      scale: canvasSize / 340.0,
    );
  }

  String get _deviceType => DrawingPointsUtil.getDeviceType();

  // ── Actions ────────────────────────────────────────────────────────────
  void clearBoard() {
    drawingController.clear();
    _rawStrokes.clear();
    predictedSegments.clear();
    stitchDebugSegments.clear();
    drawingProgress.value = 0.0;
    completedGuideStrokeCount.value = 0;
    currentGuideStrokeFraction.value = 0.0;
    hintMessage.value = '';
    isHintValid.value = true;
    hintIssueReason.value = '';
    restartGuideFromStart();
  }

  void onNext(VoidCallback onFinished) {
    drawingController.clear();
    _rawStrokes.clear();
    predictedSegments.clear();
    stitchDebugSegments.clear();
    drawingProgress.value = 0.0;
    completedGuideStrokeCount.value = 0;
    currentGuideStrokeFraction.value = 0.0;
    hintMessage.value = '';
    isHintValid.value = true;
    hintIssueReason.value = '';
    attemptLeft.value = 3;

    final nextRep = rep.value + 1;
    if (nextRep < repeatCount) {
      rep.value = nextRep;
      _refreshGuide();
      return;
    }

    // Finished all reps for this character.
    final nextChar = charIndex.value + 1;
    if (nextChar < characters.length) {
      charIndex.value = nextChar;
      rep.value = 0;
      repResults.assignAll(List<bool?>.filled(repeatCount, null));
      _refreshGuide();
      return;
    }

    // Session complete – sync coins and notify
    _submitSessionProgress();
    onFinished();
  }

  /// Sync earned coins locally (HomeController + ShopController) and submit to backend.
  void _submitSessionProgress() {
    final coins = earnedCoins.value;

    // Update local student coin balance immediately
    if (coins > 0 && Get.isRegistered<HomeController>()) {
      try {
        final homeController = Get.find<HomeController>();
        final currentStudent = homeController.student.value;
        if (currentStudent != null) {
          final newCoin = currentStudent.coin + coins;
          final updatedStudent = Student.fromJson({
            ...currentStudent.toJson(),
            'coin': newCoin,
          });
          homeController.student.value = updatedStudent;
          _box.write('student', updatedStudent.toJson());

          if (Get.isRegistered<ShopController>()) {
            Get.find<ShopController>().totalPoints.value = newCoin;
            _box.write('adventure_points', newCoin);
          }
        }
      } catch (e) {
        dev.log(
          'Failed to update local coins: $e',
          name: 'AiWritingController',
        );
      }
    }

    _worldService
        .submitExerciseBatch(
          attempts,
          coinsEarned: coins,
          xpEarned: totalCorrect.value * 10,
        )
        .catchError((e) {
          dev.log(
            'Failed to submit session progress: $e',
            name: 'AiWritingController',
          );
          return ApiResponse<Map<String, dynamic>>(
            code: 500,
            message: 'Failed to submit progress: $e',
            data: {},
          );
        });
  }

  // ── Stitching/Gap-closing State ────────────────────────────────────────
  bool _isContinuingLastStroke = false;
  static const double _strokeMergeRatio =
      0.1; // percentage of canvas dimension (e.g. 0.045 = 4.5%, 0.1 = 10%)
  final RxList<StitchDebugSegment> stitchDebugSegments =
      <StitchDebugSegment>[].obs;

  // ── Drawing Board Handlers ─────────────────────────────────────────────
  void onPointerDown(PointerDownEvent e) {
    stopGuide();
    guideCirclePx.value = null;

    final now = DateTime.now().millisecondsSinceEpoch;
    final point = {
      "x": e.localPosition.dx,
      "y": e.localPosition.dy,
      "time": now,
    };

    // Check if we should stitch this new stroke with the last stroke
    if (_rawStrokes.isNotEmpty) {
      final lastStroke = _rawStrokes.last;
      if (lastStroke.isNotEmpty) {
        final lastPoint = lastStroke.last;
        final dx = e.localPosition.dx - (lastPoint["x"] as num).toDouble();
        final dy = e.localPosition.dy - (lastPoint["y"] as num).toDouble();
        final distSq = dx * dx + dy * dy;

        final mergeThresholdPx = canvasSize * _strokeMergeRatio;
        if (distSq < mergeThresholdPx * mergeThresholdPx) {
          _isContinuingLastStroke = true;
          if (showStitchDebug.value) {
            stitchDebugSegments.add(
              StitchDebugSegment(
                from: Offset(
                  (lastPoint["x"] as num).toDouble(),
                  (lastPoint["y"] as num).toDouble(),
                ),
                to: Offset(e.localPosition.dx, e.localPosition.dy),
                radius: mergeThresholdPx,
              ),
            );
          }
          _currentStroke = lastStroke;
          _currentStroke!.add(point);
          return;
        }
      }
    }

    _isContinuingLastStroke = false;
    _currentStroke = [point];
  }

  void onPointerMove(PointerMoveEvent e) {
    if (_currentStroke == null) return;
    if (_currentStroke!.isNotEmpty) {
      final lastPoint = _currentStroke!.last;
      final dx = e.localPosition.dx - (lastPoint["x"] as num).toDouble();
      final dy = e.localPosition.dy - (lastPoint["y"] as num).toDouble();
      // Filter out duplicate or sub-pixel noise points closer than 1.5px
      if (dx * dx + dy * dy < 2.25) return;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    _currentStroke!.add({
      "x": e.localPosition.dx,
      "y": e.localPosition.dy,
      "time": now,
    });
  }

  void onPointerUp(PointerUpEvent e) {
    // Only accept strokes with at least 2 points (discarding 1-point tap specks)
    if (_currentStroke != null && _currentStroke!.length >= 2) {
      if (!_isContinuingLastStroke) {
        _rawStrokes.add(List<Map<String, dynamic>>.from(_currentStroke!));
      }
    }
    _currentStroke = null;
    _isContinuingLastStroke = false;

    // Clear hint guide after finger is lifted
    autoPredict.value = false;
    predictedSegments.clear();

    // Trigger background ONNX AI prediction, smooth guide sync, and real-time validation
    predictNextStrokes();
    _validateRealtimeHandwriting();
  }

  // ── Real-time Handwriting Validation & Top Guide Sync ────────────────
  void _validateRealtimeHandwriting() {
    final validUserStrokes = _rawStrokes.where((s) => s.length >= 2).toList();
    if (validUserStrokes.isEmpty || canvasTemplateStrokesPx.isEmpty) {
      hintMessage.value = '';
      isHintValid.value = true;
      hintIssueReason.value = '';
      completedGuideStrokeCount.value = 0;
      currentGuideStrokeFraction.value = 0.0;
      _updateGuideCirclePosition();
      return;
    }

    final progressResult = AiStrokeFeedbackUtil.evaluateDrawingProgress(
      userRawStrokes: validUserStrokes,
      templateStrokesPx: canvasTemplateStrokesPx,
    );

    // Synchronize top guide card progress and circle position
    completedGuideStrokeCount.value = progressResult.completedStrokes.clamp(
      0,
      guideStrokesPx.length,
    );
    currentGuideStrokeFraction.value = progressResult.activeStrokeFraction
        .clamp(0.0, 1.0);
    _updateGuideCirclePosition();

    if (progressResult.hasError) {
      // Mistake detected -> freeze guide at mistake point & show guidance message
      isHintValid.value = false;
      final reason = progressResult.errorReason ?? 'feedback_scribble_detected';
      hintIssueReason.value = reason;
      hintMessage.value = reason.tr;
    } else {
      // Valid progress -> advance guide smoothly without error banner
      isHintValid.value = true;
      hintIssueReason.value = '';
      hintMessage.value = '';
    }
  }

  // ── AI check ───────────────────────────────────────────────────────────
  String getModelTypeForChar(String char) {
    const consonantsSet = {
      'ក',
      'ខ',
      'គ',
      'ឃ',
      'ង',
      'ច',
      'ឆ',
      'ជ',
      'ឈ',
      'ញ',
      'ដ',
      'ឋ',
      'ឌ',
      'ឍ',
      'ណ',
      'ត',
      'ថ',
      'ទ',
      'ធ',
      'ន',
      'ប',
      'ផ',
      'ព',
      'ភ',
      'ម',
      'យ',
      'រ',
      'ល',
      'វ',
      'ស',
      'ហ',
      'ឡ',
      'អ',
    };
    const independentVowelsSet = {
      'ឥ',
      'ឦ',
      'ឧ',
      'ឩ',
      'ឪ',
      'ឫ',
      'ឬ',
      'ឭ',
      'ឮ',
      'ឯ',
      'ឰ',
      'ឱ',
      'ឲ',
      'ឳ',
    };
    const dependentVowelsSet = {
      'ា',
      'ិ',
      'ី',
      'ឹ',
      'ឺ',
      'ុ',
      'ូ',
      'ួ',
      'ើ',
      'ឿ',
      'ៀ',
      'េ',
      'ែ',
      'ៃ',
      'ោ',
      'ៅ',
      'ុំ',
      'ំ',
      'ាំ',
      'ះ',
      'ិះ',
      'ុះ',
      'េះ',
      'ោះ',
    };
    const numbersSet = {'០', '១', '២', '៣', '៤', '៥', '៦', '៧', '៨', '៩'};

    final trimChar = char.trim();
    if (consonantsSet.contains(trimChar)) return 'consonant';
    if (independentVowelsSet.contains(trimChar)) return 'independent_vowel';
    if (dependentVowelsSet.contains(trimChar)) return 'dependent_vowel';
    if (numbersSet.contains(trimChar)) return 'digit';
    return 'consonant';
  }

  Map<String, dynamic> _getXYStrokeWithTime(String modelType) {
    final s = canvasSize / 340.0;
    final validStrokes = _rawStrokes
        .where((stroke) => stroke.length >= 2)
        .toList();

    return {
      "strokes": validStrokes
          .map(
            (stroke) => {
              "points": stroke
                  .map(
                    (p) => {
                      "x": (p["x"] as num).toDouble() / s,
                      "y": (p["y"] as num).toDouble() / s,
                      "time": (p["time"] as num?)?.toInt(),
                    },
                  )
                  .toList(),
            },
          )
          .toList(),
      "model_type": modelType,
    };
  }

  bool _isDrawingCorrect(String prediction, String expected) {
    final p = prediction.trim();
    final e = expected.trim();
    if (p == e) return true;

    const arabicToKhmer = {
      '0': '០',
      '1': '១',
      '2': '២',
      '3': '៣',
      '4': '៤',
      '5': '៥',
      '6': '៦',
      '7': '៧',
      '8': '៨',
      '9': '៩',
    };

    final normP = arabicToKhmer[p] ?? p;
    final normE = arabicToKhmer[e] ?? e;
    return normP == normE;
  }

  Future<void> checkDrawingAndSubmit(VoidCallback onFinished) async {
    final validStrokes = _rawStrokes.where((s) => s.length >= 2).toList();
    if (validStrokes.isEmpty) {
      Get.snackbar(
        'warning'.tr,
        'Please draw the character before submitting!',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isSubmitting.value = true;
    stopGuide();
    guideCirclePx.value = null;

    try {
      bool isCorrect = false;
      String? strokeHint;
      final expected = currentChar.trim();
      final modelType = getModelTypeForChar(expected);
      final isSupported = OnnxInferenceService.instance.supportsCharacter(
        expected,
        modelType,
      );

      // ── Step 1: AI Character Recognition ────────────────────────────
      String prediction = '';
      bool aiRecognized = false;

      if (isSupported) {
        final evalResult = await _evalService.predictBoard(
          modelType: modelType,
          rawStrokes: _rawStrokes,
          getPayload: () => _getXYStrokeWithTime(modelType),
        );
        prediction = (evalResult?['prediction'] ?? '').toString().trim();
        aiRecognized = _isDrawingCorrect(prediction, expected);
      } else {
        // Character not present in classifier model set, rely on structural validation
        aiRecognized = true;
        prediction = expected;
      }

      // ── Step 2: Structural & Geometric Validation (count, direction, length, outliers)
      if (canvasTemplateStrokesPx.isNotEmpty) {
        final centered = StrokeTransformUtil.autoCenterStrokes(
          _rawStrokes,
          canvasTemplateStrokesPx,
        );
        strokeHint = AiStrokeFeedbackUtil.getFeedback(
          userRawStrokes: centered,
          templateStrokesPx: canvasTemplateStrokesPx,
          boardWidth: _canvasSize,
          boardHeight: _canvasSize,
        );
      }

      // ── Step 3: Combined Evaluation Decision ─────────────────────────
      if (aiRecognized && strokeHint == null) {
        isCorrect = true;
      } else {
        isCorrect = false;
        if (!aiRecognized) {
          // If AI says drawing is a different character or unrecognized scribble
          strokeHint = strokeHint ?? 'feedback_wrong_character';
        }
      }

      final String recordedAnswer = isCorrect
          ? expected
          : (prediction.isNotEmpty ? prediction : 'unknown');

      final int? exId = _charToExerciseId[expected];
      if (exId != null) {
        attempts.add({
          'exercise_id': exId,
          'user_answer': recordedAnswer,
          'label': expected,
          'stroke': getPointsJson(),
          'device_type': _deviceType,
          'is_correct': isCorrect,
        });
      }

      final audio = Get.isRegistered<StageAudioController>()
          ? Get.find<StageAudioController>()
          : Get.put(StageAudioController());

      if (isCorrect) {
        repResults[rep.value] = true;
        totalCorrect.value++;
        totalAttempted.value++;
        earnedCoins.value += _coinsPerCorrect;
        feedbackState.value = DrawFeedback.correct;
        praiseFeedback.value = DrawFeedback.correct;
        praiseText.value = [
          'praise_excellent'.tr,
          'praise_well_done'.tr,
        ][DateTime.now().millisecond % 2];

        await audio.playCorrectSfx();

        await Future.delayed(const Duration(milliseconds: 1500));

        feedbackState.value = DrawFeedback.none;
        praiseText.value = '';
        praiseFeedback.value = DrawFeedback.none;

        onNext(onFinished);
      } else {
        attemptLeft.value = (attemptLeft.value - 1).clamp(0, 3);
        feedbackState.value = DrawFeedback.wrong;
        praiseFeedback.value = DrawFeedback.wrong;
        // Show specific stroke feedback hint if available
        praiseText.value = (strokeHint != null) ? strokeHint.tr : 'try_again'.tr;

        await audio.playWrongSfx();
        _shakeController.forward(from: 0);

        await Future.delayed(const Duration(milliseconds: 1500));

        feedbackState.value = DrawFeedback.none;
        praiseText.value = '';
        praiseFeedback.value = DrawFeedback.none;

        clearBoard();

        if (attemptLeft.value == 0) {
          repResults[rep.value] = false;
          totalAttempted.value++;
          onNext(onFinished);
        }
      }
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        'Failed to evaluate drawing. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.withValues(alpha: 0.9),
        colorText: Colors.white,
      );
    } finally {
      isSubmitting.value = false;
    }
  }
}
