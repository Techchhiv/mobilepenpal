import 'dart:async';
import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_drawing_board/flutter_drawing_board.dart';
import 'package:get/get.dart';
import 'package:mobilepenpal/core/network/route_builder.dart';
import 'package:mobilepenpal/data/models/stage/stage.dart';
import 'package:mobilepenpal/data/models/stage/stage_exercise.dart';
import 'package:mobilepenpal/data/services/world_service.dart';
import 'package:mobilepenpal/presentation/routes/app_routes.dart';

enum DrawFeedback { none, correct, wrong }

class StageController extends GetxController
    with GetSingleTickerProviderStateMixin {
  final WorldService _worldService = WorldService();

  var isLoading = false.obs;
  var isSubmitting = false.obs;

  var currentStage = Rxn<Stage>();
  var exercises = <StageExercise>[].obs;

  late int worldId;
  late int levelId;
  late int stageId;

  final DrawingController drawingController = DrawingController();
  final double boardWidth = 320;
  final double boardHeight = 320;
  final double fontSize = 240;

  final RxInt currentExerciseIndex = 0.obs;
  final RxString selectedCharacter = ''.obs;

  final attempts = <Map<String, dynamic>>[].obs;

  final hasDrawnStroke = false.obs;

  static const String penUpToken = '#';

  Timer? idle;

  StageExercise? get currentExercise =>
      (currentExerciseIndex.value >= 0 &&
          currentExerciseIndex.value < exercises.length)
      ? exercises[currentExerciseIndex.value]
      : null;

  List<String> get characters =>
      exercises.map((e) => e.character).where((c) => c.isNotEmpty).toList();

  final feedback = DrawFeedback.none.obs;

  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;
  final shakeOffset = 0.0.obs;

  final praiseText = ''.obs;

  late final ConfettiController confettiController;

  @override
  void onInit() {
    super.onInit();

    final parameters = Get.parameters;
    worldId = int.tryParse(parameters['worldId'] ?? '') ?? 0;
    levelId = int.tryParse(parameters['levelId'] ?? '') ?? 0;
    stageId = int.tryParse(parameters['stageId'] ?? '') ?? 0;

    drawingController.setStyle(color: Colors.black, strokeWidth: 6);

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _shakeAnimation = Tween<double>(
      begin: 0,
      end: 12,
    ).chain(CurveTween(curve: Curves.elasticIn)).animate(_shakeController);

    _shakeAnimation.addListener(() {
      shakeOffset.value = _shakeAnimation.value;
    });

    confettiController = ConfettiController(
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void onClose() {
    idle?.cancel();
    _shakeController.dispose();
    confettiController.dispose();
    drawingController.dispose();
    super.onClose();
  }

  Future<void> fetchStageDetail() async {
    isLoading.value = true;
    try {
      final response = await _worldService.getStageById(stageId);

      if (response.code == 200) {
        final stage = response.data;
        if (stage != null) {
          currentStage.value = stage;
          exercises.assignAll(stage.exercises);

          if (exercises.isNotEmpty) {
            currentExerciseIndex.value = 0;
            selectedCharacter.value = exercises[0].character;
          }
        } else {
          Get.snackbar('Error', 'Stage data is empty');
        }
      } else {
        Get.snackbar('Error', response.message);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load stage details: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<Map<String, dynamic>?> submitExerciseBatch(
    List<Map<String, dynamic>> attempts,
  ) async {
    isSubmitting.value = true;
    try {
      final response = await _worldService.submitExerciseBatch(attempts);

      if (response.code == 200) {
        final data = response.data ?? <String, dynamic>{};
        final summary = data['summary'] as Map<String, dynamic>? ?? {};
        return summary;
      } else {
        Get.snackbar('Error', response.message);
        return null;
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to submit exercises: $e');
      return null;
    } finally {
      isSubmitting.value = false;
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

    attempts.clear();
    currentExerciseIndex.value = 0;
    selectedCharacter.value = '';
    exercises.clear();
    currentStage.value = null;

    await fetchStageDetail();
  }

  String get characterVowelFormsRaw {
    return currentExercise?.example ?? 'កា/កិ/កី';
  }

  List<String> get characterVowelFormsList {
    final raw = characterVowelFormsRaw;
    if (raw.isEmpty) return [];
    return raw
        .split('/')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  void clearBoard() {
    drawingController.clear();
    hasDrawnStroke.value = false;
    idle?.cancel();
  }

  void selectExerciseByIndex(int index) {
    if (index < 0 || index >= exercises.length) return;

    currentExerciseIndex.value = index;
    selectedCharacter.value = exercises[index].character;
    clearBoard();
  }

  void selectExerciseByCharacter(String char) {
    final index = exercises.indexWhere((e) => e.character == char);
    if (index != -1) {
      selectExerciseByIndex(index);
    }
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

  void onPointerDown() {
    hasDrawnStroke.value = true;
    idle?.cancel();
  }

  Future<void> onPointerUp() async {
    if (!hasDrawnStroke.value) return;
    hasDrawnStroke.value = false;
    idle?.cancel();

    idle = Timer(Duration(milliseconds: 1500), () async {
      await checkDrawing();
      hasDrawnStroke.value = false;
    });
  }

  Future<void> checkDrawing() async {
    final exercise = currentExercise;
    if (exercise == null) return;

    final bool isCorrect = Random().nextDouble() <= 0.9;

    feedback.value = isCorrect ? DrawFeedback.correct : DrawFeedback.wrong;

    if (isCorrect) {
      final phrases = ['ល្អណាស់!', 'ធ្វើបានល្អ 👍'];
      praiseText.value = phrases[Random().nextInt(phrases.length)];
      confettiController.play();
    } else {
      praiseText.value = '';
      _shakeController.forward(from: 0);

      await Future.delayed(const Duration(milliseconds: 400));

      feedback.value = DrawFeedback.none;
      await Future.delayed(const Duration(milliseconds: 300));

      clearBoard();
      hasDrawnStroke.value = false;
      return;
    }

    attempts.add({
      'exercise_id': exercise.id,
      'user_answer': exercise.character,
      'label': exercise.character,
      'stroke': getXYStrokes(),
      'is_correct': isCorrect,
    });

    final isLastExercise = currentExerciseIndex.value >= exercises.length - 1;

    await Future.delayed(const Duration(milliseconds: 800));

    feedback.value = DrawFeedback.none;

    if (isLastExercise) {
      final summary = await submitExerciseBatch(
        List<Map<String, dynamic>>.from(attempts),
      );
      attempts.clear();
      hasDrawnStroke.value = false;
      drawingController.clear();

      if (summary != null) {
        final summaryRoute = RouteBuilder.build(AppRoutes.summary, {
          'worldId': worldId.toString(),
          'levelId': levelId.toString(),
          'stageId': stageId.toString(),
        });

        Get.offNamed(summaryRoute, arguments: {'summary': summary});
      }
    } else {
      nextExercise();
      clearBoard();
    }
  }

  void skipCurrentExercise() {
    final isLastExercise = currentExerciseIndex.value >= exercises.length - 1;
    if (isLastExercise) {
      return;
    }

    nextExercise();
    clearBoard();
  }

  void resetForRetry() {
    attempts.clear();

    currentExerciseIndex.value = 0;

    if (exercises.isNotEmpty) {
      selectedCharacter.value = exercises[0].character;
    } else {
      selectedCharacter.value = '';
    }
    clearBoard();
  }

  List<dynamic> getXYStrokes() {
    final strokes = drawingController.getJsonList();
    final List<dynamic> sequence = [];

    for (final stroke in strokes) {
      final steps = stroke['path']?['steps'];
      if (steps is! List) continue;

      bool strokeHasPoints = false;

      for (final step in steps) {
        final x = step['x'];
        final y = step['y'];

        if (x != null && y != null) {
          sequence.add((x as num).toDouble());
          sequence.add((y as num).toDouble());
          strokeHasPoints = true;
        }
      }

      if (strokeHasPoints) {
        sequence.add('#');
      }
    }

    if (sequence.isNotEmpty && sequence.last == '#') {
      sequence.removeLast();
    }

    return sequence;
  }
}
