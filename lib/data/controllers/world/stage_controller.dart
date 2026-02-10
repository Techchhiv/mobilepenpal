import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_drawing_board/flutter_drawing_board.dart';
import 'package:get/get.dart';
import 'package:mobilepenpal/core/network/route_builder.dart';
import 'package:mobilepenpal/core/utils/math_generation.dart';
import 'package:mobilepenpal/core/utils/number_format_utils.dart';
import 'package:mobilepenpal/data/controllers/world/stage_animation_controller.dart';
import 'package:mobilepenpal/data/controllers/world/stage_audio_controller.dart';
import 'package:mobilepenpal/data/models/stage/stage.dart';
import 'package:mobilepenpal/data/models/stage/stage_exercise.dart';
import 'package:mobilepenpal/data/services/world_service.dart';
import 'package:mobilepenpal/presentation/routes/app_routes.dart';
import 'package:mobilepenpal/presentation/widgets/app_snackbar.dart';

class StageController extends GetxController {
  StageController({WorldService? worldService})
    : _worldService = worldService ?? WorldService();

  final WorldService _worldService;

  final isLoading = false.obs;
  final isSubmitting = false.obs;

  final currentStage = Rxn<Stage>();
  final exercises = <StageExercise>[].obs;
  final lastError = RxnString();

  static const int maxAttemptsPerExercise = 3;
  final attemptLeft = maxAttemptsPerExercise.obs;

  CancelToken? _cancelToken;
  int _redId = 0;

  late int worldId;
  late int levelId;
  late int stageId;

  final DrawingController drawingController = DrawingController();

  final letterSubpathsNorm = <List<Offset>>[].obs;
  final strokeStrokesNorm = <List<Offset>>[].obs;

  final double boardWidth = 340;
  final double boardHeight = 340;

  final currentExerciseIndex = 0.obs;
  final selectedCharacter = ''.obs;

  final MathGenerator _mathGen = MathGenerator();

  final mathPrompt = ''.obs;
  final mathExpected = RxnInt();
  final currentMathOp = RxnString();

  final Map<String, MathQuestion> _mathCache = {};

  final attempts = <Map<String, dynamic>>[].obs;

  final _strokesDb = Rxn<Map<String, dynamic>>();

  late final StageAnimationController anim;
  bool _ownsAnim = false;

  late final StageAudioController audio;
  bool _ownsAudio = false;

  final List<List<Map<String, dynamic>>> _rawStrokes = [];
  List<Map<String, dynamic>>? _currentStroke;

  bool hasDrawnStroke = false;
  Timer? idle;
  DateTime? _sessionStart;

  StageExercise? get currentExercise =>
      (currentExerciseIndex.value >= 0 &&
          currentExerciseIndex.value < exercises.length)
      ? exercises[currentExerciseIndex.value]
      : null;

  bool get _isLastExercise =>
      currentExerciseIndex.value >= exercises.length - 1;

  int get _sessionDurationSeconds {
    if (_sessionStart == null) return 0;
    return DateTime.now().difference(_sessionStart!).inSeconds;
  }

  bool get showIllustration {
    final t = (currentExercise?.characterType ?? '').trim().toLowerCase();
    return t == 'consonants' || t == 'digits' || t == 'math';
  }

  bool get isMathCurrent {
    final t = (currentExercise?.characterType ?? '').trim().toLowerCase();
    return t == 'math';
  }

  String _mathKeyFor(StageExercise ex) => '${ex.id}:${ex.repeatSlot}';

  final stageProgress = 0.0.obs;

  final progressStarStates = <StarState>[
    StarState.pending,
    StarState.pending,
    StarState.pending,
  ].obs;
  final progressAnimatingStarIndex = (-1).obs;
  final progressStarScale = 1.0.obs;

  int get totalExercises => exercises.length;

  int get completedExercises => attempts.length.clamp(0, totalExercises);

  int get correctExercises {
    return attempts.where((a) => a['is_correct'] == true).length;
  }

  int get starsEarnedByScore {
    final total = totalExercises;
    if (total <= 0) return 0;

    final pct = (correctExercises / total) * 100.0;

    if (pct >= 100.0) return 3;
    if (pct >= 66.0) return 2;
    if (pct >= 33.0) return 1;
    return 0;
  }

  @override
  void onInit() {
    super.onInit();

    final p = Get.parameters;
    worldId = int.tryParse(p['worldId'] ?? '') ?? 0;
    levelId = int.tryParse(p['levelId'] ?? '') ?? 0;
    stageId = int.tryParse(p['stageId'] ?? '') ?? 0;

    drawingController.setStyle(color: Colors.black, strokeWidth: 6);

    if (Get.isRegistered<StageAnimationController>()) {
      anim = Get.find<StageAnimationController>();
      _ownsAnim = false;
    } else {
      anim = Get.put(StageAnimationController());
      _ownsAnim = true;
    }
    anim.setBoardSize(width: boardWidth, height: boardHeight);

    if (Get.isRegistered<StageAudioController>()) {
      audio = Get.find<StageAudioController>();
      _ownsAudio = false;
    } else {
      audio = Get.put(StageAudioController());
      _ownsAudio = true;
    }

    loadStrokeDb();

    if (currentStage.value != null && currentStage.value!.id == stageId) return;

    if (stageId > 0) fetchStageDetail();

    anim.resetStars();
  }

  @override
  void onClose() {
    idle?.cancel();
    drawingController.dispose();
    _cancelPredictIfAny();
    audio.stopAll();

    // if (_ownsAnim && Get.isRegistered<StageAnimationController>()) {
    //   Get.delete<StageAnimationController>();
    // }
    // if (_ownsAudio && Get.isRegistered<StageAudioController>()) {
    //   Get.delete<StageAudioController>();
    // }

    super.onClose();
  }

  Future<void> fetchStageDetail() async {
    isLoading.value = true;
    lastError.value = null;

    try {
      final response = await _worldService.getStageById(stageId);
      if (response.code != 200) {
        lastError.value = response.message;
        return;
      }

      final stage = response.data;
      if (stage == null) {
        lastError.value = 'Stage data is empty';
        return;
      }

      currentStage.value = stage;
      exercises.assignAll(stage.exercises);

      _mathCache.clear();
      mathPrompt.value = '';
      mathExpected.value = null;

      anim.resetStars(total: exercises.length);

      attempts.clear();
      _updateProgressUI(animate: false);

      if (exercises.isEmpty) return;
      _startAtExercise(0, playAudioAfter: true);
      _sessionStart = DateTime.now();
    } catch (e) {
      lastError.value = 'Failed to load stage details: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadStage({
    required int newStageId,
    int? newWorldId,
    int? newLevelId,
  }) async {
    stageId = newStageId;
    if (newWorldId != null) worldId = newWorldId;
    if (newLevelId != null) levelId = newLevelId;
    anim.resetStars();
    _resetSessionState(clearGuide: true);
    await fetchStageDetail();
    anim.resetStars(total: exercises.length);
  }

  void selectExerciseByIndex(int index) {
    if (index < 0 || index >= exercises.length) return;
    audio.stopVoice();
    _startAtExercise(index);
  }

  void selectExerciseByCharacter(String char) {
    final index = exercises.indexWhere((e) => e.character == char);
    if (index != -1) selectExerciseByIndex(index);
  }

  void nextExercise() {
    if (currentExerciseIndex.value < exercises.length - 1) {
      selectExerciseByIndex(currentExerciseIndex.value + 1);
    }
  }

  void previousExercise() {
    if (currentExerciseIndex.value > 0) {
      selectExerciseByIndex(currentExerciseIndex.value - 1);
    }
  }

  Future<void> _startAtExercise(
    int index, {
    bool playAudioAfter = false,
  }) async {
    currentExerciseIndex.value = index;
    attemptLeft.value = maxAttemptsPerExercise;

    clearBoard();

    final ex = exercises[index];
    final t = (ex.characterType ?? '').trim().toLowerCase();

    if (t == 'math') {
      final key = _mathKeyFor(ex);

      final diff = parseMathDifficulty(ex.difficulty);
      final q = _mathCache.putIfAbsent(key, () {
        return _mathGen.generate(
          difficulty: diff,
          opKeyRaw: ex.mathOp,
        );
      });

      mathPrompt.value = q.toPrompt(withQuestionMark: true);
      mathExpected.value = q.answer;
      currentMathOp.value = q.opKey;

      letterSubpathsNorm.clear();
      strokeStrokesNorm.clear();
      anim.setGuideFromPx(strokesPx: const []);
      anim.stopGuide();

      selectedCharacter.value = '';
      return;
    }

    mathPrompt.value = '';
    mathExpected.value = null;
    currentMathOp.value = null;

    selectedCharacter.value = ex.character;
    setGuideForCharacter(selectedCharacter.value);

    await anim.resolveIllustration(
      characterType: ex.characterType ?? '',
      character: ex.character,
    );

    if (playAudioAfter) {
      await Future.delayed(const Duration(milliseconds: 150));
      await audio.autoPlayCharacter(
        type: ex.characterType ?? '',
        ch: ex.character,
      );
    }
  }

  void _updateProgressUI({bool animate = true}) {
    final total = totalExercises;
    final correct = correctExercises;

    stageProgress.value = (total <= 0)
        ? 0.0
        : (correct / total).clamp(0.0, 1.0);

    final earned = starsEarnedByScore;

    final next = List<StarState>.generate(
      3,
      (i) => i < earned ? StarState.correct : StarState.pending,
    );

    if (animate) {
      for (int i = 0; i < 3; i++) {
        if (progressStarStates[i] != StarState.correct &&
            next[i] == StarState.correct) {
          _popProgressStar(i);
          break;
        }
      }
    }

    progressStarStates.assignAll(next);
  }

  Future<void> _popProgressStar(int i) async {
    progressAnimatingStarIndex.value = i;
    progressStarScale.value = 1.25;
    await Future.delayed(const Duration(milliseconds: 140));
    progressStarScale.value = 1.0;
    await Future.delayed(const Duration(milliseconds: 120));
    progressAnimatingStarIndex.value = -1;
  }

  Future<void> playCurrentCharacterAudio() async {
    final ex = currentExercise;
    if (ex == null) return;
    await audio.playCharacterGuarded(
      type: ex.characterType ?? '',
      ch: ex.character,
    );
  }

  void clearBoard() {
    drawingController.clear();

    hasDrawnStroke = false;
    idle?.cancel();

    _rawStrokes.clear();
    _currentStroke = null;
    if (!isMathCurrent) {
      anim.restartGuideFromStart();
    } else {
      anim.stopGuide();
      anim.setGuideFromPx(strokesPx: const []);
    }
  }

  void onPointerDown() {
    hasDrawnStroke = true;
    idle?.cancel();
    anim.stopGuide();
    _cancelPredictIfAny();
  }

  Future<void> onPointerUp() async {
    if (!hasDrawnStroke) return;

    hasDrawnStroke = false;
    idle?.cancel();

    idle = Timer(const Duration(milliseconds: 1800), () async {
      await checkDrawing();
      hasDrawnStroke = false;
    });
  }

  void onRawPointerDown(PointerDownEvent e) {
    _currentStroke = [];
    final now = DateTime.now().millisecondsSinceEpoch;
    _currentStroke!.add({
      "x": e.localPosition.dx,
      "y": e.localPosition.dy,
      "time": now,
    });
    onPointerDown();
  }

  void onRawPointerMove(PointerMoveEvent e) {
    if (_currentStroke == null) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    _currentStroke!.add({
      "x": e.localPosition.dx,
      "y": e.localPosition.dy,
      "time": now,
    });
  }

  void onRawPointerUp(PointerUpEvent e) {
    if (_currentStroke != null && _currentStroke!.isNotEmpty) {
      _rawStrokes.add(List<Map<String, dynamic>>.from(_currentStroke!));
    }
    _currentStroke = null;
    onPointerUp();
  }

  Future<void> checkDrawing() async {
    final exercise = currentExercise;
    if (exercise == null) return;

    _cancelPredictIfAny();
    final myReqId = ++_redId;
    final cancelToken = CancelToken();
    _cancelToken = cancelToken;

    final modelType = _mapCharacterTypeToModelType(exercise.characterType);

    bool isCorrect = false;
    String prediction = '';

    try {
      final payload = getXYStrokeWithTime(modelType: modelType);

      final strokes = (payload['strokes'] as List).cast<Map<String, dynamic>>();

      final data = await _worldService.predictDrawingVector(
        strokes: strokes,
        modelType: payload['model_type'] as String,
        cancelToken: cancelToken,
      );
      if (myReqId != _redId) return;

      prediction = (data['prediction'] ?? '').toString().trim();

      if (isMathCurrent) {
        final expected = mathExpected.value;
        final predValue = NumberFormatUtils.parseIntAny(prediction);

        isCorrect =
            expected != null && predValue != null && predValue == expected;
      } else {
        final expected = exercise.character.trim();
        isCorrect = prediction == expected;
      }
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) return;
    } catch (e) {
      lastError.value = 'Predict failed: $e';
      isCorrect = isMathCurrent ? false : (Random().nextDouble() <= 0.9);
    } finally {
      if (myReqId == _redId) {
        _cancelToken = null;
      }
    }

    if (!isCorrect) {
      unawaited(audio.playWrongSfx());

      attemptLeft.value = (attemptLeft.value - 1).clamp(
        0,
        maxAttemptsPerExercise,
      );

      await anim.showWrongAndReset(
        onAfterReset: () {
          clearBoard();
          hasDrawnStroke = false;
          if (!isMathCurrent) anim.restartGuideFromStart();
        },
      );

      if (attemptLeft.value > 0) {
        return;
      }

      anim.markWrong(currentExerciseIndex.value);
      unawaited(anim.playStarPop(currentExerciseIndex.value));

      final label = isMathCurrent
          ? (mathExpected.value?.toString() ?? '')
          : exercise.character;

      attempts.add({
        'exercise_id': exercise.id,
        'user_answer': prediction,
        'label': label,
        'stroke': getXYStrokes(),
        'is_correct': false,
        if (isMathCurrent) 'math_op': currentMathOp.value,
      });

      _updateProgressUI();

      await Future.delayed(const Duration(milliseconds: 300));
      anim.feedback.value = DrawFeedback.none;
      anim.clearPraise();

      if (_isLastExercise) {
        await _finishStageIfLast();
      } else {
        nextExercise();
        clearBoard();
      }
      return;
    }

    anim.showCorrect(starIndex: currentExerciseIndex.value);
    unawaited(audio.playCorrectSfx());

    final label = isMathCurrent
        ? (mathExpected.value?.toString() ?? '')
        : exercise.character;

    attempts.add({
      'exercise_id': exercise.id,
      'user_answer': prediction.isNotEmpty ? prediction : exercise.character,
      'label': label,
      'stroke': getXYStrokes(),
      'is_correct': true,
      if (isMathCurrent) 'math_op': currentMathOp.value,
    });
    _updateProgressUI();

    await Future.delayed(const Duration(milliseconds: 800));
    anim.feedback.value = DrawFeedback.none;
    anim.clearPraise();

    if (_isLastExercise) {
      await _finishStageIfLast();
    } else {
      nextExercise();
      clearBoard();
    }
  }

  Future<void> skipCurrentExercise() async {
    final exercise = currentExercise;
    if (exercise == null) return;

    final label = isMathCurrent
        ? (mathExpected.value?.toString() ?? '')
        : exercise.character;

    attempts.add({
      'exercise_id': exercise.id,
      'user_answer': '',
      'label': label,
      'stroke': getXYStrokes(),
      'is_correct': false,
      if (isMathCurrent) 'math_op': currentMathOp.value,
    });
    _updateProgressUI();

    anim.markWrong(currentExerciseIndex.value);
    await anim.playStarPop(currentExerciseIndex.value);

    await anim.showWrongAndReset(
      onAfterReset: () {
        clearBoard();
        hasDrawnStroke = false;
      },
    );

    if (_isLastExercise) {
      await _finishStageIfLast();
      return;
    }

    nextExercise();
    clearBoard();
  }

  Future<void> _finishStageIfLast() async {
    final summary = await submitExerciseBatch(
      List<Map<String, dynamic>>.from(attempts),
      durationSeconds: _sessionDurationSeconds,
    );

    attempts.clear();
    _updateProgressUI(animate: false);
    hasDrawnStroke = false;
    drawingController.clear();
    _sessionStart = null;

    if (summary == null) return;

    final summaryRoute = RouteBuilder.build(AppRoutes.summary, {
      'worldId': worldId.toString(),
      'levelId': levelId.toString(),
      'stageId': stageId.toString(),
    });

    Get.offNamed(summaryRoute, arguments: {'summary': summary});
  }

  Future<void> resetForRetry() async {
    idle?.cancel();
    _cancelPredictIfAny();
    audio.stopVoice();

    attempts.clear();
    _sessionStart = DateTime.now();

    currentExerciseIndex.value = 0;
    attemptLeft.value = maxAttemptsPerExercise;

    anim.resetStars(total: exercises.length);

    stageProgress.value = 0.0;
    progressStarStates.assignAll([
      StarState.pending,
      StarState.pending,
      StarState.pending,
    ]);
    progressAnimatingStarIndex.value = -1;
    progressStarScale.value = 1.0;

    _updateProgressUI(animate: false);

    if (exercises.isNotEmpty) {
      await _startAtExercise(0, playAudioAfter: true);
    } else {
      selectedCharacter.value = '';
      anim.setGuideFromPx(strokesPx: const []);
    }

    clearBoard();
  }

  Future<Map<String, dynamic>?> submitExerciseBatch(
    List<Map<String, dynamic>> attempts, {
    int durationSeconds = 0,
  }) async {
    isSubmitting.value = true;
    try {
      final response = await _worldService.submitExerciseBatch(
        attempts,
        stageId: stageId,
        durationSeconds: durationSeconds,
      );

      if (response.code != 200) {
        AppSnackbar.show(
          response.message.isNotEmpty ? response.message : 'Request failed',
          title: 'Error',
          backgroundColor: Colors.redAccent,
        );
        return null;
      }

      final data = response.data ?? <String, dynamic>{};
      return data['summary'] as Map<String, dynamic>? ?? {};
    } catch (e) {
      Get.snackbar('Error', 'Failed to submit exercises: $e');
      return null;
    } finally {
      isSubmitting.value = false;
    }
  }

  List<dynamic> getXYStrokes() {
    final out = <dynamic>[];

    for (final stroke in _rawStrokes) {
      for (final p in stroke) {
        out.add((p["x"] as num).toDouble());
        out.add((p["y"] as num).toDouble());
      }
      out.add('#');
    }

    if (out.isNotEmpty && out.last == '#') out.removeLast();
    return out;
  }

  Map<String, dynamic> getXYStrokeWithTime({required String modelType}) {
    return {
      "strokes": _rawStrokes
          .map(
            (stroke) => {
              "points": stroke
                  .map(
                    (p) => {
                      "x": (p["x"] as num).toDouble(),
                      "y": (p["y"] as num).toDouble(),
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

  String get characterVowelFormsRaw => currentExercise?.example ?? '';

  List<String> get characterVowelFormsList {
    final raw = characterVowelFormsRaw.trim();
    if (raw.isEmpty) return const [];

    final ex = currentExercise;
    final t = (ex?.characterType ?? '').trim().toLowerCase();
    final target = (ex?.character ?? selectedCharacter.value).trim();

    String prefixForType() {
      if (t == 'digits') return 'លេខ ';
      if (t == 'dependent_vowels' || t == 'independent_vowels') return 'ស្រៈ ';
      return '';
    }

    final prefix = prefixForType();

    final parts = raw
        .split('/')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .map((token) {
          if (token.startsWith('លេខ') || token.startsWith('ស្រៈ')) return token;

          if (prefix.isNotEmpty && token == target) return '$prefix$token';

          return token;
        })
        .toList();

    final out = <String>[];
    for (final s in parts) {
      if (!out.contains(s)) out.add(s);
    }
    return out;
  }

  Future<void> loadStrokeDb() async {
    if (_strokesDb.value != null) return;

    final raw = await rootBundle.loadString('assets/strokes/strokes.json');
    _strokesDb.value = jsonDecode(raw) as Map<String, dynamic>;
  }

  void setGuideForCharacter(String ch) {
    final db = _strokesDb.value;
    final items = db?['items'] as Map<String, dynamic>?;

    if (isMathCurrent) {
      letterSubpathsNorm.clear();
      strokeStrokesNorm.clear();
      anim.setGuideFromPx(strokesPx: const []);
      return;
    }

    final entry = items?[ch.trim()] as Map<String, dynamic>?;

    if (entry == null) {
      letterSubpathsNorm.clear();
      strokeStrokesNorm.clear();
      anim.setGuideFromPx(strokesPx: const []);
      return;
    }

    final letter = entry['text_px'] as List<dynamic>? ?? [];
    final strokes = entry['paths_px'] as List<dynamic>? ?? [];

    final letterOut = _readSubpathsPx(letter);
    final strokesOut = _readSubpathsPx(strokes);

    if (letterOut.isEmpty && strokesOut.isEmpty) {
      letterSubpathsNorm.clear();
      strokeStrokesNorm.clear();
      anim.setGuideFromPx(strokesPx: const []);
      return;
    }

    final combined = <List<Offset>>[...letterOut, ...strokesOut];
    final fitted = _autoFitGlyphPx(
      combined,
      boardW: boardWidth,
      boardH: boardHeight,
      pad: 24,
      minWidthFill: 0.72,
      minHeightFill: 0.78,
    );

    final fittedLetter = fitted.take(letterOut.length).toList();
    final fittedStrokes = fitted.skip(letterOut.length).toList();

    letterSubpathsNorm.assignAll(fittedLetter);
    strokeStrokesNorm.assignAll(fittedStrokes);
    anim.setGuideFromPx(strokesPx: fittedStrokes);
  }

  List<List<Offset>> _readSubpathsPx(List<dynamic> raw) {
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

  List<List<Offset>> _autoFitGlyphPx(
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

  void _resetSessionState({bool clearGuide = false}) {
    attempts.clear();
    _updateProgressUI(animate: false);
    currentExerciseIndex.value = 0;
    selectedCharacter.value = '';
    exercises.clear();
    currentStage.value = null;
    _sessionStart = null;

    _mathCache.clear();
    mathPrompt.value = '';
    mathExpected.value = null;
    currentMathOp.value = null;

    clearBoard();
    if (clearGuide) anim.setGuideFromPx(strokesPx: const []);
  }

  void _cancelPredictIfAny() {
    if (_cancelToken != null && !(_cancelToken!.isCancelled)) {
      _cancelToken!.cancel();
    }
    _cancelToken = null;
  }

  String _mapCharacterTypeToModelType(String? characterType) {
    final t = (characterType ?? '').trim().toLowerCase();
    switch (t) {
      case 'digits':
        return 'digit';
      case 'consonants':
        return 'consonant';
      case 'independent_vowels':
        return 'independent_vowel';
      case 'dependent_vowels':
        return 'dependent_vowel';
      case 'math':
        return 'math';
      default:
        return 'consonant';
    }
  }
}
