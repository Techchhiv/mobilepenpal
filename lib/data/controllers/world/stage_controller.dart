import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_drawing_board/flutter_drawing_board.dart';
import 'package:get/get.dart';
import 'package:mobilepenpal/core/network/route_builder.dart';
import 'package:mobilepenpal/data/controllers/world/stage_animation_controller.dart';
import 'package:mobilepenpal/data/models/stage/stage.dart';
import 'package:mobilepenpal/data/models/stage/stage_exercise.dart';
import 'package:mobilepenpal/data/services/world_service.dart';
import 'package:mobilepenpal/presentation/routes/app_routes.dart';

class StageController extends GetxController {
  final WorldService _worldService = WorldService();
  final isLoading = false.obs;
  final isSubmitting = false.obs;

  final currentStage = Rxn<Stage>();
  final exercises = <StageExercise>[].obs;

  late int worldId;
  late int levelId;
  late int stageId;

  final DrawingController drawingController = DrawingController();

  final double boardWidth = 320;
  final double boardHeight = 320;

  final double fontSize = 320;

  final currentExerciseIndex = 0.obs;
  final selectedCharacter = ''.obs;

  final attempts = <Map<String, dynamic>>[].obs;

  final hasDrawnStroke = false.obs;
  static const String penUpToken = '#';

  Timer? idle;
  DateTime? _sessionStart;

  StageExercise? get currentExercise =>
      (currentExerciseIndex.value >= 0 &&
              currentExerciseIndex.value < exercises.length)
          ? exercises[currentExerciseIndex.value]
          : null;

  List<String> get characters =>
      exercises.map((e) => e.character).where((c) => c.isNotEmpty).toList();

  final _audioPlayer = AudioPlayer();
  final _strokesDb = Rxn<Map<String, dynamic>>();
  late final StageAnimationController anim;
  bool _ownsAnim = false;

  @override
  void onInit() {
    super.onInit();

    final parameters = Get.parameters;
    worldId = int.tryParse(parameters['worldId'] ?? '') ?? 0;
    levelId = int.tryParse(parameters['levelId'] ?? '') ?? 0;
    stageId = int.tryParse(parameters['stageId'] ?? '') ?? 0;

    drawingController.setStyle(color: Colors.black, strokeWidth: 6);

    if (Get.isRegistered<StageAnimationController>()) {
      anim = Get.find<StageAnimationController>();
      _ownsAnim = false;
    } else {
      anim = Get.put(StageAnimationController());
      _ownsAnim = true;
    }

    anim.setBoardSize(width: boardWidth, height: boardHeight);

    loadStrokeDb();
  }

  @override
  void onClose() {
    idle?.cancel();
    drawingController.dispose();
    _audioPlayer.dispose();

    if (_ownsAnim && Get.isRegistered<StageAnimationController>()) {
      Get.delete<StageAnimationController>();
    }
    super.onClose();
  }

  Future<void> fetchStageDetail() async {
    isLoading.value = true;
    try {
      await loadStrokeDb();

      final response = await _worldService.getStageById(stageId);

      if (response.code == 200) {
        final stage = response.data;
        if (stage != null) {
          currentStage.value = stage;
          exercises.assignAll(stage.exercises);

          if (exercises.isNotEmpty) {
            currentExerciseIndex.value = 0;
            selectedCharacter.value = exercises[0].character;

            setGuideForCharacter(selectedCharacter.value);

            _sessionStart = DateTime.now();
            await Future.delayed(const Duration(milliseconds: 150));
            playCurrentCharacterAudio();
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

    anim.setGuideFromNormalized(strokesNorm: const [], svgW: 320, svgH: 320);

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

    stopAudio();

    currentExerciseIndex.value = index;
    selectedCharacter.value = exercises[index].character;

    clearBoard();
    setGuideForCharacter(selectedCharacter.value);
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

    anim.stopGuide();
  }

  Future<void> onPointerUp() async {
    if (!hasDrawnStroke.value) return;
    hasDrawnStroke.value = false;
    idle?.cancel();

    idle = Timer(const Duration(milliseconds: 1500), () async {
      // anim.startGuide();

      await checkDrawing();
      hasDrawnStroke.value = false;
    });
  }

  Future<void> checkDrawing() async {
    final exercise = currentExercise;
    if (exercise == null) return;

    final bool isCorrect = Random().nextDouble() <= 0.9;

    if (isCorrect) {
      anim.showCorrect();
    } else {
      await anim.showWrongAndReset(onAfterReset: () {
        clearBoard();
        hasDrawnStroke.value = false;
      });
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

    anim.feedback.value = DrawFeedback.none;
    anim.clearPraise();

    if (isLastExercise) {
      final durationSeconds = _sessionDurationSeconds;
      final summary = await submitExerciseBatch(
        List<Map<String, dynamic>>.from(attempts),
        durationSeconds: durationSeconds,
      );

      attempts.clear();
      hasDrawnStroke.value = false;
      drawingController.clear();
      _sessionStart = null;

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
    if (isLastExercise) return;

    nextExercise();
    clearBoard();
  }

  void resetForRetry() {
    attempts.clear();
    currentExerciseIndex.value = 0;

    if (exercises.isNotEmpty) {
      selectedCharacter.value = exercises[0].character;
      setGuideForCharacter(selectedCharacter.value);
    } else {
      selectedCharacter.value = '';
      anim.setGuideFromNormalized(strokesNorm: const [], svgW: 320, svgH: 320);
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
        durationSeconds: durationSeconds,
      );

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

  int get _sessionDurationSeconds {
    if (_sessionStart == null) return 0;
    final diff = DateTime.now().difference(_sessionStart!);
    return diff.inSeconds;
  }

  String? get _audioRelPath {
    final ex = currentExercise;
    if (ex == null) return null;

    final type = (ex.characterType ?? '').trim();
    final ch = ex.character.trim();
    if (type.isEmpty || ch.isEmpty) return null;

    return 'audios/$type/$ch.mp3';
  }

  Future<void> playCurrentCharacterAudio() async {
    final rel = _audioRelPath;
    if (rel == null) return;

    await _audioPlayer.stop();
    await _audioPlayer.play(AssetSource(rel));
  }

  Future<void> stopAudio() => _audioPlayer.stop();

  Future<void> loadStrokeDb() async {
    if (_strokesDb.value != null) return;

    final raw = await rootBundle.loadString('assets/strokes/strokes.json');
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    _strokesDb.value = decoded;
  }

  void setGuideForCharacter(String ch) {
    final db = _strokesDb.value;
    final items = db?['items'] as Map<String, dynamic>?;

    final key = ch.trim();
    final entry = items?[key] as Map<String, dynamic>?;

    if (entry == null) {
      anim.setGuideFromNormalized(strokesNorm: const [], svgW: 320, svgH: 320);
      debugPrint('GUIDE NOT FOUND for "$key"');
      return;
    }

    final sz = (entry['svg_size'] as Map<String, dynamic>?) ??
        (entry['viewBox'] as Map<String, dynamic>?) ??
        {};

    final svgW = (sz['w'] as num?)?.toDouble() ?? 320;
    final svgH = (sz['h'] as num?)?.toDouble() ?? 320;

    final strokes = entry['strokes'] as List<dynamic>?;
    if (strokes == null || strokes.isEmpty) {
      anim.setGuideFromNormalized(strokesNorm: const [], svgW: svgW, svgH: svgH);
      return;
    }

    final strokesNorm = <List<Offset>>[];

    for (final stroke in strokes) {
      final pts = <Offset>[];
      for (final p in (stroke as List)) {
        pts.add(
          Offset(
            (p[0] as num).toDouble(),
            (p[1] as num).toDouble(),
          ),
        ); // normalized 0..1
      }
      strokesNorm.add(pts);
    }

    anim.setGuideFromNormalized(strokesNorm: strokesNorm, svgW: svgW, svgH: svgH);
  }
}
