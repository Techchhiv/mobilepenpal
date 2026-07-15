import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_drawing_board/flutter_drawing_board.dart';
import 'package:get/get.dart';
import 'package:mobilepenpal/core/utils/stroke_transform_util.dart';
import 'package:mobilepenpal/data/controllers/world/stage_audio_controller.dart';
import 'package:mobilepenpal/data/controllers/world/stage_animation_controller.dart';
import 'package:mobilepenpal/data/services/next_stroke_predictor_service.dart';
import 'package:mobilepenpal/data/services/drawing_evaluation_service.dart';

class AiWritingController extends GetxController with GetTickerProviderStateMixin {
  AiWritingController({
    required this.characters,
    required this.repeatCount,
  });

  final List<String> characters;
  final int repeatCount;

  // ── Session state ──────────────────────────────────────────────────────
  final charIndex = 0.obs;
  final rep = 0.obs;
  final isSubmitting = false.obs;
  final isLoading = true.obs;
  final attemptLeft = 3.obs;
  final repResults = <bool?>[].obs;

  // ── Drawing state ──────────────────────────────────────────────────────
  final drawingController = DrawingController();

  // ── Raw strokes coordinate capture ─────────────────────────────────────
  final List<List<Map<String, dynamic>>> _rawStrokes = [];
  List<Map<String, dynamic>>? _currentStroke;

  // ── Canvas size ────────────────────────────────────────────────────────
  double canvasSize = 340.0;

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

    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 12.0), weight: 1),
      TweenSequenceItem(tween: Tween<double>(begin: 12.0, end: -12.0), weight: 2),
      TweenSequenceItem(tween: Tween<double>(begin: -12.0, end: 12.0), weight: 2),
      TweenSequenceItem(tween: Tween<double>(begin: 12.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut))
      ..addListener(() {
        shakeOffset.value = _shakeAnimation.value;
      });

    guideController = AnimationController(
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
          guideController.forward(from: 0);
          return;
        }

        _betweenStrokeTimer = Timer(Duration(milliseconds: pause), () {
          if (!isGuiding.value) return;
          guideController.forward(from: 0);
        });
      });

    _loadStrokesDb();
    NextStrokePredictorService.instance.init();
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

  // ── Load strokes.json ──────────────────────────────────────────────────
  Future<void> _loadStrokesDb() async {
    try {
      final raw = await rootBundle.loadString('assets/strokes/strokes.json');
      _strokesDb = jsonDecode(raw) as Map<String, dynamic>;
      _refreshGuide();
    } catch (e) {
      dev.log('Failed to load strokes database: $e', name: 'AiWritingController');
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
      return;
    }

    final textPx = entry['text_px'] as List<dynamic>? ?? [];
    final pathsPx = entry['paths_px'] as List<dynamic>? ?? [];

    final letterOut = StrokeTransformUtil.readSubpathsPx(textPx);
    final strokesOut = StrokeTransformUtil.readSubpathsPx(pathsPx);

    if (letterOut.isEmpty && strokesOut.isEmpty) {
      _setGuideStrokes([], []);
      return;
    }

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
  }

  void _setGuideStrokes(List<List<Offset>> letterPx, List<List<Offset>> strokesPx) {
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
      return <int>[
        totalMs.clamp(minStrokeDurationMs, maxStrokeDurationMs),
      ];
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

    guideController.forward(from: 0);
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
    currentGuideStrokeIndex.value = (next >= guideStrokesPx.length) ? 0 : next;

    final stroke = guideStrokesPx[currentGuideStrokeIndex.value];
    guideCirclePx.value = stroke.isNotEmpty ? stroke.first : null;

    guideController.duration = Duration(
      milliseconds: _strokeDurationMs(currentGuideStrokeIndex.value),
    );
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

  final autoPredict = true.obs;
  final predictedSegments = <List<Offset>>[].obs;

  Future<void> predictNextStrokes() async {
    if (_rawStrokes.isEmpty) {
      predictedSegments.clear();
      return;
    }

    try {
      final userStrokes = _rawStrokes.map((stroke) {
        return stroke.map((p) => Offset((p["x"] as num).toDouble(), (p["y"] as num).toDouble())).toList();
      }).toList();

      final predictor = NextStrokePredictorService.instance;
      final segments = await predictor.predictNextStrokes(
        userStrokes: userStrokes,
        char: currentChar,
        canvasSize: canvasSize,
      );

      List<List<Offset>> filteredSegments = [];
      if (segments.isNotEmpty) {
        final firstSeg = segments.first;
        double pathLen = 0.0;
        for (int i = 0; i < firstSeg.length - 1; i++) {
          pathLen += (firstSeg[i + 1] - firstSeg[i]).distance;
        }

        // A threshold of 30.0 logical pixels is used to determine if the stroke is partial or complete.
        // If it's less than 30.0, the current stroke is considered complete, so we show the next stroke.
        const double threshold = 30.0;
        if (pathLen < threshold) {
          if (segments.length > 1) {
            // If the first segment is extremely short, discard it to avoid rendering a tiny dot/speck
            if (pathLen < 8.0) {
              filteredSegments = [segments[1]];
            } else {
              filteredSegments = [firstSeg, segments[1]];
            }
          } else {
            // No next stroke, and the current stroke is basically finished (leftover < threshold).
            // We treat the character as completely finished and show no further guides.
            filteredSegments = [];
          }
        } else {
          // If the first segment is long enough, the user is still drawing it, so show only this stroke.
          filteredSegments = [firstSeg];
        }
      }

      predictedSegments.assignAll(filteredSegments);
    } catch (e) {
      dev.log("Next-stroke prediction failed: $e", name: "AiWritingController");
      predictedSegments.clear();
    }
  }

  // ── Actions ────────────────────────────────────────────────────────────
  void clearBoard() {
    drawingController.clear();
    _rawStrokes.clear();
    predictedSegments.clear();
  }

  void onNext(VoidCallback onFinished) {
    drawingController.clear();
    _rawStrokes.clear();
    predictedSegments.clear();
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

    // Session complete
    onFinished();
  }

  // ── Stitching/Gap-closing State ────────────────────────────────────────
  bool _isContinuingLastStroke = false;
  static const double _strokeMergeThreshold = 35.0; // logical pixels

  // ── Pointer events coordinate capturing ───────────────────────────────
  void onPointerDown(PointerDownEvent e) {
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

        if (distSq < _strokeMergeThreshold * _strokeMergeThreshold) {
          _isContinuingLastStroke = true;
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
    final now = DateTime.now().millisecondsSinceEpoch;
    _currentStroke!.add({
      "x": e.localPosition.dx,
      "y": e.localPosition.dy,
      "time": now,
    });
  }

  void onPointerUp(PointerUpEvent e) {
    if (_currentStroke != null && _currentStroke!.isNotEmpty) {
      if (!_isContinuingLastStroke) {
        _rawStrokes.add(List<Map<String, dynamic>>.from(_currentStroke!));
      }
    }
    _currentStroke = null;
    _isContinuingLastStroke = false;
    if (autoPredict.value) {
      predictNextStrokes();
    }
  }

  // ── AI check ───────────────────────────────────────────────────────────
  String getModelTypeForChar(String char) {
    const consonantsSet = {
      'ក', 'ខ', 'គ', 'ឃ', 'ង',
      'ច', 'ឆ', 'ជ', 'ឈ', 'ញ',
      'ដ', 'ឋ', 'ឌ', 'ឍ', 'ណ',
      'ត', 'ថ', 'ទ', 'ធ', 'ន',
      'ប', 'ផ', 'ព', 'ភ', 'ម',
      'យ', 'រ', 'ល', 'វ', 'ស',
      'ហ', 'ឡ', 'អ',
    };
    const independentVowelsSet = {
      'ឥ', 'ឦ', 'ឧ', 'ឩ', 'ឪ', 'ឫ', 'ឬ', 'ឭ', 'ឮ', 'ឯ', 'ឰ', 'ឱ', 'ឲ', 'ឳ'
    };
    const dependentVowelsSet = {
      'ា', 'ិ', 'ី', 'ឹ', 'ឺ', 'ុ', 'ូ', 'ួ', 'ើ', 'ឿ', 'ៀ', 'េ', 'ែ', 'ៃ', 'ោ', 'ៅ', 'ុំ', 'ំ', 'ាំ', 'ះ', 'ិះ', 'ុះ', 'េះ', 'ោះ'
    };
    const numbersSet = {
      '០', '១', '២', '៣', '៤', '៥', '៦', '៧', '៨', '៩'
    };

    final trimChar = char.trim();
    if (consonantsSet.contains(trimChar)) return 'consonant';
    if (independentVowelsSet.contains(trimChar)) return 'independent_vowel';
    if (dependentVowelsSet.contains(trimChar)) return 'dependent_vowel';
    if (numbersSet.contains(trimChar)) return 'digit';
    return 'consonant';
  }

  Map<String, dynamic> _getXYStrokeWithTime(String modelType) {
    final s = canvasSize / 340.0;
    return {
      "strokes": _rawStrokes
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
      '0': '០', '1': '១', '2': '២', '3': '៣', '4': '៤',
      '5': '៥', '6': '៦', '7': '៧', '8': '៨', '9': '៩',
    };

    final normP = arabicToKhmer[p] ?? p;
    final normE = arabicToKhmer[e] ?? e;
    return normP == normE;
  }

  Future<void> checkDrawingAndSubmit(VoidCallback onFinished) async {
    if (_rawStrokes.isEmpty) {
      Get.snackbar(
        'warning'.tr,
        'Please draw the character before submitting!',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isSubmitting.value = true;

    try {
      final modelType = getModelTypeForChar(currentChar);
      final evalService = DrawingEvaluationService();

      final data = await evalService.predictBoard(
        modelType: modelType,
        rawStrokes: _rawStrokes,
        getPayload: () => _getXYStrokeWithTime(modelType),
      );

      final prediction = (data?['prediction'] ?? '').toString().trim();
      final expected = currentChar.trim();

      bool isCorrect = _isDrawingCorrect(prediction, expected);

      final audio = Get.isRegistered<StageAudioController>()
          ? Get.find<StageAudioController>()
          : Get.put(StageAudioController());

      if (isCorrect) {
        repResults[rep.value] = true;
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
        praiseText.value = 'try_again'.tr;

        await audio.playWrongSfx();
        _shakeController.forward(from: 0);

        await Future.delayed(const Duration(milliseconds: 1500));

        feedbackState.value = DrawFeedback.none;
        praiseText.value = '';
        praiseFeedback.value = DrawFeedback.none;

        clearBoard();

        if (attemptLeft.value == 0) {
          repResults[rep.value] = false;
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
