import 'package:flutter/material.dart';
import 'package:flutter_drawing_board/flutter_drawing_board.dart';
import 'package:get/get.dart';
import 'package:mobilepenpal/core/network/route_builder.dart';
import 'package:mobilepenpal/data/models/stage/stage.dart';
import 'package:mobilepenpal/data/models/stage/stage_exercise.dart';
import 'package:mobilepenpal/data/services/world_service.dart';
import 'package:mobilepenpal/presentation/routes/app_routes.dart';

class StageController extends GetxController {
  final WorldService _worldService = WorldService();

  // ───────── API / data state ─────────
  var isLoading = false.obs;
  var isSubmitting = false.obs;

  var currentStage = Rxn<Stage>();
  var exercises = <StageExercise>[].obs;

  late int worldId;
  late int levelId;
  late int stageId;

  // ───────── UI / gameplay state ─────────

  // Drawing board
  final DrawingController drawingController = DrawingController();
  final double boardWidth = 320;
  final double boardHeight = 320;
  final double fontSize = 240;

  // Current exercise
  final RxInt currentExerciseIndex = 0.obs;
  final RxString selectedCharacter = ''.obs;

  // Attempts for this stage
  // Each item: { exercise_id, user_answer, is_correct }
  final attempts = <Map<String, dynamic>>[].obs;

  // Whether user has drawn something for the current exercise
  final hasDrawnStroke = false.obs;

  // Convenience getters
  StageExercise? get currentExercise =>
      (currentExerciseIndex.value >= 0 &&
          currentExerciseIndex.value < exercises.length)
      ? exercises[currentExerciseIndex.value]
      : null;

  List<String> get characters =>
      exercises.map((e) => e.character).where((c) => c.isNotEmpty).toList();

  // ───────── Lifecycle ─────────

  @override
  void onInit() {
    super.onInit();

    final parameters = Get.parameters;
    worldId = int.tryParse(parameters['worldId'] ?? '') ?? 0;
    levelId = int.tryParse(parameters['levelId'] ?? '') ?? 0;
    stageId = int.tryParse(parameters['stageId'] ?? '') ?? 0;

    drawingController.setStyle(color: Colors.black, strokeWidth: 6);
  }

  @override
  void onClose() {
    drawingController.dispose();
    super.onClose();
  }

  // ───────── API calls ─────────

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

  // For the vowel forms bar
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

  // ───────── Drawing / exercise actions ─────────

  void clearBoard() {
    drawingController.clear();
    hasDrawnStroke.value = false;
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

  /// Called when the child starts drawing.
  void onPointerDown() {
    hasDrawnStroke.value = true;
  }

  /// Called when they finish a stroke.
  /// For now: anything drawn counts as CORRECT and triggers next/submit.
  Future<void> onPointerUp() async {
    if (!hasDrawnStroke.value) return;
    hasDrawnStroke.value = false;

    await checkDrawing();
  }

  Future<void> checkDrawing() async {
    final exercise = currentExercise;
    if (exercise == null) return;

    attempts.add({
      'exercise_id': exercise.id,
      'user_answer': exercise.character,
      'is_correct': true,
    });

    final isLastExercise = currentExerciseIndex.value >= exercises.length - 1;

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
      // Last one: just finish stage, no submit (since they skipped).
      // Later you might still want to submit "skipped" attempts with is_correct = false.
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
}
