import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_drawing_board/flutter_drawing_board.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mobilepenpal/core/utils/stroke_feedback_util.dart';
import 'package:mobilepenpal/core/utils/stroke_transform_util.dart';
import 'package:mobilepenpal/data/controllers/world/stage_animation_controller.dart';
import 'package:mobilepenpal/data/controllers/world/stage_audio_controller.dart';
import 'package:mobilepenpal/data/models/mini_game/challenge_generator.dart';
import 'package:mobilepenpal/data/models/api_response.dart';
import 'package:mobilepenpal/data/models/mini_game/mini_game_model.dart';
import 'package:mobilepenpal/data/services/drawing_evaluation_service.dart';
import 'package:mobilepenpal/data/services/world_service.dart';

/// A floating "+N" popup that animates from a spawn position up to the score bar.
class FloatingScoreEvent {
  final int id;
  final int points;
  final double startX; // 0.0–1.0 fraction of screen width
  final double startY; // 0.0–1.0 fraction of screen height
  FloatingScoreEvent({
    required this.id,
    required this.points,
    required this.startX,
    required this.startY,
  });
}

/// Controller for the dynamic endless mini-game mode.
class DynamicMiniGameController extends GetxController
    with GetTickerProviderStateMixin {
  final WorldService _worldService = WorldService();
  late final DrawingEvaluationService _evalService = DrawingEvaluationService(
    worldService: _worldService,
  );
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

  // ── Difficulty ──
  final difficulty = MiniGameDifficulty.easy.obs;
  int _correctStreakForDifficulty = 0;

  /// Consecutive correct answers needed to advance to the next difficulty tier
  static const int _mediumThreshold = 4;
  static const int _hardThreshold = 8;

  /// Whether to show the shadow guide on the drawing board
  bool get showShadowGuide => difficulty.value == MiniGameDifficulty.easy;

  /// Whether to show the letter/character prompt above the drawing board.
  /// On Easy: always visible. On Medium: visible then fades. On Hard: hidden.
  bool get showLetterPrompt {
    if (difficulty.value == MiniGameDifficulty.easy) return true;
    if (difficulty.value == MiniGameDifficulty.hard) return false;
    // Medium: controlled by timer
    return isPromptVisible.value;
  }

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

  // One-retry state for Choices and Drag-and-Drop
  final hasRetried = false.obs;
  final lastWrongAnswer = ''.obs;

  // ── Floating score popup state ──
  final floatingScores = <FloatingScoreEvent>[].obs;
  int _floatingScoreIdCounter = 0;
  bool _spawnOnLeft = true; // alternates sides

  // ── Drag-and-drop state ──
  final currentDragPairs = <DragMatchPair>[].obs;
  final shuffledDragTargets = <DragMatchPair>[].obs;
  final selectedDragSource = Rxn<String>();

  // ── Object count display state ──
  final objectCountEmojis = <String>[].obs;
  final objectCountLayout = ''.obs; // 'neat', 'scattered', 'memory'
  final objectCountMemoryVisible = true.obs;
  Timer? _memoryFadeTimer;

  // ── Missing character display state ──
  final missingCharWordBlank = ''.obs;
  final missingCharFullWord = ''.obs;
  final missingCharDisplayHint = ''.obs; // 'with_image', 'word_only', 'audio'

  // ── Question display state ──
  final questionText = ''.obs;
  final questionFruitImage = ''.obs;

  // ── Math equation display state ──
  final mathFruitImage = ''.obs;
  final mathOperandA = 0.obs;
  final mathOperandB = 0.obs;
  final mathOperator = ''.obs;

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
  late final AnimationController mediumTimerCtrl;
  CancelToken? _cancelToken;
  int _reqId = 0;

  /// Controls whether the prompt is currently visible (used for Medium fade).
  final isPromptVisible = true.obs;

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

    mediumTimerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    mediumTimerCtrl.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) {
        isPromptVisible.value = false;
      }
    });

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
      bool needsDrawing = miniGames.any(
        (g) => g.inputType.contains('drawing_board'),
      );
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
    hasRetried.value = false;
    lastWrongAnswer.value = '';

    timeLeft.value = initialTimerDuration;
    maxTime.value = initialTimerDuration;
    isGameOver.value = false;
    isPaused.value = false;
    isGameActive.value = true;

    // Reset difficulty
    difficulty.value = MiniGameDifficulty.easy;
    _correctStreakForDifficulty = 0;

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
    mediumTimerCtrl.stop();
    _cancelPredictIfAny();
    isGameActive.value = false;
    isGameOver.value = true;

    // Update high score
    if (score.value > highScore.value) {
      highScore.value = score.value;
      _box.write(_highScoreKey, highScore.value);
    }

    // Submit progress to backend (coins accumulated during gameplay)
    final coins = earnedCoins.value;
    if (coins > 0 || score.value > 0) {
      _worldService.submitExerciseBatch(
        [], // No specific exercise attempts for endless minigames
        coinsEarned: coins,
        xpEarned: score.value,
      ).catchError((e) {
        dev.log('Failed to submit mini-game progress: $e', name: 'DynamicMiniGameController');
        return ApiResponse<Map<String, dynamic>>(
          code: 500,
          message: 'Failed to submit progress: $e',
          data: {},
        );
      });
    }
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

  /// Determine the difficulty for the next challenge based on the
  /// current correct streak, using a probabilistic roll like the adventure stage.
  void _rollDifficulty() {
    final rng = Random();
    if (_correctStreakForDifficulty >= _hardThreshold) {
      // 8+ streak: 20% Hard, 40% Medium, 40% Easy
      final roll = rng.nextDouble();
      if (roll < 0.20) {
        difficulty.value = MiniGameDifficulty.hard;
      } else if (roll < 0.60) {
        difficulty.value = MiniGameDifficulty.medium;
      } else {
        difficulty.value = MiniGameDifficulty.easy;
      }
    } else if (_correctStreakForDifficulty >= _mediumThreshold) {
      // 4-7 streak: 40% Medium, 60% Easy
      final roll = rng.nextDouble();
      if (roll < 0.40) {
        difficulty.value = MiniGameDifficulty.medium;
      } else {
        difficulty.value = MiniGameDifficulty.easy;
      }
    } else {
      // <4 streak: 100% Easy
      difficulty.value = MiniGameDifficulty.easy;
    }
  }

  void _pickNextChallenge() {
    // Roll difficulty before generating
    _rollDifficulty();

    // Pick a random game from the selected ones
    final game = miniGames[Random().nextInt(miniGames.length)];
    currentMiniGame.value = game;

    // Determine which input types are valid
    final compatibleTypes = game.compatibleInputTypes(game.displayType);

    if (userChosenInputType != null &&
        compatibleTypes.contains(userChosenInputType)) {
      // User explicitly chose this input type and it's compatible
      currentInputType.value = userChosenInputType!;
    } else if (compatibleTypes.isNotEmpty) {
      currentInputType.value =
          compatibleTypes[Random().nextInt(compatibleTypes.length)];
    } else {
      // Fallback
      currentInputType.value = 'drawing_board';
    }

    final challenge = ChallengeGenerator.generate(
      game,
      difficulty: difficulty.value,
    );
    currentChallenge.value = challenge;

    // ── Populate display-specific state ──
    _populateDisplayState(game, challenge);

    // Generate options if multiple choice
    if (currentInputType.value == 'multiple_choice') {
      final pool =
          (game.config?['pool'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];
      // For object_count, the pool is Khmer digits
      // For math_equation / question, the pool is Arabic digits
      List<String> effectivePool;
      if (game.displayType == 'object_count') {
        effectivePool = ['០', '១', '២', '៣', '៤', '៥', '៦', '៧', '៨', '៩'];
      } else if (game.displayType == 'math_equation' ||
          game.displayType == 'question') {
        effectivePool = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
      } else {
        effectivePool = pool;
      }
      final options = ChallengeGenerator.generateOptions(
        target: challenge.target,
        pool: effectivePool,
        difficulty: difficulty.value,
      );
      currentOptions.assignAll(options);
    } else {
      currentOptions.clear();
    }

    // Generate drag pairs if drag_and_drop
    if (currentInputType.value == 'drag_and_drop') {
      final pool =
          (game.config?['pool'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];
      final pairs = ChallengeGenerator.generateDragMatchPairs(
        pool: pool,
        difficulty: difficulty.value,
        displayType: game.displayType,
      );
      currentDragPairs.assignAll(pairs);
      // Shuffle the target side separately so they don't line up
      final shuffled = List<DragMatchPair>.from(pairs)..shuffle(Random());
      shuffledDragTargets.assignAll(shuffled);
      selectedDragSource.value = null;
    } else {
      currentDragPairs.clear();
      shuffledDragTargets.clear();
      selectedDragSource.value = null;
    }

    hasRetried.value = false;
    lastWrongAnswer.value = '';
    clearBoard();

    // If drawing board and we have stroke data, set guide
    // Only show the shadow guide on Easy difficulty
    // No shadow guide for math/question since the answer is a digit, not a character
    final isNumericDisplay =
        game.displayType == 'math_equation' || game.displayType == 'question';
    if (currentInputType.value == 'drawing_board' && !isNumericDisplay) {
      if (showShadowGuide) {
        setGuideForCharacter(challenge.target);
      } else {
        // No shadow guide for medium/hard
        letterSubpathsNorm.clear();
        strokeStrokesNorm.clear();
        anim.setGuideFromPx(strokesPx: const []);
      }
    } else {
      letterSubpathsNorm.clear();
      strokeStrokesNorm.clear();
      anim.setGuideFromPx(strokesPx: const []);
    }

    // ── Prompt visibility & audio per difficulty ──
    mediumTimerCtrl.stop();
    if (difficulty.value == MiniGameDifficulty.easy) {
      isPromptVisible.value = true;
    } else if (difficulty.value == MiniGameDifficulty.medium) {
      isPromptVisible.value = true;
      mediumTimerCtrl.reverse(from: 1.0);
    } else {
      // Hard: hidden from the start, play audio immediately
      isPromptVisible.value = false;
      replayPromptAudio();
    }

    _startIdleTimer();
  }

  /// Populate display-type-specific state from a generated challenge.
  void _populateDisplayState(MiniGameModel game, Challenge challenge) {
    _memoryFadeTimer?.cancel();

    if (game.displayType == 'object_count') {
      objectCountEmojis.assignAll(challenge.objectEmojis ?? []);
      objectCountLayout.value =
          challenge.display; // 'neat' / 'scattered' / 'memory'
      objectCountMemoryVisible.value = true;

      // For Hard (memory mode): show objects briefly, then fade
      if (challenge.display == 'memory') {
        _memoryFadeTimer = Timer(const Duration(seconds: 2), () {
          objectCountMemoryVisible.value = false;
        });
      }
    } else {
      objectCountEmojis.clear();
      objectCountLayout.value = '';
    }

    if (game.displayType == 'missing_character') {
      missingCharWordBlank.value = challenge.wordWithBlank ?? '';
      missingCharFullWord.value = challenge.fullWord ?? '';
      missingCharDisplayHint.value =
          challenge.display; // 'with_image' / 'word_only' / 'audio'
    } else {
      missingCharWordBlank.value = '';
      missingCharFullWord.value = '';
      missingCharDisplayHint.value = '';
    }

    // Math equation display state
    if (game.displayType == 'math_equation') {
      mathFruitImage.value = challenge.fruitImage ?? '';
      mathOperandA.value = challenge.operandA ?? 0;
      mathOperandB.value = challenge.operandB ?? 0;
      mathOperator.value = challenge.operator ?? '+';
    } else {
      mathFruitImage.value = '';
      mathOperandA.value = 0;
      mathOperandB.value = 0;
      mathOperator.value = '';
    }

    // Question display state
    if (game.displayType == 'question') {
      questionText.value = challenge.wordProblemText ?? '';
      questionFruitImage.value = challenge.wordProblemFruitImage ?? '';
    } else {
      questionText.value = '';
      questionFruitImage.value = '';
    }
  }



  void replayPromptAudio() {
    final game = currentMiniGame.value;
    final challenge = currentChallenge.value;
    if (game == null || challenge == null) return;

    final dt = game.displayType;
    if (dt == 'character' ||
        dt == 'letter' ||
        dt == 'number' ||
        dt == 'text' ||
        dt == 'image') {
      // If the game config explicitly provides a character_type, use it.
      // Otherwise, we infer it from the target character itself.
      String? audioType =
          (game.config?['character_type'] as String?) ??
          (game.config?['type'] as String?);

      if (audioType == null) {
        audioType = _getAudioFolderForCharacter(challenge.target);
      } else {
        // Normalize common types to folder names
        audioType = audioType.trim().toLowerCase();
        if (audioType == 'letter') {
          audioType = 'consonants';
        }
        if (audioType == 'number') {
          audioType = 'digits';
        }
        if (!audioType.endsWith('s')) {
          // Attempt to pluralize if missing (consonant -> consonants, etc)
          if (audioType == 'independent_vowel') {
            audioType = 'independent_vowels';
          }
          if (audioType == 'dependent_vowel') {
            audioType = 'dependent_vowels';
          }
          if (audioType == 'digit') {
            audioType = 'digits';
          }
        }
      }

      audio.autoPlayCharacter(type: audioType, ch: challenge.target);
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
    final dt = currentMiniGame.value?.displayType;
    if (currentChallenge.value != null &&
        dt != 'math_equation' &&
        dt != 'question') {
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
    _startIdleTimer();
    if (_rawStrokes.isEmpty) return;
  }

  void _startIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = Timer(const Duration(seconds: 3), () {
      if (!isGameActive.value || isGameOver.value || isPaused.value) return;
      final dt = currentMiniGame.value?.displayType;
      if (showShadowGuide && dt != 'math_equation' && dt != 'question') {
        anim.restartGuideFromStart();
      }
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

    final dt = currentMiniGame.value?.displayType;
    if (dt != 'math_equation' && dt != 'question') {
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

    if (selectedAnswer == challenge.target) {
      totalAnswered.value++;
      _applyCorrectResult();
    } else if (!hasRetried.value) {
      // First mistake — gentle retry, no penalty
      hasRetried.value = true;
      lastWrongAnswer.value = selectedAnswer;
      audio.playWrongSfx();
      isCorrectFeedback.value = false;
      feedbackText.value = 'Try again!';
      feedbackTrigger.value++;
    } else {
      // Second mistake — apply full wrong result
      totalAnswered.value++;
      _applyWrongResult();
    }
  }

  /// Handle tap on a source (left side) in drag-and-drop.
  void selectDragSource(String sourceId) {
    if (!isGameActive.value || isGameOver.value || isPaused.value) return;
    selectedDragSource.value = sourceId;
  }

  /// Handle a direct drag-and-drop from source to target.
  void submitDragDrop(String sourceId, DragMatchPair tappedTarget) {
    if (!isGameActive.value || isGameOver.value || isPaused.value) return;
    selectedDragSource.value = sourceId;
    selectDragTarget(tappedTarget);
  }

  /// Handle tap on a target (right side) in drag-and-drop.
  void selectDragTarget(DragMatchPair tappedTarget) {
    if (!isGameActive.value || isGameOver.value || isPaused.value) return;
    final srcId = selectedDragSource.value;
    if (srcId == null) return;

    // Find the source pair
    final matches = currentDragPairs.where((p) => p.source == srcId);
    final srcPair = matches.isEmpty ? null : matches.first;
    if (srcPair == null) return;

    // Check if this is the correct match
    if (srcPair.source == tappedTarget.source) {
      // Correct match!
      srcPair.matched = true;
      tappedTarget.matched = true;
      currentDragPairs.refresh();
      shuffledDragTargets.refresh();
      selectedDragSource.value = null;

      audio.playCorrectSfx();

      // Check if all valid pairs are matched
      if (currentDragPairs
          .where((p) => p.source.isNotEmpty)
          .every((p) => p.matched)) {
        // All pairs matched — count as a correct answer
        totalAnswered.value++;
        _applyCorrectResult();
      }
    } else {
      // Wrong match
      selectedDragSource.value = null;
      if (!hasRetried.value) {
        // First mistake — gentle retry
        hasRetried.value = true;
        lastWrongAnswer.value = tappedTarget.target;
        audio.playWrongSfx();
        isCorrectFeedback.value = false;
        feedbackText.value = 'Try again!';
        feedbackTrigger.value++;

        Future.delayed(const Duration(seconds: 1), () {
          if (lastWrongAnswer.value == tappedTarget.target) {
            lastWrongAnswer.value = '';
          }
        });
      } else {
        totalAnswered.value++;
        _applyWrongResult();
      }
    }
  }

  List<List<Offset>> _getTemplateForChar(String ch) {
    final db = _strokesDbCache;
    final items = db?['items'] as Map<String, dynamic>?;
    
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
    final normalizedCh = arabicToKhmer[ch.trim()] ?? ch.trim();
    final entry = items?[normalizedCh] as Map<String, dynamic>?;
    if (entry == null) return [];

    final strokes = entry['paths_px'] as List<dynamic>? ?? [];
    final strokesOut = StrokeTransformUtil.readSubpathsPx(strokes);
    if (strokesOut.isEmpty) return [];

    return StrokeTransformUtil.autoFitGlyphPx(
      strokesOut,
      boardW: boardWidth.value,
      boardH: boardHeight.value,
      pad: 24,
      minWidthFill: 0.72,
      minHeightFill: 0.78,
    );
  }

  Future<void> _checkDrawing() async {
    if (!isGameActive.value || isGameOver.value) return;

    _cancelPredictIfAny();
    final myReqId = ++_reqId;
    final cancelToken = CancelToken();
    _cancelToken = cancelToken;

    final challenge = currentChallenge.value;
    if (challenge == null) return;

    final expectedChar = challenge.target;
    final bool hasGuide = showShadowGuide && strokeStrokesNorm.isNotEmpty;

    bool isCorrect = false;

    try {
      if (hasGuide) {
        // ── WITH GUIDE (Easy): pure stroke-based evaluation ────────────
        final hint = StrokeFeedbackUtil.getFeedback(
          userRawStrokes: _rawStrokes,
          templateStrokesPx: strokeStrokesNorm,
          boardWidth: boardWidth.value,
          boardHeight: boardHeight.value,
          ignoreBounds: false,
        );
        isCorrect = (hint == null);
      } else {
        // ── WITHOUT GUIDE (Medium/Hard): AI + structural checks ────────
        final modelType = _getModelTypeForDisplay();

        final data = await _evalService.predictBoard(
          modelType: modelType,
          rawStrokes: _rawStrokes,
          getPayload: () => _getXYStrokeWithTime(modelType: modelType),
          cancelToken: cancelToken,
        );

        if (myReqId != _reqId) return;

        final prediction = (data?['prediction'] ?? '').toString().trim();
        isCorrect = _isDrawingCorrect(prediction, expectedChar);

        // If AI says correct, also validate stroke structure (ignoring bounds).
        if (isCorrect) {
          final template = _getTemplateForChar(expectedChar);
          if (template.isNotEmpty) {
            final centered = StrokeTransformUtil.autoCenterStrokes(
              _rawStrokes,
              template,
            );
            final hint = StrokeFeedbackUtil.getFeedback(
              userRawStrokes: centered,
              templateStrokesPx: template,
              boardWidth: boardWidth.value,
              boardHeight: boardHeight.value,
              ignoreBounds: true,
            );
            if (hint != null) {
              isCorrect = false;
            }
          }
        }
      }
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
  static const _khmerDigits = {
    '០',
    '១',
    '២',
    '៣',
    '៤',
    '៥',
    '៦',
    '៧',
    '៨',
    '៩',
  };

  String _getModelTypeForChar(String target) {
    final char = target.trim();
    if (char.isEmpty) return 'consonant';

    // 1. Digits (Khmer or Arabic)
    const khmerDigits = {'០', '១', '២', '៣', '៤', '៥', '៦', '៧', '៨', '៩'};
    const arabicDigits = {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9'};
    if (khmerDigits.contains(char) || arabicDigits.contains(char)) {
      return 'digit';
    }

    // 2. Independent Vowels
    const independentVowels = {
      'ឥ', 'ឦ', 'ឧ', 'ឩ', 'ឪ', 'ឫ', 'ឬ', 'ឭ', 'ឮ', 'ឯ', 'ឰ', 'ឱ', 'ឲ', 'ឳ'
    };
    if (independentVowels.contains(char)) {
      return 'independent_vowel';
    }

    // 3. Dependent Vowels
    const dependentVowels = {
      'ា', 'ិ', 'ី', 'ឹ', 'ឺ', 'ុ', 'ូ', 'ួ', 'ើ', 'ឿ', 'ៀ', 'េ', 'ែ', 'ៃ', 'ោ', 'ៅ', 'ុំ', 'ំ', 'ាំ', 'ះ', 'ិះ', 'ុះ', 'េះ', 'ោះ'
    };
    if (dependentVowels.contains(char)) {
      return 'dependent_vowel';
    }

    return 'consonant';
  }

  bool _isDrawingCorrect(String prediction, String expected) {
    final p = prediction.trim();
    final e = expected.trim();
    if (p == e) return true;

    // Normalize Arabic numerals to Khmer numerals for comparison
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

  String _getModelTypeForDisplay() {
    final challenge = currentChallenge.value;
    if (challenge != null && challenge.target.isNotEmpty) {
      return _getModelTypeForChar(challenge.target);
    }

    final dt = currentMiniGame.value?.displayType;

    // Legacy explicit types
    if (dt == 'number' || dt == 'math_equation' || dt == 'question' || dt == 'object_count') {
      return 'digit';
    }

    // For generic 'character' display type, inspect the pool to decide
    if (dt == 'character') {
      final pool =
          (currentMiniGame.value?.config?['pool'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];

      if (pool.isNotEmpty) {
        // Check if all digits
        if (pool.every((c) => _khmerDigits.contains(c))) {
          return 'digit';
        }

        // Check for independent vowels
        final independentVowels = [
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
        ];
        if (pool.any((c) => independentVowels.contains(c))) {
          return 'independent_vowel';
        }

        // Check for dependent vowels
        final dependentVowels = [
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
        ];
        if (pool.any((c) => dependentVowels.contains(c))) {
          return 'dependent_vowel';
        }
      }
    }

    return 'consonant';
  }

  String _getAudioFolderForCharacter(String ch) {
    final c = ch.trim();
    if (_khmerDigits.contains(c)) return 'digits';

    const independentVowels = [
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
    ];
    if (independentVowels.contains(c)) return 'independent_vowels';

    const dependentVowels = [
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
    ];
    if (dependentVowels.contains(c)) return 'dependent_vowels';

    return 'consonants';
  }

  void _applyCorrectResult() {
    correctCount.value++;

    // Briefly show the completed word (replace the '?' box) for missing_character games
    if (currentMiniGame.value?.displayType == 'missing_character') {
      missingCharWordBlank.value = currentChallenge.value?.fullWord ?? '';
    }

    // Update combo
    combo.value++;
    if (combo.value > bestCombo.value) {
      bestCombo.value = combo.value;
    }

    // Track streak for difficulty scaling
    _correctStreakForDifficulty++;

    // Calculate score with combo multiplier
    final comboMultiplier = 1.0 + (combo.value - 1) * 0.1;
    final earnedScore = (10 * comboMultiplier).round();

    // Calculate coins earned for this answer (combo-based)
    // Base: 1 coin, +1 per 2 combo levels → combo 1-2 = 1, 3-4 = 2, 5-6 = 3, etc.
    final coinsForAnswer = (1 + (combo.value - 1) ~/ 2).clamp(1, 999);
    earnedCoins.value += coinsForAnswer;

    // Add time
    timeLeft.value = (timeLeft.value + timeRewardCorrect).clamp(
      0.0,
      maxTime.value,
    );

    // Show feedback
    isCorrectFeedback.value = true;
    feedbackText.value = combo.value >= 3 ? '🔥 x${combo.value}!' : 'Correct!';
    feedbackTrigger.value++;

    audio.playCorrectSfx();
    anim.showCorrect(starIndex: 0);

    // ── Spawn a floating score popup on alternating sides ──
    final rng = Random();
    // X: left side (0.05–0.20) or right side (0.80–0.95)
    final xFrac = _spawnOnLeft
        ? 0.05 + rng.nextDouble() * 0.15
        : 0.80 + rng.nextDouble() * 0.15;
    _spawnOnLeft = !_spawnOnLeft;
    // Y: somewhere between 25%–45% of screen height (below timer, above input)
    final yFrac = 0.25 + rng.nextDouble() * 0.20;

    final event = FloatingScoreEvent(
      id: _floatingScoreIdCounter++,
      points: earnedScore,
      startX: xFrac,
      startY: yFrac,
    );
    floatingScores.add(event);

    // After the fly animation finishes, add points and remove the popup
    Future.delayed(const Duration(milliseconds: 1200), () {
      score.value += earnedScore;
      floatingScores.removeWhere((e) => e.id == event.id);
    });

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

    // Break combo and reset difficulty streak
    combo.value = 0;
    _correctStreakForDifficulty = 0;

    // Time penalty
    timeLeft.value = (timeLeft.value + timePenaltyWrong).clamp(
      0.0,
      maxTime.value,
    );

    // Show feedback
    isCorrectFeedback.value = false;
    feedbackText.value = 'Wrong!';
    feedbackTrigger.value++;

    audio.playWrongSfx();

    anim.showWrongAndReset(
      customDuration: const Duration(milliseconds: 500),
      onAfterReset: () {
        clearBoard();
        final dt = currentMiniGame.value?.displayType;
        if (dt != 'math_equation' && dt != 'question') {
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

    final items = _strokesDbCache!['items'] as Map<String, dynamic>?;
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
    final normalizedCh = arabicToKhmer[ch.trim()] ?? ch.trim();
    final entry = items?[normalizedCh] as Map<String, dynamic>?;

    if (entry == null) {
      letterSubpathsNorm.clear();
      strokeStrokesNorm.clear();
      anim.setGuideFromPx(strokesPx: const []);
      return;
    }

    final boardW = boardWidth.value;
    final boardH = boardHeight.value;

    final letter = entry['text_px'] as List<dynamic>? ?? [];
    final strokes = entry['paths_px'] as List<dynamic>? ?? [];

    final letterOut = StrokeTransformUtil.readSubpathsPx(letter);
    final strokesOut = StrokeTransformUtil.readSubpathsPx(strokes);

    if (letterOut.isEmpty && strokesOut.isEmpty) {
      letterSubpathsNorm.clear();
      strokeStrokesNorm.clear();
      anim.setGuideFromPx(strokesPx: const []);
      return;
    }

    final combined = <List<Offset>>[...letterOut, ...strokesOut];
    final fitted = StrokeTransformUtil.autoFitGlyphPx(
      combined,
      boardW: boardW,
      boardH: boardH,
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

  Map<String, dynamic> _getXYStrokeWithTime({required String modelType}) {
    final formattedStrokes = _rawStrokes.map((stroke) {
      return {
        "points": stroke.map((point) {
          return {
            "x": (point["x"] as num).toDouble(),
            "y": (point["y"] as num).toDouble(),
            "time": (point["time"] as num?)?.toInt(),
          };
        }).toList(),
      };
    }).toList();
    return {
      "strokes": formattedStrokes,
      "model_type": modelType,
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
    _memoryFadeTimer?.cancel();
    mediumTimerCtrl.dispose();
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
