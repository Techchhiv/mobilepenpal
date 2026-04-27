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
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mobilepenpal/core/utils/stroke_preprocessor.dart';
import 'package:mobilepenpal/data/controllers/world/stage_animation_controller.dart';
import 'package:mobilepenpal/data/controllers/world/stage_audio_controller.dart';
import 'package:mobilepenpal/data/models/mini_game/challenge_generator.dart';
import 'package:mobilepenpal/data/models/mini_game/mini_game_model.dart';
import 'package:mobilepenpal/data/services/onnx_inference_service.dart';
import 'package:mobilepenpal/data/services/world_service.dart';

/// Controller for the dynamic endless mini-game mode.
class DynamicMiniGameController extends GetxController
    with GetTickerProviderStateMixin {
  final WorldService _worldService = WorldService();
  final GetStorage _box = GetStorage();

  // ── The mini-games being played ──
  late final List<MiniGameModel> miniGames;
  final currentMiniGame = Rxn<MiniGameModel>();
  final currentInputType = 'drawing_board'.obs;

  /// If the user explicitly chose an input type from the hub modal,
  /// we honour it (as long as it's compatible). Otherwise null = random.
  String? userChosenInputType;

  // ── Timer constants ──
  static const double initialTimerDuration = 30.0;
  static const double timerTickInterval = 0.05;
  static const double timeRewardCorrect = 5.0;
  static const double timePenaltyWrong = -2.0;

  // ── Observables: Game state ──
  final isGameActive = false.obs;
  final isGameOver = false.obs;
  final isPaused = false.obs;
  final isLoading = true.obs;
  final isSubmitting = false.obs;

  // Timer
  final timeLeft = initialTimerDuration.obs;
  final maxTime = initialTimerDuration.obs;
  double get timerFraction => (timeLeft.value / maxTime.value).clamp(0.0, 1.0);
  Timer? _gameTimer;

  // ── Animation Controllers ──
  late final AnimationController feedbackAnimCtrl;
  late final AnimationController promptBounceCtrl;
  late final AnimationController countdownAnimCtrl;

  // ── Countdown ──
  final countdownValue = 3.obs;
  final isCountingDown = true.obs;
  bool _countdownStarted = false;

  // Score
  final score = 0.obs;
  final combo = 0.obs;
  final bestCombo = 0.obs;
  final highScore = 0.obs;

  // Stats
  final totalAnswered = 0.obs;
  final correctCount = 0.obs;
  final wrongCount = 0.obs;
  final earnedCoins = 0.obs;

  double get accuracy {
    if (totalAnswered.value == 0) return 0.0;
    return (correctCount.value / totalAnswered.value * 100.0);
  }

  // Current challenge
  final currentChallenge = Rxn<Challenge>();
  final currentOptions = <String>[].obs;
  final feedbackText = ''.obs;
  final feedbackTrigger = 0.obs;
  final isCorrectFeedback = true.obs;

  // Drawing board (only used when input_type == 'drawing_board')
  final boardWidth = 340.0.obs;
  final boardHeight = 340.0.obs;
  final letterSubpathsNorm = <List<Offset>>[].obs;
  final strokeStrokesNorm = <List<Offset>>[].obs;

  final DrawingController drawingController = DrawingController();
  final List<List<Map<String, dynamic>>> _rawStrokes = [];
  List<Map<String, dynamic>>? _currentStroke;
  bool hasDrawnStroke = false;
  Timer? _idleTimer;
  CancelToken? _cancelToken;
  int _reqId = 0;

  // Stroke database
  static Map<String, dynamic>? _strokesDbCache;

  // Animation & Audio controllers
  late final StageAnimationController anim;
  bool _ownsAnim = false;
  late final StageAudioController audio;
  bool _ownsAudio = false;

  // Storage key for high score (per game or custom mix)
  String get _highScoreKey {
    if (miniGames.length == 1) {
      return 'dynamic_minigame_${miniGames.first.id}_high_score';
    }
    return 'custom_mix_high_score';
  }

  @override
  void onInit() {
    super.onInit();

    // Get the mini-games from navigation arguments
    final args = Get.arguments;
    if (args != null && args['miniGames'] is List<MiniGameModel>) {
      miniGames = args['miniGames'] as List<MiniGameModel>;
    } else if (args != null && args['miniGame'] is MiniGameModel) {
      miniGames = [args['miniGame'] as MiniGameModel];
    } else {
      // Fallback for safety
      Get.back();
      return;
    }

    // Read user-chosen input type (may be null = random)
    if (args != null && args['inputType'] is String) {
      userChosenInputType = args['inputType'] as String;
    }

    drawingController.setStyle(color: Colors.black, strokeWidth: 6);

    // Animation controller
    if (Get.isRegistered<StageAnimationController>()) {
      anim = Get.find<StageAnimationController>();
      _ownsAnim = false;
    } else {
      anim = Get.put(StageAnimationController());
      _ownsAnim = true;
    }
    anim.setBoardSize(width: boardWidth.value, height: boardHeight.value);

    // Audio controller
    if (Get.isRegistered<StageAudioController>()) {
      audio = Get.find<StageAudioController>();
      _ownsAudio = false;
    } else {
      audio = Get.put(StageAudioController());
      _ownsAudio = true;
    }

    // Load saved stats
    highScore.value = _box.read<int>(_highScoreKey) ?? 0;

    // Initialize Animation Controllers
    feedbackAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    promptBounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    countdownAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // Listen to feedback trigger
    ever(feedbackTrigger, (_) {
      if (feedbackTrigger.value > 0) {
        feedbackAnimCtrl.forward(from: 0);
      }
    });

    // Auto-start when loading finishes
    ever(isLoading, (bool loading) {
      if (!loading && !_countdownStarted) {
        _countdownStarted = true;
        startGame();
        pauseGame();
        startCountdown();
      }
    });

    _initGame();
  }

  void startCountdown() {
    isCountingDown.value = true;
    countdownValue.value = 3;
    countdownAnimCtrl.forward(from: 0);

    Future.delayed(const Duration(seconds: 1), () {
      countdownValue.value = 2;
      if (!isCountingDown.value) return;
      countdownAnimCtrl.forward(from: 0);

      Future.delayed(const Duration(seconds: 1), () {
        countdownValue.value = 1;
        if (!isCountingDown.value) return;
        countdownAnimCtrl.forward(from: 0);

        Future.delayed(const Duration(seconds: 1), () {
          countdownValue.value = 0;
          if (!isCountingDown.value) return;
          countdownAnimCtrl.forward(from: 0);

          Future.delayed(const Duration(milliseconds: 600), () {
            isCountingDown.value = false;
            resumeGame();
          });
        });
      });
    });
  }

  Future<void> _initGame() async {
    isLoading.value = true;
    try {
      bool needsDrawing = miniGames.any((g) => g.inputType.contains('drawing_board'));
      if (needsDrawing) {
        await _loadStrokeDb();
      }
    } finally {
      isLoading.value = false;
    }
  }

  // ── Game lifecycle ──

  void startGame() {
    score.value = 0;
    combo.value = 0;
    bestCombo.value = 0;
    totalAnswered.value = 0;
    correctCount.value = 0;
    wrongCount.value = 0;
    earnedCoins.value = 0;
    feedbackText.value = '';

    timeLeft.value = initialTimerDuration;
    maxTime.value = initialTimerDuration;
    isGameOver.value = false;
    isPaused.value = false;
    isGameActive.value = true;

    anim.feedback.value = DrawFeedback.none;
    anim.clearPraise();

    _pickNextChallenge();
    _startTimer();
  }

  void pauseGame() {
    if (!isGameActive.value || isGameOver.value) return;
    isPaused.value = true;
    _gameTimer?.cancel();
  }

  void resumeGame() {
    if (!isGameActive.value || isGameOver.value) return;
    isPaused.value = false;
    _startTimer();
  }

  void endGame() {
    _gameTimer?.cancel();
    _idleTimer?.cancel();
    _cancelPredictIfAny();
    isGameActive.value = false;
    isGameOver.value = true;

    // Update high score
    if (score.value > highScore.value) {
      highScore.value = score.value;
      _box.write(_highScoreKey, highScore.value);
    }

    // Calculate coins: 1 coin per 10 score
    earnedCoins.value = (score.value / 10).floor();
  }

  void _startTimer() {
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(
      Duration(milliseconds: (timerTickInterval * 1000).round()),
      (_) {
        if (isPaused.value) return;
        timeLeft.value -= timerTickInterval;
        if (timeLeft.value <= 0) {
          timeLeft.value = 0;
          endGame();
        }
      },
    );
  }

  // ── Challenge selection ──

  void _pickNextChallenge() {
    // Pick a random game from the selected ones
    final game = miniGames[Random().nextInt(miniGames.length)];
    currentMiniGame.value = game;

    // Determine which input types are valid
    final compatibleTypes = game.compatibleInputTypes(game.displayType);

    if (userChosenInputType != null && compatibleTypes.contains(userChosenInputType)) {
      // User explicitly chose this input type and it's compatible
      currentInputType.value = userChosenInputType!;
    } else if (compatibleTypes.isNotEmpty) {
      currentInputType.value = compatibleTypes[Random().nextInt(compatibleTypes.length)];
    } else {
      // Fallback
      currentInputType.value = 'drawing_board';
    }

    final challenge = ChallengeGenerator.generate(game);
    currentChallenge.value = challenge;
    
    // Generate options if multiple choice
    if (currentInputType.value == 'multiple_choice') {
      final pool = (game.config?['pool'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
      final options = <String>{challenge.target};
      pool.shuffle();
      for (final option in pool) {
        if (options.length >= 4) break;
        options.add(option);
      }
      final optionsList = options.toList()..shuffle();
      currentOptions.assignAll(optionsList);
    } else {
      currentOptions.clear();
    }
    
    clearBoard();

    // If drawing board and we have stroke data, set guide
    if (currentInputType.value == 'drawing_board' &&
        game.displayType != 'math_equation') {
      setGuideForCharacter(challenge.target);
    } else {
      letterSubpathsNorm.clear();
      strokeStrokesNorm.clear();
      anim.setGuideFromPx(strokesPx: const []);
    }
  }

  // ── Drawing input ──

  void updateBoardSize(double size, {double? height}) {
    if (boardWidth.value == size && boardHeight.value == (height ?? size)) {
      return;
    }
    boardWidth.value = size;
    boardHeight.value = height ?? size;
    anim.setBoardSize(width: boardWidth.value, height: boardHeight.value);
    if (currentChallenge.value != null &&
        currentMiniGame.value?.displayType != 'math_equation') {
      setGuideForCharacter(currentChallenge.value!.target);
    }
  }

  void onPointerDown() {
    _idleTimer?.cancel();
    anim.stopGuide();
    _cancelPredictIfAny();
  }

  Future<void> onPointerUp() async {
    if (!hasDrawnStroke) return;
    if (!isGameActive.value || isGameOver.value || isPaused.value) return;
    _idleTimer?.cancel();
    if (_rawStrokes.isEmpty) return;
  }

  void onRawPointerDown(PointerDownEvent e) {
    _currentStroke = [];
    final now = DateTime.now().millisecondsSinceEpoch;
    _currentStroke!.add({
      "x": e.localPosition.dx,
      "y": e.localPosition.dy,
      "time": now,
    });
    hasDrawnStroke = true;
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

  void clearBoard() {
    drawingController.clear();
    hasDrawnStroke = false;
    _idleTimer?.cancel();
    _rawStrokes.clear();
    _currentStroke = null;

    if (currentMiniGame.value?.displayType != 'math_equation') {
      anim.restartGuideFromStart();
    }
  }

  // ── Submit / AI check ──

  Future<void> forceSubmit() async {
    if (!isGameActive.value || isGameOver.value || isPaused.value) return;
    _idleTimer?.cancel();

    if (currentInputType.value == 'drawing_board') {
      if (_rawStrokes.isEmpty) {
        _applyWrongResult();
        return;
      }
      await _checkDrawing();
    }
  }

  /// Handle multiple choice answer
  void submitMultipleChoice(String selectedAnswer) {
    if (!isGameActive.value || isGameOver.value || isPaused.value) return;
    final challenge = currentChallenge.value;
    if (challenge == null) return;

    totalAnswered.value++;

    if (selectedAnswer == challenge.target) {
      _applyCorrectResult();
    } else {
      _applyWrongResult();
    }
  }

  Future<void> _checkDrawing() async {
    if (!isGameActive.value || isGameOver.value) return;

    _cancelPredictIfAny();
    final myReqId = ++_reqId;
    final cancelToken = CancelToken();
    _cancelToken = cancelToken;

    final challenge = currentChallenge.value;
    if (challenge == null) return;

    // Determine model type based on display type
    final modelType = _getModelTypeForDisplay();
    final expectedChar = challenge.target;

    bool isCorrect = false;

    try {
      // Try local ONNX first
      Map<String, dynamic>? data = await _predictLocal(modelType);

      if (data == null) {
        // Fall back to server
        final payload = _getXYStrokeWithTime(modelType: modelType);
        final strokes =
            (payload['strokes'] as List).cast<Map<String, dynamic>>();
        data = await _worldService.predictDrawingVector(
          strokes: strokes,
          modelType: payload['model_type'] as String,
          cancelToken: cancelToken,
        );
      }

      if (myReqId != _reqId) return;

      final prediction = (data['prediction'] ?? '').toString().trim();
      isCorrect = prediction == expectedChar.trim();
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) return;
    } catch (e) {
      dev.log('Predict failed: $e', name: 'DynamicMiniGameController');
      isCorrect = (Random().nextDouble() <= 0.9);
    } finally {
      if (myReqId == _reqId) _cancelToken = null;
    }

    totalAnswered.value++;

    if (isCorrect) {
      _applyCorrectResult();
    } else {
      _applyWrongResult();
    }

    hasDrawnStroke = false;
  }

  /// Khmer digit codepoints: ០ (U+17E0) through ៩ (U+17E9)
  static const _khmerDigits = {'០', '១', '២', '៣', '៤', '៥', '៦', '៧', '៨', '៩'};

  String _getModelTypeForDisplay() {
    final dt = currentMiniGame.value?.displayType;

    // Legacy explicit types
    if (dt == 'number' || dt == 'math_equation') return 'digit';

    // For generic 'character' display type, inspect the pool to decide
    if (dt == 'character') {
      final pool = (currentMiniGame.value?.config?['pool'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];
      if (pool.isNotEmpty && pool.every((c) => _khmerDigits.contains(c))) {
        return 'digit';
      }
    }

    return 'consonant';
  }

  void _applyCorrectResult() {
    correctCount.value++;

    // Update combo
    combo.value++;
    if (combo.value > bestCombo.value) {
      bestCombo.value = combo.value;
    }

    // Calculate score with combo multiplier
    final comboMultiplier = 1.0 + (combo.value - 1) * 0.1;
    final earnedScore = (10 * comboMultiplier).round();
    score.value += earnedScore;

    // Add time
    timeLeft.value =
        (timeLeft.value + timeRewardCorrect).clamp(0.0, maxTime.value);

    // Show feedback
    isCorrectFeedback.value = true;
    feedbackText.value = combo.value >= 3 ? '🔥 x${combo.value}!' : 'Correct!';
    feedbackTrigger.value++;

    audio.playCorrectSfx();
    anim.showCorrect(starIndex: 0);

    // Next challenge after a brief delay
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!isGameActive.value || isGameOver.value) return;
      anim.feedback.value = DrawFeedback.none;
      anim.clearPraise();
      _pickNextChallenge();
    });
  }

  void _applyWrongResult() {
    wrongCount.value++;

    // Break combo
    combo.value = 0;

    // Time penalty
    timeLeft.value =
        (timeLeft.value + timePenaltyWrong).clamp(0.0, maxTime.value);

    // Show feedback
    isCorrectFeedback.value = false;
    feedbackText.value = 'Wrong!';
    feedbackTrigger.value++;

    audio.playWrongSfx();

    anim.showWrongAndReset(
      customDuration: const Duration(milliseconds: 500),
      onAfterReset: () {
        clearBoard();
        if (currentMiniGame.value?.displayType != 'math_equation') {
          anim.restartGuideFromStart();
        }
      },
    );

    // Pick next after a brief delay
    Future.delayed(const Duration(milliseconds: 700), () {
      if (!isGameActive.value || isGameOver.value) return;
      anim.feedback.value = DrawFeedback.none;
      anim.clearPraise();
      _pickNextChallenge();
    });

    if (timeLeft.value <= 0) {
      endGame();
    }
  }

  // ── Stroke DB & Guide ──

  Future<void> _loadStrokeDb() async {
    if (_strokesDbCache != null) return;
    final raw = await rootBundle.loadString('assets/strokes/strokes.json');
    _strokesDbCache = jsonDecode(raw) as Map<String, dynamic>;
  }

  void setGuideForCharacter(String ch) {
    if (_strokesDbCache == null) {
      _loadStrokeDb().then((_) {
        if (currentChallenge.value?.target == ch) {
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

    // Parse strokes
    final rawStrokes = entry['strokes'] as List<dynamic>? ?? [];
    final parsedStrokesPx = <List<Offset>>[];

    for (final s in rawStrokes) {
      final pts = <Offset>[];
      if (s is List) {
        for (final p in s) {
          if (p is Map<String, dynamic>) {
            final x = ((p['x'] as num?) ?? 0).toDouble();
            final y = ((p['y'] as num?) ?? 0).toDouble();
            pts.add(Offset(x * boardWidth.value, y * boardHeight.value));
          }
        }
      }
      if (pts.isNotEmpty) parsedStrokesPx.add(pts);
    }

    strokeStrokesNorm.value = parsedStrokesPx;

    // Parse subpaths for the letter fill
    final rawSub = entry['subpaths'] as List<dynamic>? ?? [];
    final parsedSubpaths = <List<Offset>>[];
    for (final s in rawSub) {
      final pts = <Offset>[];
      if (s is List) {
        for (final p in s) {
          if (p is Map<String, dynamic>) {
            final x = ((p['x'] as num?) ?? 0).toDouble();
            final y = ((p['y'] as num?) ?? 0).toDouble();
            pts.add(Offset(x * boardWidth.value, y * boardHeight.value));
          }
        }
      }
      if (pts.isNotEmpty) parsedSubpaths.add(pts);
    }

    letterSubpathsNorm.value = parsedSubpaths;
    anim.setGuideFromPx(strokesPx: parsedStrokesPx);
  }

  // ── Local ONNX prediction ──

  Future<Map<String, dynamic>?> _predictLocal(String modelType) async {
    try {
      if (!OnnxInferenceService.instance.isReady) {
        return null;
      }

      final preprocessed = StrokePreprocessor.preprocessForModel(
        modelType,
        _rawStrokes,
      );

      final result = await OnnxInferenceService.instance.predict(
        modelType,
        preprocessed.segments[0],
        preprocessed.shapes[0],
      );

      return result;
    } catch (e) {
      dev.log('Local predict failed: $e', name: 'DynamicMiniGameController');
      return null;
    }
  }

  Map<String, dynamic> _getXYStrokeWithTime({required String modelType}) {
    final allStrokes = <Map<String, dynamic>>[];
    for (int si = 0; si < _rawStrokes.length; si++) {
      final stroke = _rawStrokes[si];
      for (final point in stroke) {
        allStrokes.add({
          'x': point['x'],
          'y': point['y'],
          'time': point['time'],
          'stroke_index': si,
        });
      }
    }
    return {
      'strokes': allStrokes,
      'model_type': modelType,
    };
  }

  void _cancelPredictIfAny() {
    _cancelToken?.cancel();
    _cancelToken = null;
  }

  @override
  void onClose() {
    isCountingDown.value = false;
    _gameTimer?.cancel();
    _idleTimer?.cancel();
    _cancelPredictIfAny();
    feedbackAnimCtrl.dispose();
    promptBounceCtrl.dispose();
    countdownAnimCtrl.dispose();
    drawingController.dispose();
    if (_ownsAnim && Get.isRegistered<StageAnimationController>()) {
      Get.delete<StageAnimationController>();
    }
    if (_ownsAudio && Get.isRegistered<StageAudioController>()) {
      Get.delete<StageAudioController>();
    }
    super.onClose();
  }
}
