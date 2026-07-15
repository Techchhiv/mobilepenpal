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
import 'package:mobilepenpal/core/utils/adventure_shadow_score_util.dart';
import 'package:mobilepenpal/core/utils/stroke_preprocessor.dart';
import 'package:mobilepenpal/data/controllers/mini_game/adventure/adventure_controller.dart';
import 'package:mobilepenpal/data/controllers/home/home_controller.dart';
import 'package:mobilepenpal/data/controllers/shop/shop_controller.dart';
import 'package:mobilepenpal/data/controllers/world/stage_animation_controller.dart';
import 'package:mobilepenpal/data/controllers/world/stage_audio_controller.dart';
import 'package:mobilepenpal/data/models/exercise/exercise.dart';
import 'package:mobilepenpal/data/models/student/student.dart';
import 'package:mobilepenpal/data/services/onnx_inference_service.dart';
import 'package:mobilepenpal/data/services/world_service.dart';
import 'package:mobilepenpal/presentation/widgets/world/image_stamp_content.dart';
import 'package:mobilepenpal/presentation/widgets/app_snackbar.dart';

/// Rating tiers based on drawing accuracy
enum DrawRating { perfect, good, okay, miss }

/// Difficulty tiers that scale during gameplay
enum SprintDifficulty {
  /// Shadow guide + letter prompt visible
  easy,

  /// No shadow guide, letter prompt still visible
  medium,

  /// No shadow guide, no letter prompt — audio only
  hard,
}

/// Types of collectible power-ups
enum PowerUpType { timePlus, score2x, freeze, shield }

/// Controller for the "Drawing Sprint" endless game mode.
class AdventureStageController extends GetxController
    with GetTickerProviderStateMixin {
  final WorldService _worldService = WorldService();
  final GetStorage _box = GetStorage();

  // ── Storage keys ──
  static const String _highScoreKey = 'sprint_high_score';
  static const String _bestComboKey = 'sprint_best_combo';
  static const String _gamesPlayedKey = 'sprint_games_played';

  // ── Timer constants ──
  static const double initialTimerDuration = 30.0; // seconds
  static const double minTimerDuration = 5.0;
  static const double timerTickInterval = 0.05; // 50ms ticks
  // Time rewards/penalties
  static const Map<DrawRating, double> timeRewards = {
    DrawRating.perfect: 5.0,
    DrawRating.good: 3.0,
    DrawRating.okay: 2.0,
    DrawRating.miss: -2.0,
  };
  // Score rewards
  static const Map<DrawRating, int> baseScoreRewards = {
    DrawRating.perfect: 15,
    DrawRating.good: 10,
    DrawRating.okay: 5,
    DrawRating.miss: 0,
  };

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

  // ── Animation Controllers (View State) ──
  late final AnimationController feedbackAnimCtrl;
  late final AnimationController promptBounceCtrl;
  late final AnimationController countdownAnimCtrl;

  // ── Countdown State ──
  final countdownValue = 3.obs;
  final isCountingDown = true.obs;
  bool _countdownStarted = false;

  // Score
  final score = 0.obs;
  final combo = 0.obs;
  final bestCombo = 0.obs;
  final highScore = 0.obs;

  // Stats for results screen
  final totalDrawn = 0.obs;
  final perfectCount = 0.obs;
  final goodCount = 0.obs;
  final okayCount = 0.obs;
  final missCount = 0.obs;
  final earnedCoins = 0.obs;
  final charactersPracticed = <String>[].obs;

  double get accuracy {
    if (totalDrawn.value == 0) return 0.0;
    final correct = perfectCount.value + goodCount.value + okayCount.value;
    return (correct / totalDrawn.value * 100.0);
  }

  // Current prompt
  final selectedCharacter = ''.obs;
  final currentCharacterType = ''.obs;

  // Drawing board
  final boardWidth = 340.0.obs;
  final boardHeight = 340.0.obs;
  final letterSubpathsNorm = <List<Offset>>[].obs;
  final strokeStrokesNorm = <List<Offset>>[].obs;
  double get scale => boardWidth.value / 340.0;

  final List<DrawingController> drawingControllers = List.generate(
    3,
    (_) => DrawingController(),
  );
  int get activeBoardCount => 1;

  final lastRating = Rxn<DrawRating>();
  final lastRatingText = ''.obs;
  final lastRatingAlignment = const Alignment(0.0, 0.0).obs;
  final feedbackTrigger = 0.obs;

  // ── Difficulty ──
  final difficulty = SprintDifficulty.easy.obs;
  int _correctStreakForDifficulty = 0;

  /// Consecutive correct answers needed to advance to the next difficulty tier
  static const int _mediumThreshold = 4;
  static const int _hardThreshold = 8;

  /// Whether to show the shadow guide on the drawing board
  bool get showShadowGuide => difficulty.value == SprintDifficulty.easy;

  /// Whether to show the letter prompt above the drawing board
  bool get showLetterPrompt => difficulty.value != SprintDifficulty.hard;

  // ── Power-Ups ──
  Timer? _powerUpSpawnTimer;
  Timer? _powerUpDespawnTimer;

  // Currently spawned (waiting to be tapped)
  final spawnedPowerUp = Rxn<PowerUpType>();
  final powerUpAlignment = const Alignment(0.0, 0.0).obs;

  // Active Buffs state
  final hasShield = false.obs;

  final isScore2xActive = false.obs;
  final score2xTimeLeft = 0.0.obs;
  final score2xMaxDuration = 10.0.obs;

  final isFreezeActive = false.obs;
  final freezeTimeLeft = 0.0.obs;
  final freezeMaxDuration = 7.0.obs;

  // Raw stroke tracking
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
  Timer? _idleTimer;
  CancelToken? _cancelToken;
  int _redId = 0;

  // Stroke database
  static Map<String, dynamic>? _strokesDbCache;

  // Available exercises pool
  final List<Exercise> _exercisePool = [];

  // Animation & Audio controllers
  late StageAnimationController anim;
  bool _ownsAnim = false;
  late StageAudioController audio;
  bool _ownsAudio = false;

  ui.Image? _currentStampImage;
  ui.Image? get currentStampImage => _currentStampImage;

  @override
  void onInit() {
    super.onInit();

    for (var c in drawingControllers) {
      c.setStyle(color: Colors.black, strokeWidth: 6);
    }

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

    // Listen to feedback trigger to fire animation reliably
    ever(feedbackTrigger, (_) {
      if (feedbackTrigger.value > 0) {
        feedbackAnimCtrl.forward(from: 0);
      }
    });

    // Auto-start game with countdown when loading finishes
    ever(isLoading, (bool loading) {
      if (!loading && !_countdownStarted) {
        _countdownStarted = true;
        startGame();
        pauseGame();
        _startCountdown();
      }
    });

    // Check if already loaded (hot reload case)
    if (!isLoading.value && !_countdownStarted) {
      _countdownStarted = true;
      Future.delayed(const Duration(milliseconds: 100), () {
        startGame();
        pauseGame();
        _startCountdown();
      });
    }

    _initGame();
  }

  void _startCountdown() {
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
          countdownValue.value = 0; // "GO!"
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
      await _loadStrokeDb();
      await _loadExercisePool();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadExercisePool() async {
    if (Get.isRegistered<AdventureController>()) {
      final adventureCtrl = Get.find<AdventureController>();
      _exercisePool.clear();
      _exercisePool.addAll(adventureCtrl.allExercises);
    }

    if (_exercisePool.isEmpty) {
      // Fetch directly
      try {
        final response = await _worldService.getExercises();
        if (response.code == 200 && response.data != null) {
          _exercisePool.addAll(response.data!);
        }
      } catch (e) {
        dev.log(
          'Failed to load exercises: $e',
          name: 'AdventureStageController',
        );
      }
    }

    dev.log(
      'Exercise pool loaded: ${_exercisePool.length} exercises',
      name: 'AdventureStageController',
    );
  }

  // ── Game lifecycle ──

  void startGame() {
    // Reset all state
    score.value = 0;
    combo.value = 0;
    bestCombo.value = 0;
    totalDrawn.value = 0;
    perfectCount.value = 0;
    goodCount.value = 0;
    okayCount.value = 0;
    missCount.value = 0;
    earnedCoins.value = 0;
    charactersPracticed.clear();
    lastRating.value = null;
    lastRatingText.value = '';

    timeLeft.value = initialTimerDuration;
    maxTime.value = initialTimerDuration;
    isGameOver.value = false;
    isPaused.value = false;
    isGameActive.value = true;

    anim.feedback.value = DrawFeedback.none;
    anim.clearPraise();

    // Reset difficulty
    difficulty.value = SprintDifficulty.easy;
    _correctStreakForDifficulty = 0;

    // Reset power-ups
    spawnedPowerUp.value = null;
    hasShield.value = false;
    isScore2xActive.value = false;
    score2xTimeLeft.value = 0.0;
    score2xMaxDuration.value = 10.0;
    isFreezeActive.value = false;
    freezeTimeLeft.value = 0.0;
    freezeMaxDuration.value = 7.0;

    _pickNextCharacter();
    _startTimer();
    _startPowerUpSpawner();
  }

  void pauseGame() {
    if (!isGameActive.value || isGameOver.value) return;
    isPaused.value = true;
    _gameTimer?.cancel();
    _powerUpSpawnTimer?.cancel();
    _powerUpDespawnTimer?.cancel();
  }

  void resumeGame() {
    if (!isGameActive.value || isGameOver.value) return;
    isPaused.value = false;
    _startTimer();
    _startPowerUpSpawner();
    // Re-trigger despawn if one was active (simplified: just let it wait for the next tick to clear or keep it forever until tapped if resumed)
  }

  void endGame() {
    _gameTimer?.cancel();
    _idleTimer?.cancel();
    _powerUpSpawnTimer?.cancel();
    _powerUpDespawnTimer?.cancel();
    _cancelPredictIfAny();
    isGameActive.value = false;
    isGameOver.value = true;

    // Update high score
    if (score.value > highScore.value) {
      highScore.value = score.value;
      _box.write(_highScoreKey, highScore.value);
    }

    // Update best combo
    final savedBestCombo = _box.read<int>(_bestComboKey) ?? 0;
    if (bestCombo.value > savedBestCombo) {
      _box.write(_bestComboKey, bestCombo.value);
    }

    // Increment games played
    final gamesPlayed = (_box.read<int>(_gamesPlayedKey) ?? 0) + 1;
    _box.write(_gamesPlayedKey, gamesPlayed);

    // Calculate coins: 1 coin per 10 score
    earnedCoins.value = (score.value / 10).floor();

    // Submit results to backend
    _submitResults();
  }

  void _startTimer() {
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(
      Duration(milliseconds: (timerTickInterval * 1000).round()),
      (_) {
        if (isPaused.value) return;

        // Process freeze buff
        if (isFreezeActive.value) {
          freezeTimeLeft.value -= timerTickInterval;
          if (freezeTimeLeft.value <= 0) {
            freezeTimeLeft.value = 0;
            isFreezeActive.value = false;
          }
        } else {
          // Normal timer ticking
          timeLeft.value -= timerTickInterval;
          if (timeLeft.value <= 0) {
            timeLeft.value = 0;
            endGame();
            return;
          }
        }

        // Process score 2x buff
        if (isScore2xActive.value) {
          score2xTimeLeft.value -= timerTickInterval;
          if (score2xTimeLeft.value <= 0) {
            score2xTimeLeft.value = 0;
            isScore2xActive.value = false;
          }
        }
      },
    );
  }

  // ── Power-Ups Mechanics ──

  void _startPowerUpSpawner() {
    _powerUpSpawnTimer?.cancel();
    // Try to spawn a power-up
    final int delayMs = Random().nextInt(5000) + 5000;
    _powerUpSpawnTimer = Timer(Duration(milliseconds: delayMs), () {
      if (!isGameActive.value || isGameOver.value || isPaused.value) return;
      _spawnPowerUp();
      _startPowerUpSpawner();
    });
  }

  void _spawnPowerUp() {
    // Pick random type, but exclude already active buffs
    final availableTypes = PowerUpType.values.where((t) {
      if (t == PowerUpType.score2x && isScore2xActive.value) return false;
      if (t == PowerUpType.freeze && isFreezeActive.value) return false;
      if (t == PowerUpType.shield && hasShield.value) return false;
      return true; // timePlus has no duration, can always spawn
    }).toList();

    if (availableTypes.isEmpty) return; // All buffs active!

    final type = availableTypes[Random().nextInt(availableTypes.length)];

    // Spawn at random location around the prompt
    powerUpAlignment.value = Alignment(
      (Random().nextDouble() * 1.6) - 0.8, // X: left to right (-0.8 to 0.8)
      (Random().nextDouble() * -0.6) - 0.2, // Y: upper half
    );
    spawnedPowerUp.value = type;

    // Optional: play a subtle 'spawn' UI sound
    // audio.playBubbleSfx();

    // Despawn after 5 seconds if not collected
    _powerUpDespawnTimer?.cancel();
    _powerUpDespawnTimer = Timer(const Duration(seconds: 5), () {
      if (spawnedPowerUp.value == type) {
        spawnedPowerUp.value = null;
      }
    });
  }

  void collectPowerUp() {
    if (spawnedPowerUp.value == null) return;

    final type = spawnedPowerUp.value!;
    spawnedPowerUp.value = null;
    _powerUpDespawnTimer?.cancel();

    // Play collect SFX
    audio
        .playCorrectSfx(); // Reusing correct sfx for now, or use a specific one

    // Get upgrade level (mocked to 1 for now, will connect to ShopController later)
    int upgradeLevel = 1;

    switch (type) {
      case PowerUpType.timePlus:
        // Level 1: +5s, Level 2: +7s, Level 3: +10s
        double addedTime = 5.0 + ((upgradeLevel - 1) * 2.5);
        timeLeft.value = (timeLeft.value + addedTime).clamp(0.0, maxTime.value);
        break;
      case PowerUpType.score2x:
        // Level 1: 10s, Level 2: 15s
        double duration = 10.0 + ((upgradeLevel - 1) * 5.0);
        isScore2xActive.value = true;
        score2xTimeLeft.value = duration;
        score2xMaxDuration.value = duration;
        break;
      case PowerUpType.freeze:
        // Level 1: 7s, Level 2: 10s
        double dur = 7.0 + ((upgradeLevel - 1) * 3.0);
        isFreezeActive.value = true;
        freezeTimeLeft.value = dur;
        freezeMaxDuration.value = dur;
        break;
      case PowerUpType.shield:
        // Shields don't really have duration, they block next hit.
        hasShield.value = true;
        break;
    }
  }

  // ── Character selection ──

  void _pickNextCharacter() {
    if (_exercisePool.isEmpty) return;

    final rng = Random();

    // Determine difficulty randomly based on the current streak tier
    if (_correctStreakForDifficulty >= _hardThreshold) {
      // 8+ Combo: 20% Hard, 40% Medium, 40% Easy
      final roll = rng.nextDouble();
      if (roll < 0.20) {
        difficulty.value = SprintDifficulty.hard;
      } else if (roll < 0.60) {
        difficulty.value = SprintDifficulty.medium;
      } else {
        difficulty.value = SprintDifficulty.easy;
      }
    } else if (_correctStreakForDifficulty >= _mediumThreshold) {
      // 5-7 Combo: 40% Medium, 60% Easy
      final roll = rng.nextDouble();
      if (roll < 0.40) {
        difficulty.value = SprintDifficulty.medium;
      } else {
        difficulty.value = SprintDifficulty.easy;
      }
    } else {
      // < 5 Combo: 100% Easy
      difficulty.value = SprintDifficulty.easy;
    }

    final exercise = _exercisePool[rng.nextInt(_exercisePool.length)];

    // Filter out math for now (sprint only does drawing)
    final type = (exercise.characterType ?? '').trim().toLowerCase();
    if (type == 'math') {
      _pickNextCharacter(); // re-roll
      return;
    }

    selectedCharacter.value = exercise.character;
    currentCharacterType.value = exercise.characterType ?? 'consonants';

    clearBoard();
    setGuideForCharacter(selectedCharacter.value);

    // Track character practiced
    if (!charactersPracticed.contains(exercise.character)) {
      charactersPracticed.add(exercise.character);
    }

    // Play audio for the character ONLY on hard mode where there is no letter prompt
    if (difficulty.value == SprintDifficulty.hard) {
      audio.autoPlayCharacter(
        type: exercise.characterType ?? '',
        ch: exercise.character,
      );
    }
  }

  // ── Drawing input (auto-submit on pointer up, same as stage_detail) ──

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

  void onPointerDown() {
    _idleTimer?.cancel();
    anim.stopGuide();
    _cancelPredictIfAny();
  }

  Future<void> onPointerUp() async {
    if (!hasDrawnAnyStroke) return;
    if (!isGameActive.value || isGameOver.value || isPaused.value) return;

    _idleTimer?.cancel();

    // Check all boards have strokes
    for (int i = 0; i < activeBoardCount; i++) {
      if (_rawStrokesList[i].isEmpty) return;
    }

    // Check minimum stroke distance
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
      anim.restartGuideFromStart();
      return;
    }
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

  void clearBoard() {
    for (var c in drawingControllers) {
      c.clear();
    }
    hasDrawnStrokeList.fillRange(0, hasDrawnStrokeList.length, false);
    _idleTimer?.cancel();
    for (int i = 0; i < _rawStrokesList.length; i++) {
      _rawStrokesList[i].clear();
      _currentStrokeList[i] = null;
    }

    if (_currentStampImage != null) {
      _applyStampBrush();
    }

    anim.restartGuideFromStart();
    anim.resetMorph();
  }

  // ── AI check ──

  Future<void> forceSubmit() async {
    if (!isGameActive.value || isGameOver.value || isPaused.value) return;
    _idleTimer?.cancel();

    bool isEmpty = true;
    for (int i = 0; i < activeBoardCount; i++) {
      if (_rawStrokesList[i].isNotEmpty) {
        isEmpty = false;
        break;
      }
    }

    if (isEmpty) {
      _applyMissResult();
      return;
    }

    await _checkDrawing();
    hasDrawnStrokeList.fillRange(0, hasDrawnStrokeList.length, false);
  }

  Future<void> _checkDrawing() async {
    if (!isGameActive.value || isGameOver.value) return;

    _cancelPredictIfAny();
    final myReqId = ++_redId;
    final cancelToken = CancelToken();
    _cancelToken = cancelToken;

    final modelType = _mapCharacterTypeToModelType(currentCharacterType.value);
    final expectedChar = selectedCharacter.value;

    bool isCorrect = false;
    String prediction = '';

    final isSupported = OnnxInferenceService.instance.supportsCharacter(expectedChar, modelType);

    if (!isSupported) {
      isCorrect = _rawStrokesList[0].isNotEmpty;
      prediction = expectedChar;
      if (myReqId == _redId) _cancelToken = null;
    } else {
      try {
        // Try local ONNX first
        Map<String, dynamic>? data = await _predictLocal(modelType, 0);

        if (data == null) {
          // Fall back to server
          final payload = _getXYStrokeWithTime(modelType: modelType);
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
        isCorrect = prediction == expectedChar.trim();
      } on DioException catch (e) {
        if (CancelToken.isCancel(e)) return;
      } catch (e) {
        dev.log('Predict failed: $e', name: 'AdventureStageController');
        isCorrect = false;
        AppSnackbar.show(
          'Failed to evaluate drawing. Please try again.',
          title: 'Error',
          backgroundColor: Colors.red,
        );
      } finally {
        if (myReqId == _redId) _cancelToken = null;
      }
    }

    totalDrawn.value++;

    if (isCorrect) {
      // Calculate shadow score for rating
      final shadowScore = AdventureShadowScoreUtil.calculate(
        userRawStrokes: _rawStrokesList[0],
        templateStrokesPx: strokeStrokesNorm,
        boardWidth: boardWidth.value,
        boardHeight: boardHeight.value,
      );

      final rating = _getRating(shadowScore.iou);
      _applyCorrectResult(rating);
    } else {
      _applyMissResult();
    }
  }

  DrawRating _getRating(double iou) {
    if (iou >= 0.60) return DrawRating.perfect;
    if (iou >= 0.40) return DrawRating.good;
    if (iou >= 0.20) return DrawRating.okay;
    return DrawRating.miss;
  }

  void _applyCorrectResult(DrawRating rating) {
    // Update rating counts
    switch (rating) {
      case DrawRating.perfect:
        perfectCount.value++;
        break;
      case DrawRating.good:
        goodCount.value++;
        break;
      case DrawRating.okay:
        okayCount.value++;
        break;
      case DrawRating.miss:
        missCount.value++;
        break;
    }

    // Update combo
    combo.value++;
    if (combo.value > bestCombo.value) {
      bestCombo.value = combo.value;
    }

    // Calculate score with combo multiplier
    final comboMultiplier = 1.0 + (combo.value - 1) * 0.1;
    final baseScore = baseScoreRewards[rating] ?? 10;

    // Apply 2x Score Power-up if active
    final powerUpMultiplier = isScore2xActive.value ? 2 : 1;

    final earnedScore = ((baseScore * comboMultiplier) * powerUpMultiplier)
        .round();
    score.value += earnedScore;

    // Add time
    final timeReward = timeRewards[rating] ?? 0.0;
    timeLeft.value = (timeLeft.value + timeReward).clamp(0.0, maxTime.value);

    // Show feedback
    lastRating.value = rating;
    lastRatingAlignment.value = Alignment(
      (Random().nextDouble() * 0.4) - 0.2, // Random X between -0.2 and 0.2
      (Random().nextDouble() * 0.4) - 0.2, // Random Y between -0.2 and 0.2
    );
    switch (rating) {
      case DrawRating.perfect:
        lastRatingText.value = 'PERFECT!';
        break;
      case DrawRating.good:
        lastRatingText.value = 'Good!';
        break;
      case DrawRating.okay:
        lastRatingText.value = 'Okay';
        break;
      case DrawRating.miss:
        lastRatingText.value = 'Miss';
        break;
    }
    feedbackTrigger.value++;

    // Play correct SFX
    audio.playCorrectSfx();

    final bool hasGuide = showShadowGuide && strokeStrokesNorm.isNotEmpty;
    if (hasGuide && _rawStrokesList[0].isNotEmpty) {
      final userOffsets = _rawStrokesList[0]
          .map((stroke) => stroke
              .map((p) => Offset(
                    (p['x'] as num).toDouble(),
                    (p['y'] as num).toDouble(),
                  ))
              .toList())
          .toList();

      unawaited(anim.startMorph(
        userStrokes: userOffsets,
        templateStrokes: List<List<Offset>>.from(strokeStrokesNorm),
      ));
    }

    // Show correct animation
    anim.showCorrect(starIndex: 0);

    // Next character after a brief delay
    final delayMs = hasGuide ? 1000 : 600;
    Future.delayed(Duration(milliseconds: delayMs), () {
      if (!isGameActive.value || isGameOver.value) return;
      anim.feedback.value = DrawFeedback.none;
      anim.clearPraise();
      anim.resetMorph();

      // Update difficulty based on correct streak
      _correctStreakForDifficulty++;

      _pickNextCharacter();
    });
  }

  void _applyMissResult() {
    missCount.value++;
    totalDrawn.value; // already incremented

    if (hasShield.value) {
      // Consume shield and protect combo/time
      hasShield.value = false;
      lastRating.value =
          DrawRating.okay; // Consider it an "okay" or "protected shield"
      lastRatingText.value = 'Shielded!';
      lastRatingAlignment.value = Alignment(
        (Random().nextDouble() * 0.4) - 0.2,
        (Random().nextDouble() * 0.4) - 0.2,
      );
      feedbackTrigger.value++;
      audio.playCorrectSfx(); // Change later to shield SFX

      // Still show wrong guide to teach them, but clear right after
      anim.showWrongAndReset(
        customDuration: const Duration(milliseconds: 500),
        onAfterReset: () {
          clearBoard();
          anim.restartGuideFromStart();
        },
      );

      Future.delayed(const Duration(milliseconds: 700), () {
        if (!isGameActive.value || isGameOver.value) return;
        anim.feedback.value = DrawFeedback.none;
        anim.clearPraise();
        _pickNextCharacter();
      });
      return;
    }

    // Break combo
    combo.value = 0;

    // Reset difficulty streak back to complete ease
    _correctStreakForDifficulty = 0;

    // Lose time
    final timePenalty = timeRewards[DrawRating.miss] ?? -2.0;
    timeLeft.value = (timeLeft.value + timePenalty).clamp(0.0, maxTime.value);

    lastRating.value = DrawRating.miss;
    lastRatingText.value = 'Miss';
    lastRatingAlignment.value = Alignment(
      (Random().nextDouble() * 0.4) - 0.2,
      (Random().nextDouble() * 0.4) - 0.2,
    );
    feedbackTrigger.value++;

    // Play wrong SFX
    audio.playWrongSfx();

    // Show wrong animation
    anim.showWrongAndReset(
      customDuration: const Duration(milliseconds: 500),
      onAfterReset: () {
        clearBoard();
        anim.restartGuideFromStart();
      },
    );

    // Pick next after a brief delay
    Future.delayed(const Duration(milliseconds: 700), () {
      if (!isGameActive.value || isGameOver.value) return;
      anim.feedback.value = DrawFeedback.none;
      anim.clearPraise();
      _pickNextCharacter();
    });

    // Check if time ran out
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
    );

    final fittedLetter = fitted.take(letterOut.length).toList();
    final fittedStrokes = fitted.skip(letterOut.length).toList();

    letterSubpathsNorm.assignAll(fittedLetter);
    strokeStrokesNorm.assignAll(fittedStrokes);
    anim.setGuideFromPx(strokesPx: fittedStrokes);

    // Load stamp image for the character
    _loadStampImage();
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

  // ── Helper methods ──

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
      dev.log('Local ONNX failed: $e', name: 'AdventureStageController');
      return null;
    }
  }

  Map<String, dynamic> _getXYStrokeWithTime({
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

  String _mapCharacterTypeToModelType(String characterType) {
    final t = characterType.trim().toLowerCase();
    switch (t) {
      case 'digits':
        return 'digit';
      case 'consonants':
        return 'consonant';
      case 'independent_vowels':
        return 'independent_vowel';
      case 'dependent_vowels':
        return 'dependent_vowel';
      default:
        return 'consonant';
    }
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
    double pad = 24,
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

  Future<void> _submitResults() async {
    if (earnedCoins.value <= 0 && score.value <= 0) return;

    try {
      // Sync coins with backend
      if (earnedCoins.value > 0 && Get.isRegistered<HomeController>()) {
        final homeController = Get.find<HomeController>();
        final currentStudent = homeController.student.value;

        if (currentStudent != null) {
          final newCoin = currentStudent.coin + earnedCoins.value;
          final updatedStudent = Student.fromJson({
            ...currentStudent.toJson(),
            'coin': newCoin,
          });
          homeController.student.value = updatedStudent;
          await _box.write('student', updatedStudent.toJson());

          if (Get.isRegistered<ShopController>()) {
            Get.find<ShopController>().totalPoints.value = newCoin;
            await _box.write('adventure_points', newCoin);
          }
        }
      }
    } catch (e) {
      dev.log(
        'Failed to submit sprint results: $e',
        name: 'AdventureStageController',
      );
    }
  }

  // ── Getters for saved stats ──
  int get savedBestCombo => _box.read<int>(_bestComboKey) ?? 0;
  int get gamesPlayed => _box.read<int>(_gamesPlayedKey) ?? 0;

  @override
  void onClose() {
    _gameTimer?.cancel();
    _idleTimer?.cancel();
    for (var c in drawingControllers) {
      c.dispose();
    }
    _cancelPredictIfAny();
    audio.stopAll();

    feedbackAnimCtrl.dispose();
    promptBounceCtrl.dispose();
    countdownAnimCtrl.dispose();

    if (_ownsAnim && Get.isRegistered<StageAnimationController>()) {
      Get.delete<StageAnimationController>();
    }
    if (_ownsAudio && Get.isRegistered<StageAudioController>()) {
      Get.delete<StageAudioController>();
    }

    super.onClose();
  }
}
