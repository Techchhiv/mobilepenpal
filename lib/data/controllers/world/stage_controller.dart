import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:math';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_drawing_board/flutter_drawing_board.dart';
import 'package:flutter_drawing_board/paint_contents.dart';
import 'package:mobilepenpal/presentation/widgets/world/image_stamp_content.dart';
import 'package:get/get.dart';
import 'package:mobilepenpal/core/network/route_builder.dart';
import 'package:mobilepenpal/core/utils/math_generation.dart';
import 'package:mobilepenpal/core/utils/number_format_utils.dart';
import 'package:mobilepenpal/core/utils/stroke_feedback_util.dart';
import 'package:mobilepenpal/core/utils/stroke_preprocessor.dart';
import 'package:mobilepenpal/data/controllers/world/stage_animation_controller.dart';
import 'package:mobilepenpal/data/controllers/world/stage_audio_controller.dart';
import 'package:mobilepenpal/data/models/stage/stage.dart';
import 'package:mobilepenpal/data/models/stage/stage_exercise.dart';
import 'package:mobilepenpal/data/services/onnx_inference_service.dart';
import 'package:mobilepenpal/data/services/world_service.dart';
import 'package:mobilepenpal/presentation/routes/app_routes.dart';
import 'package:mobilepenpal/presentation/widgets/app_snackbar.dart';

class StageController extends GetxController {
  StageController({WorldService? worldService})
    : _worldService = worldService ?? WorldService();

  final WorldService _worldService;

  final isLoading = false.obs;
  final isSubmitting = false.obs;
  final isSkipLocked = false.obs;

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

  final List<DrawingController> drawingControllers = List.generate(
    3,
    (_) => DrawingController(),
  );

  int get activeBoardCount {
    if (isMathCurrent) {
      final expected = mathExpected.value;
      if (expected != null) {
        return expected.toString().length;
      }
    }
    return 1;
  }

  final letterSubpathsNorm = <List<Offset>>[].obs;
  final strokeStrokesNorm = <List<Offset>>[].obs;

  final boardWidth = 340.0.obs;
  final boardHeight = 340.0.obs;

  void updateBoardSize(double size, {double? height}) {
    if (boardWidth.value == size && boardHeight.value == (height ?? size)) {
      return;
    }

    boardWidth.value = size;
    boardHeight.value = height ?? size;
    anim.setBoardSize(width: boardWidth.value, height: boardHeight.value);

    if (selectedCharacter.value.isNotEmpty) {
      setGuideForCharacter(selectedCharacter.value);
    }
  }

  double get scale => boardWidth.value / 340.0;

  final currentExerciseIndex = 0.obs;
  final selectedCharacter = ''.obs;

  final MathGenerator _mathGen = MathGenerator();

  final mathPrompt = ''.obs;
  final mathExpected = RxnInt();
  final currentMathOp = RxnString();

  final Map<String, MathQuestion> _mathCache = {};

  final attempts = <Map<String, dynamic>>[].obs;

  static Map<String, dynamic>? _strokesDbCache;

  ui.Image? _currentStampImage;

  late final StageAnimationController anim;
  bool _ownsAnim = false;

  late final StageAudioController audio;
  bool _ownsAudio = false;

  final List<List<List<Map<String, dynamic>>>> _rawStrokesList = List.generate(
    3,
    (_) => [],
  );
  final List<List<Map<String, dynamic>>?> _currentStrokeList = List.filled(
    3,
    null,
  );
  final List<bool> hasDrawnStrokeList = List.filled(3, false);

  bool get hasDrawnAnyStroke => hasDrawnStrokeList.any((e) => e);
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

  /// Gogomath-style: remaining stars (starts at 3, decreases on each wrong exercise).
  final remainingStars = 3.obs;

  /// Per-exercise dot states for the progress bar.
  /// Length == totalExercises. Each entry is correct / wrong / pending.
  final exerciseDotStates = <StarState>[].obs;

  int get totalExercises => exercises.length;

  int get completedExercises => attempts.length.clamp(0, totalExercises);

  int get correctExercises {
    return attempts.where((a) => a['is_correct'] == true).length;
  }

  int get starsEarnedByScore {
    return remainingStars.value.clamp(0, 3);
  }

  bool get canSkip =>
      !isSubmitting.value &&
      !isSkipLocked.value &&
      anim.feedback.value == DrawFeedback.none;

  @override
  void onInit() {
    super.onInit();

    final p = Get.parameters;
    worldId = int.tryParse(p['worldId'] ?? '') ?? 0;
    levelId = int.tryParse(p['levelId'] ?? '') ?? 0;
    stageId = int.tryParse(p['stageId'] ?? '') ?? 0;

    for (var c in drawingControllers) {
      c.setStyle(color: Colors.black, strokeWidth: 6);
    }

    if (Get.isRegistered<StageAnimationController>()) {
      anim = Get.find<StageAnimationController>();
      _ownsAnim = false;
    } else {
      anim = Get.put(StageAnimationController());
      _ownsAnim = true;
    }
    // Initial sync
    anim.setBoardSize(width: boardWidth.value, height: boardHeight.value);

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
    for (var c in drawingControllers) {
      c.dispose();
    }
    _cancelPredictIfAny();
    audio.stopAll();

    if (_ownsAnim && Get.isRegistered<StageAnimationController>()) {
      Get.delete<StageAnimationController>();
    }
    if (_ownsAudio && Get.isRegistered<StageAudioController>()) {
      Get.delete<StageAudioController>();
    }

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

      remainingStars.value = 3;
      exerciseDotStates.assignAll(
        List.filled(exercises.length, StarState.pending),
      );
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
        return _mathGen.generate(difficulty: diff, opKeyRaw: ex.mathOp);
      });
      mathPrompt.value = q.toPrompt(withQuestionMark: true);
      mathExpected.value = q.expectedAnswer;
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

    await _loadStampImage();

    if (playAudioAfter) {
      await Future.delayed(const Duration(milliseconds: 150));
      await audio.autoPlayCharacter(
        type: ex.characterType ?? '',
        ch: ex.character,
      );
    }
  }

  Future<void> _loadStampImage() async {
    final path = anim.illustrationAssetPath.value;

    if (path.isEmpty) {
      _currentStampImage = null;
      _applyDefaultBrush();
      return;
    }

    try {
      final data = await rootBundle.load(path);
      final codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(),
        targetWidth: 64,
        targetHeight: 64,
      );
      final frame = await codec.getNextFrame();
      _currentStampImage = frame.image;
      _applyStampBrush();
    } catch (e) {
      dev.log('Failed to load stamp image: $e', name: 'StageController');
      _currentStampImage = null;
      _applyDefaultBrush();
    }
  }

  void _applyStampBrush() {
    final img = _currentStampImage;
    if (img == null) {
      _applyDefaultBrush();
      return;
    }
    final stamp = ImageStampContent(
      stampImage: img,
      stampSize: 24.0 * scale,
      spacing: 16.0 * scale,
    );
    for (var c in drawingControllers) {
      c.setPaintContent(stamp);
    }
  }

  void _applyDefaultBrush() {
    final defaultLine = SimpleLine();
    for (var c in drawingControllers) {
      c.setPaintContent(defaultLine);
      c.setStyle(color: Colors.black, strokeWidth: 6);
    }
  }

  void _updateProgressUI({bool animate = true}) {
    final total = totalExercises;
    final completed = completedExercises;
    final wrong = completed - correctExercises;

    // Progress bar tracks completion (correct or wrong).
    stageProgress.value = (total <= 0)
        ? 0.0
        : (completed / total).clamp(0.0, 1.0);

    // Build per-exercise dot states from the attempts list.
    final dots = List<StarState>.generate(total, (i) {
      if (i < attempts.length) {
        return attempts[i]['is_correct'] == true
            ? StarState.correct
            : StarState.wrong;
      }
      return StarState.pending;
    });
    exerciseDotStates.assignAll(dots);

    // Compute achievable stars based on max possible correct answers.
    final chunkSize = (total / 3.0).ceil();
    final maxPossibleCorrect = total - wrong;
    int achievable;
    if (total <= 0) {
      achievable = 0;
    } else if (maxPossibleCorrect >= total) {
      achievable = 3;
    } else if (maxPossibleCorrect >= (2 * total / 3.0).ceil()) {
      achievable = 2;
    } else if (maxPossibleCorrect >= chunkSize) {
      achievable = 1;
    } else {
      achievable = 0;
    }

    final prevRemaining = remainingStars.value;
    remainingStars.value = achievable;

    if (animate && achievable < prevRemaining) {
      _popProgressStar(achievable);
    }
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
    for (var c in drawingControllers) {
      c.clear();
    }

    hasDrawnStrokeList.fillRange(0, hasDrawnStrokeList.length, false);
    idle?.cancel();

    for (int i = 0; i < _rawStrokesList.length; i++) {
      _rawStrokesList[i].clear();
      _currentStrokeList[i] = null;
    }

    if (_currentStampImage != null) {
      _applyStampBrush();
    }

    if (!isMathCurrent) {
      anim.restartGuideFromStart();
    } else {
      anim.stopGuide();
      anim.setGuideFromPx(strokesPx: const []);
    }
  }

  void onPointerDown() {
    idle?.cancel();
    anim.stopGuide();
    _cancelPredictIfAny();
  }

  Future<void> onPointerUp() async {
    if (!hasDrawnAnyStroke) return;

    idle?.cancel();

    for (int i = 0; i < activeBoardCount; i++) {
      if (_rawStrokesList[i].isEmpty) {
        return;
      }
    }

    double totalDistance = 0.0;
    for (int i = 0; i < activeBoardCount; i++) {
      for (final stroke in _rawStrokesList[i]) {
        if (stroke.length > 1) {
          for (int j = 1; j < stroke.length; j++) {
            final p1 = stroke[j - 1];
            final p2 = stroke[j];
            final dx = (p2['x'] as double) - (p1['x'] as double);
            final dy = (p2['y'] as double) - (p1['y'] as double);
            totalDistance += sqrt(dx * dx + dy * dy);
          }
        }
      }
    }

    if (totalDistance < 248.0) {
      if (!isMathCurrent) {
        anim.restartGuideFromStart();
      }
      return;
    }

    idle = Timer(const Duration(milliseconds: 1800), () async {
      await checkDrawing();
      hasDrawnStrokeList.fillRange(0, hasDrawnStrokeList.length, false);
    });
  }

  void onRawPointerDown(PointerDownEvent e, int boardIndex) {
    _currentStrokeList[boardIndex] = [];
    final now = DateTime.now().millisecondsSinceEpoch;
    _currentStrokeList[boardIndex]!.add({
      "x": e.localPosition.dx,
      "y": e.localPosition.dy,
      "time": now,
    });
    hasDrawnStrokeList[boardIndex] = true;
    onPointerDown();
  }

  void onRawPointerMove(PointerMoveEvent e, int boardIndex) {
    if (_currentStrokeList[boardIndex] == null) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    _currentStrokeList[boardIndex]!.add({
      "x": e.localPosition.dx,
      "y": e.localPosition.dy,
      "time": now,
    });
  }

  void onRawPointerUp(PointerUpEvent e, int boardIndex) {
    if (_currentStrokeList[boardIndex] != null &&
        _currentStrokeList[boardIndex]!.isNotEmpty) {
      _rawStrokesList[boardIndex].add(
        List<Map<String, dynamic>>.from(_currentStrokeList[boardIndex]!),
      );
    }
    _currentStrokeList[boardIndex] = null;
    onPointerUp();
  }

  Future<Map<String, dynamic>?> _predictLocal(
    String modelType,
    int boardIndex,
  ) async {
    try {
      final result = StrokePreprocessor.preprocessForModel(
        modelType,
        _rawStrokesList[boardIndex],
      );

      if (modelType == 'math' && !result.isSingleSegment) {
        String combined = '';
        for (int i = 0; i < result.segments.length; i++) {
          final data = await OnnxInferenceService.instance.predict(
            modelType,
            result.segments[i],
            result.shapes[i],
          );
          combined += (data['prediction'] ?? '').toString().trim();
        }
        return {'prediction': combined, 'segments': result.segments.length};
      } else {
        return await OnnxInferenceService.instance.predict(
          modelType,
          result.segments[0],
          result.shapes[0],
        );
      }
    } catch (e) {
      dev.log(
        'Local ONNX inference failed for $modelType: $e',
        name: 'StageController',
      );
      return null;
    }
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
    final boards = activeBoardCount;

    try {
      if (isMathCurrent && boards > 1) {
        String combinedPred = '';
        for (int i = 0; i < boards; i++) {
          if (_rawStrokesList[i].isEmpty) continue;

          Map<String, dynamic>? data = await _predictLocal(modelType, i);

          if (data == null) {
            final payload = getXYStrokeWithTime(
              modelType: modelType,
              boardIndex: i,
            );
            final strokes = (payload['strokes'] as List)
                .cast<Map<String, dynamic>>();
            data = await _worldService.predictDrawingVector(
              strokes: strokes,
              modelType: payload['model_type'] as String,
              cancelToken: cancelToken,
            );
          }
          if (myReqId != _redId) return;
          combinedPred += (data['prediction'] ?? '').toString().trim();
        }
        prediction = combinedPred;

        final expected = mathExpected.value;
        final predValue = NumberFormatUtils.parseIntAny(prediction);
        isCorrect =
            expected != null && predValue != null && predValue == expected;
      } else {
        Map<String, dynamic>? data = await _predictLocal(modelType, 0);
        if (data == null) {
          final payload = getXYStrokeWithTime(
            modelType: modelType,
            boardIndex: 0,
          );
          final strokes = (payload['strokes'] as List)
              .cast<Map<String, dynamic>>();
          data = await _worldService.predictDrawingVector(
            strokes: strokes,
            modelType: payload['model_type'] as String,
            cancelToken: cancelToken,
          );
        }
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

      if (!isMathCurrent &&
          strokeStrokesNorm.isNotEmpty &&
          letterSubpathsNorm.isNotEmpty) {
        final hint = StrokeFeedbackUtil.getFeedback(
          userRawStrokes: _rawStrokesList[0],
          templateStrokesPx: strokeStrokesNorm,
          boardWidth: boardWidth.value,
          boardHeight: boardHeight.value,
        );
        if (hint != null) {
          anim.praiseText.value = hint.tr;
        }
      }

      attemptLeft.value = (attemptLeft.value - 1).clamp(
        0,
        maxAttemptsPerExercise,
      );
      isSkipLocked.value = true;
      await anim.showWrongAndReset(
        onAfterReset: () {
          clearBoard();
          if (!isMathCurrent) anim.restartGuideFromStart();
        },
      );

      isSkipLocked.value = false;

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

      // Don't clear praise here if it's the last attempt; let the transition handle it.
      if (_isLastExercise) {
        await Future.delayed(const Duration(milliseconds: 300));
        anim.feedback.value = DrawFeedback.none;
        anim.clearPraise();
        await _finishStageIfLast();
      } else {
        await Future.delayed(const Duration(milliseconds: 1200));
        anim.feedback.value = DrawFeedback.none;
        anim.clearPraise();
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
    if (!canSkip) return;

    await _runWithSkipLock(() async {
      idle?.cancel();
      _cancelPredictIfAny();

      final exercise = currentExercise;
      if (exercise == null) return;

      final label = isMathCurrent
          ? (mathExpected.value?.toString() ?? '')
          : exercise.character;

      attempts.add({
        'exercise_id': exercise.id,
        'user_answer': '',
        'label': label,
        'stroke': getAllXYStrokesCombined(),
        'is_correct': false,
        if (isMathCurrent) 'math_op': currentMathOp.value,
      });

      _updateProgressUI();

      anim.markWrong(currentExerciseIndex.value);
      await anim.playStarPop(currentExerciseIndex.value);

      await anim.showWrongAndReset(
        onAfterReset: () {
          clearBoard();
        },
      );

      anim.feedback.value = DrawFeedback.none;
      anim.clearPraise();

      if (_isLastExercise) {
        await _finishStageIfLast();
        return;
      }

      nextExercise();
      clearBoard();
    });
  }

  Future<void> _finishStageIfLast() async {
    final summary = await submitExerciseBatch(
      List<Map<String, dynamic>>.from(attempts),
      durationSeconds: _sessionDurationSeconds,
    );

    attempts.clear();
    _updateProgressUI(animate: false);
    for (var c in drawingControllers) {
      c.clear();
    }
    hasDrawnStrokeList.fillRange(0, hasDrawnStrokeList.length, false);
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
    remainingStars.value = 3;
    exerciseDotStates.assignAll(
      List.filled(exercises.length, StarState.pending),
    );
    progressStarStates.assignAll([
      StarState.correct,
      StarState.correct,
      StarState.correct,
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

  List<dynamic> getAllXYStrokesCombined() {
    final out = <dynamic>[];
    for (int i = 0; i < activeBoardCount; i++) {
      final s = getXYStrokes(boardIndex: i);
      if (s.isNotEmpty) {
        if (out.isNotEmpty) out.add('#');
        out.addAll(s);
      }
    }
    return out;
  }

  List<dynamic> getXYStrokes({int boardIndex = 0}) {
    final out = <dynamic>[];
    final s = scale;

    for (final stroke in _rawStrokesList[boardIndex]) {
      for (final p in stroke) {
        out.add((p["x"] as num).toDouble() / s);
        out.add((p["y"] as num).toDouble() / s);
      }
      out.add('#');
    }

    if (out.isNotEmpty && out.last == '#') out.removeLast();
    return out;
  }

  Map<String, dynamic> getXYStrokeWithTime({
    required String modelType,
    int boardIndex = 0,
  }) {
    final s = scale;
    return {
      "strokes": _rawStrokesList[boardIndex]
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
    if (_strokesDbCache != null) return;

    final raw = await rootBundle.loadString('assets/strokes/strokes.json');
    _strokesDbCache = jsonDecode(raw) as Map<String, dynamic>;
  }

  void setGuideForCharacter(String ch) {
    final db = _strokesDbCache;
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
      boardW: boardWidth.value,
      boardH: boardHeight.value,
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

  Future<T?> _runWithSkipLock<T>(Future<T> Function() fn) async {
    if (isSkipLocked.value) return null;
    isSkipLocked.value = true;
    try {
      return await fn();
    } finally {
      if (Get.isRegistered<StageController>()) {
        isSkipLocked.value = false;
      }
    }
  }
}
