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
import 'package:get_storage/get_storage.dart';
import 'package:mobilepenpal/core/utils/adventure_shadow_score_util.dart';
import 'package:mobilepenpal/core/utils/math_generation.dart';
import 'package:mobilepenpal/core/utils/number_format_utils.dart';
import 'package:mobilepenpal/core/utils/stage_session_type.dart';
import 'package:mobilepenpal/presentation/widgets/world/image_stamp_content.dart';
import 'package:get/get.dart';
import 'package:mobilepenpal/core/utils/character_option_utils.dart';
import 'package:mobilepenpal/core/utils/stroke_feedback_util.dart';
import 'package:mobilepenpal/core/utils/stroke_preprocessor.dart';
import 'package:mobilepenpal/data/controllers/world/stage_animation_controller.dart';
import 'package:mobilepenpal/data/controllers/world/stage_audio_controller.dart';
import 'package:mobilepenpal/data/controllers/home/home_controller.dart';
import 'package:mobilepenpal/data/models/exercise/exercise.dart';
import 'package:mobilepenpal/data/models/stage/stage_exercise.dart';
import 'package:mobilepenpal/data/models/student/student.dart';
import 'package:mobilepenpal/data/services/onnx_inference_service.dart';
import 'package:mobilepenpal/data/services/world_service.dart';
import 'package:mobilepenpal/data/controllers/shop/shop_controller.dart';
import 'package:mobilepenpal/presentation/routes/app_routes.dart';
import 'package:mobilepenpal/presentation/widgets/app_snackbar.dart';

class AdventureStageController extends GetxController {
  AdventureStageController({this.autoLoadFromArguments = true});

  final WorldService _worldService = WorldService();
  final GetStorage _box = GetStorage();
  final bool autoLoadFromArguments;

  final isLoading = false.obs;
  final isSubmitting = false.obs;
  final isSkipLocked = false.obs;
  final isAlreadyCompleted = false.obs;

  final exercises = <StageExercise>[].obs;
  final lastError = RxnString();
  int stageIndex = 0;
  String sessionType = StageSessionType.adventure;
  final List<Exercise> _sourceExercises = [];

  static const int maxAttemptsPerExercise = 3;
  final attemptLeft = maxAttemptsPerExercise.obs;

  CancelToken? _cancelToken;
  int _redId = 0;

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

  final MathGenerator _mathGen = MathGenerator();
  final mathPrompt = ''.obs;
  final mathExpected = RxnInt();
  final currentMathOp = RxnString();
  final Map<String, MathQuestion> _mathCache = {};

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
  bool _shouldAutoPlayInitialAudio = false;
  bool _isPlayingDeferredInitialAudio = false;

  StageExercise? get currentExercise =>
      (currentExerciseIndex.value >= 0 &&
          currentExerciseIndex.value < exercises.length)
      ? exercises[currentExerciseIndex.value]
      : null;

  bool get _isLastExercise =>
      currentExerciseIndex.value >= exercises.length - 1;

  bool get showIllustration {
    final t = (currentExercise?.characterType ?? '').trim().toLowerCase();
    return t == 'consonants' || t == 'digits' || t == 'math';
  }

  bool get isMathCurrent {
    final t = (currentExercise?.characterType ?? '').trim().toLowerCase();
    return t == 'math';
  }

  String _mathKeyFor(StageExercise ex) => '${ex.id}:${ex.repeatSlot}';

  bool get isDailyChallenge => StageSessionType.isDailyChallenge(sessionType);

  final stageProgress = 0.0.obs;
  final remainingStars = 3.obs;
  final exerciseDotStates = <StarState>[].obs;

  int get totalExercises => exercises.length;
  int get completedExercises => attempts.length.clamp(0, totalExercises);
  int get correctExercises {
    return attempts.where((a) => a['is_correct'] == true).length;
  }

  int get starsEarnedByScore => remainingStars.value.clamp(0, 3);

  bool get canSkip =>
      !isSubmitting.value &&
      !isSkipLocked.value &&
      anim.feedback.value == DrawFeedback.none;

  String categoryLabel = '';

  List<String> get characterVowelFormsList {
    final ex = currentExercise;
    if (ex == null) return const [];

    return CharacterOptionUtils.generateOptions(
      character: ex.character,
      type: ex.characterType,
      example: ex.example,
    );
  }

  @override
  void onInit() {
    super.onInit();

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
    anim.setBoardSize(width: boardWidth.value, height: boardHeight.value);

    if (Get.isRegistered<StageAudioController>()) {
      audio = Get.find<StageAudioController>();
      _ownsAudio = false;
    } else {
      audio = Get.put(StageAudioController());
      _ownsAudio = true;
    }

    if (autoLoadFromArguments) {
      final args = Get.arguments as Map<String, dynamic>?;
      if (args != null) {
        final exerciseList =
            (args['exercises'] as List? ?? const <dynamic>[])
                .whereType<Exercise>()
                .toList();
        
        isAlreadyCompleted.value = args['isAlreadyCompleted'] as bool? ?? false;

        unawaited(
          prepareStage(
            categoryLabel: args['categoryLabel'] as String? ?? '',
            stageIndex: args['stageIndex'] as int? ?? 0,
            exerciseList: exerciseList,
            deferInitialAudio: true,
            sessionType:
                args['sessionType'] as String? ?? StageSessionType.adventure,
          ),
        );
      }
    }
  }

  Future<void> prepareStage({
    required String categoryLabel,
    required int stageIndex,
    required List<Exercise> exerciseList,
    bool deferInitialAudio = true,
    String sessionType = StageSessionType.adventure,
  }) async {
    isLoading.value = true;
    lastError.value = null;

    this.categoryLabel = categoryLabel;
    this.stageIndex = stageIndex;
    this.sessionType = sessionType;
    _sourceExercises
      ..clear()
      ..addAll(exerciseList);
    _shouldAutoPlayInitialAudio = deferInitialAudio;
    _isPlayingDeferredInitialAudio = false;

    try {
      try {
        await loadStrokeDb();
      } catch (e) {
        dev.log(
          'loadStrokeDb error during prepareStage: $e',
          name: 'AdventureStageController',
        );
      }
      _initFromExercises(exerciseList);

      if (exercises.isEmpty) {
        selectedCharacter.value = '';
        letterSubpathsNorm.clear();
        strokeStrokesNorm.clear();
        anim.setGuideFromPx(strokesPx: const []);
        return;
      }

      await _startAtExercise(0, playAudioAfter: !deferInitialAudio);
      _sessionStart = DateTime.now();
    } catch (e) {
      lastError.value = 'Failed to prepare adventure stage: $e';
      dev.log(
        'prepareStage error: $e',
        name: 'AdventureStageController',
      );
    } finally {
      isLoading.value = false;
    }
  }

  void _initFromExercises(List<Exercise> exerciseList) {
    // Convert Exercise to StageExercise for compatibility
    final stageExercises = exerciseList.asMap().entries.map((entry) {
      final e = entry.value;
      return StageExercise(
        id: e.id,
        prompt: e.prompt,
        character: e.character,
        example: e.example,
        question: e.question,
        options: e.options,
        instruction: e.instruction,
        hint: e.hint,
        orderIndex: entry.key,
        characterType: e.characterType,
        repeatSlot: e.repeatSlot,
        difficulty: e.difficulty,
        mathOp: e.mathOp,
      );
    }).toList();

    exercises.assignAll(stageExercises);

    anim.resetStars(total: exercises.length);
    remainingStars.value = 3;
    exerciseDotStates.assignAll(
      List.filled(exercises.length, StarState.pending),
    );
    attempts.clear();
    earnedCoins.value = 0;
    triggerCoinAnim.value = 0;
    earnedXp.value = 0;
    triggerXpAnim.value = 0;
    _updateProgressUI(animate: false);
    anim.feedback.value = DrawFeedback.none;
    anim.clearPraise();

    if (exercises.isEmpty) return;
  }

  Future<void> playDeferredInitialAudioIfNeeded() async {
    if (!_shouldAutoPlayInitialAudio || _isPlayingDeferredInitialAudio) {
      return;
    }

    final ex = currentExercise;
    if (ex == null || isLoading.value) return;

    _shouldAutoPlayInitialAudio = false;
    _isPlayingDeferredInitialAudio = true;

    try {
      await Future.delayed(const Duration(milliseconds: 150));
      await audio.autoPlayCharacter(
        type: ex.characterType ?? '',
        ch: ex.character,
      );
    } finally {
      _isPlayingDeferredInitialAudio = false;
    }
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

  void selectExerciseByIndex(int index) {
    if (index < 0 || index >= exercises.length) return;
    audio.stopVoice();
    _startAtExercise(index);
  }

  void nextExercise() {
    if (currentExerciseIndex.value < exercises.length - 1) {
      selectExerciseByIndex(currentExerciseIndex.value + 1);
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
      dev.log(
        'Failed to load stamp image: $e',
        name: 'AdventureStageController',
      );
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

  final earnedCoins = 0.obs;
  final triggerCoinAnim = 0.obs;
  final earnedXp = 0.obs;
  final triggerXpAnim = 0.obs;

  void _updateProgressUI({bool animate = true}) {
    final total = totalExercises;
    final completed = completedExercises;
    final wrong = completed - correctExercises;

    stageProgress.value = (total <= 0)
        ? 0.0
        : (completed / total).clamp(0.0, 1.0);

    final dots = List<StarState>.generate(total, (i) {
      if (i < attempts.length) {
        return attempts[i]['is_correct'] == true
            ? StarState.correct
            : StarState.wrong;
      }
      return StarState.pending;
    });
    exerciseDotStates.assignAll(dots);

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

    remainingStars.value = achievable;
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

      return await OnnxInferenceService.instance.predict(
        modelType,
        result.segments[0],
        result.shapes[0],
      );
    } catch (e) {
      dev.log(
        'Local ONNX inference failed for $modelType: $e',
        name: 'AdventureStageController',
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

    try {
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
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) return;
    } catch (e) {
      lastError.value = 'Predict failed: $e';
      isCorrect = (Random().nextDouble() <= 0.9);
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

      final hasFeedbackText = anim.praiseText.value.isNotEmpty;
      final wrongDisplayDuration = hasFeedbackText
          ? const Duration(milliseconds: 1200)
          : const Duration(milliseconds: 550);

      attemptLeft.value = (attemptLeft.value - 1).clamp(
        0,
        maxAttemptsPerExercise,
      );
      isSkipLocked.value = true;
      await anim.showWrongAndReset(
        customDuration: wrongDisplayDuration,
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

      attempts.add({
        'exercise_id': exercise.id,
        'user_answer': prediction,
        'label': exercise.character,
        'stroke': getXYStrokes(),
        'is_correct': false,
        'xp_earned': 0,
        'shadow_iou': 0.0,
        'repeat_slot': exercise.repeatSlot,
        if (isDailyChallenge) 'is_daily_challenge': true,
      });

      _updateProgressUI();

      if (_isLastExercise) {
        await Future.delayed(const Duration(milliseconds: 300));
        anim.feedback.value = DrawFeedback.none;
        anim.clearPraise();
        await _finishAdventure();
      } else {
        anim.feedback.value = DrawFeedback.none;
        anim.clearPraise();
        nextExercise();
        clearBoard();
      }
      return;
    }

    anim.showCorrect(starIndex: currentExerciseIndex.value);
    unawaited(audio.playCorrectSfx());

    final shadowScore = AdventureShadowScoreUtil.calculate(
      userRawStrokes: _rawStrokesList[0],
      templateStrokesPx: strokeStrokesNorm,
      boardWidth: boardWidth.value,
      boardHeight: boardHeight.value,
    );

    final multiplier = isDailyChallenge ? 2 : 1;
    final earnedCoinThisAttempt = isAlreadyCompleted.value ? 0 : multiplier;
    final earnedXpThisAttempt = isAlreadyCompleted.value ? 0 : (shadowScore.xp * multiplier);

    if (earnedCoinThisAttempt > 0) {
      earnedCoins.value += earnedCoinThisAttempt;
      triggerCoinAnim.value++;
    }
    
    if (earnedXpThisAttempt > 0) {
      earnedXp.value += earnedXpThisAttempt;
      triggerXpAnim.value++;
    }

    attempts.add({
      'exercise_id': exercise.id,
      'user_answer': prediction.isNotEmpty ? prediction : exercise.character,
      'label': exercise.character,
      'stroke': getXYStrokes(),
      'is_correct': true,
      'xp_earned': earnedXpThisAttempt,
      'shadow_iou': shadowScore.iou,
      'repeat_slot': exercise.repeatSlot,
      if (isDailyChallenge) 'is_daily_challenge': true,
    });
    _updateProgressUI();

    await Future.delayed(const Duration(milliseconds: 800));
    anim.feedback.value = DrawFeedback.none;
    anim.clearPraise();

    if (_isLastExercise) {
      await _finishAdventure();
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

      attempts.add({
        'exercise_id': exercise.id,
        'user_answer': '',
        'label': exercise.character,
        'stroke': getXYStrokes(),
        'is_correct': false,
        'xp_earned': 0,
        'shadow_iou': 0.0,
        'repeat_slot': exercise.repeatSlot,
        if (isDailyChallenge) 'is_daily_challenge': true,
      });

      _updateProgressUI();

      anim.markWrong(currentExerciseIndex.value);
      await anim.playStarPop(currentExerciseIndex.value);

      await anim.showWrongAndReset(
        customDuration: const Duration(milliseconds: 550),
        onAfterReset: () {
          clearBoard();
        },
      );

      anim.feedback.value = DrawFeedback.none;
      anim.clearPraise();

      if (_isLastExercise) {
        await _finishAdventure();
        return;
      }

      nextExercise();
      clearBoard();
    });
  }

  Future<void> _finishAdventure() async {
    final correct = correctExercises;
    final total = totalExercises;
    final stars = starsEarnedByScore;

    final points = earnedCoins.value;
    final xp = earnedXp.value;

    // Submit to backend
    final duration = _sessionStart != null
        ? DateTime.now().difference(_sessionStart!).inSeconds
        : 0;

    await _submitAdventureResults(durationSeconds: duration);

    if (isDailyChallenge) {
      final studentId = Get.find<HomeController>().student.value?.id;
      if (studentId != null) {
        final today = DateTime.now().toIso8601String().split('T').first;
        _box.write('daily_challenge_date_$studentId', today);
      }
    }

    // Navigate to Adventure Summary
    Get.offNamed(
      AppRoutes.adventureSummary,
      arguments: {
        'correct': correct,
        'total': total,
        'stars': stars,
        'points': points,
        'xp': xp,
        'stageIndex': stageIndex,
        'attempts': List<Map<String, dynamic>>.from(attempts),
        'coins': earnedCoins.value,
        'sessionType': sessionType,
        'categoryLabel': categoryLabel,
        'exercises': List<Exercise>.from(_sourceExercises),
      },
    );
  }

  Future<void> _submitAdventureResults({required int durationSeconds}) async {
    if (attempts.isEmpty) return;

    isSubmitting.value = true;
    try {
      final response = await _worldService.submitExerciseBatch(
        List<Map<String, dynamic>>.from(attempts),
        durationSeconds: durationSeconds,
        coinsEarned: earnedCoins.value,
        xpEarned: earnedXp.value,
        isAdventure: !isDailyChallenge,
        isDailyChallenge: isDailyChallenge,
      );

      if (response.code != 200) {
        AppSnackbar.show(
          response.message.isNotEmpty
              ? response.message
              : 'Failed to save adventure results',
          title: 'Error',
          backgroundColor: Colors.redAccent,
        );
        return;
      }

      final data = response.data ?? const <String, dynamic>{};
      final summary = _readMap(data['summary']);

      await _syncStudentStats(
        currentCoin:
            _readInt(data['current_coin']) ?? _readInt(summary?['current_coin']),
        currentXp:
            _readInt(data['current_xp']) ?? _readInt(summary?['current_xp']),
        streak: _readInt(summary?['streak']),
      );
    } catch (e) {
      AppSnackbar.show(
        'Failed to save adventure results',
        title: 'Error',
        backgroundColor: Colors.redAccent,
      );
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> _syncStudentStats({
    int? currentCoin,
    int? currentXp,
    int? streak,
  }) async {
    if (currentCoin == null && currentXp == null && streak == null) return;

    if (Get.isRegistered<HomeController>()) {
      final homeController = Get.find<HomeController>();
      final currentStudent = homeController.student.value;

      if (currentStudent != null) {
        final updatedStudent = Student.fromJson({
          ...currentStudent.toJson(),
          if (currentCoin != null) 'coin': currentCoin,
          if (currentXp != null) 'xp': currentXp,
          if (streak != null) 'streak': streak,
        });

        homeController.student.value = updatedStudent;
        await _box.write('student', updatedStudent.toJson());
      }
    }

    if (currentCoin != null && Get.isRegistered<ShopController>()) {
      final shopController = Get.find<ShopController>();
      shopController.totalPoints.value = currentCoin;
      await _box.write('adventure_points', currentCoin);
    }
  }

  int? _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value == null) return null;
    return int.tryParse(value.toString());
  }

  Map<String, dynamic>? _readMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map(
        (key, val) => MapEntry(key.toString(), val),
      );
    }
    return null;
  }

  Future<void> resetForRetry() async {
    idle?.cancel();
    _cancelPredictIfAny();
    audio.stopVoice();

    attempts.clear();
    _sessionStart = DateTime.now();
    earnedCoins.value = 0;
    triggerCoinAnim.value = 0;
    earnedXp.value = 0;
    triggerXpAnim.value = 0;

    currentExerciseIndex.value = 0;
    attemptLeft.value = maxAttemptsPerExercise;

    anim.resetStars(total: exercises.length);

    stageProgress.value = 0.0;
    remainingStars.value = 3;
    exerciseDotStates.assignAll(
      List.filled(exercises.length, StarState.pending),
    );

    _updateProgressUI(animate: false);

    if (exercises.isNotEmpty) {
      await _startAtExercise(0, playAudioAfter: true);
    } else {
      selectedCharacter.value = '';
      anim.setGuideFromPx(strokesPx: const []);
    }

    clearBoard();
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

  Future<void> loadStrokeDb() async {
    if (_strokesDbCache != null) return;

    final raw = await rootBundle.loadString('assets/strokes/strokes.json');
    _strokesDbCache = jsonDecode(raw) as Map<String, dynamic>;
  }

  void setGuideForCharacter(String ch) {
    if (_strokesDbCache == null) {
      loadStrokeDb().then((_) {
        if (selectedCharacter.value == ch) {
          setGuideForCharacter(ch);
        }
      });
      return;
    }

    final db = _strokesDbCache;
    final items = db?['items'] as Map<String, dynamic>?;

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
      if (Get.isRegistered<AdventureStageController>()) {
        isSkipLocked.value = false;
      }
    }
  }
}
