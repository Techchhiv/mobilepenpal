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

  final letterSubpathsNorm = <List<Offset>>[].obs;
  final strokeStrokesNorm = <List<Offset>>[].obs;

  final double boardWidth = 340;
  final double boardHeight = 340;

  final currentExerciseIndex = 0.obs;
  final selectedCharacter = ''.obs;

  final attempts = <Map<String, dynamic>>[].obs;

  bool hasDrawnStroke = false;

  Timer? idle;
  DateTime? _sessionStart;

  StageExercise? get currentExercise =>
      (currentExerciseIndex.value >= 0 &&
          currentExerciseIndex.value < exercises.length)
      ? exercises[currentExerciseIndex.value]
      : null;

  final List<List<Map<String, dynamic>>> _rawStrokes = [];
  List<Map<String, dynamic>>? _currentStroke;

  int? _t0Ms;
  int _relTimeMs() {
    _t0Ms ??= DateTime.now().millisecondsSinceEpoch;
    return DateTime.now().millisecondsSinceEpoch - _t0Ms!;
  }

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

    anim.setGuideFromNormalized(strokesNorm: const [], boundsH: 1, boundsW: 1);

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
    hasDrawnStroke = false;
    idle?.cancel();

    _rawStrokes.clear();
    _currentStroke = null;
    _t0Ms = null;
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
    hasDrawnStroke = true;
    idle?.cancel();

    anim.stopGuide();
  }

  Future<void> onPointerUp() async {
    if (!hasDrawnStroke) return;
    hasDrawnStroke = false;
    idle?.cancel();

    idle = Timer(const Duration(milliseconds: 1500), () async {
      // anim.startGuide();

      await checkDrawing();
      hasDrawnStroke = false;
    });
  }

  Future<void> checkDrawing() async {
    final exercise = currentExercise;
    if (exercise == null) return;

    final modelType = _mapCharacterTypeToModelType(exercise.characterType);

    // ====== AI verify (currently disabled / API down) ======
    // bool isCorrect = false;
    // String? prediction;
    //
    // try {
    //   final payload = getYXWithTime(modelType: modelType);
    //   final data = await _worldService.predictDrawing(payload);
    //
    //   prediction = (data['prediction'] ?? '').toString().trim();
    //   isCorrect = prediction == (exercise.character ?? '').trim();
    // } catch (e) {
    //   // Fallback while AI is down
    //   isCorrect = Random().nextDouble() <= 0.9;
    // }

    final bool isCorrect = Random().nextDouble() <= 0.9;

    if (isCorrect) {
      anim.showCorrect();
    } else {
      await anim.showWrongAndReset(
        onAfterReset: () {
          clearBoard();
          hasDrawnStroke = false;
        },
      );
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
      hasDrawnStroke = false;
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

  Future<void> skipCurrentExercise() async {
    final exercise = currentExercise;
    if (exercise == null) return;

    attempts.add({
      'exercise_id': exercise.id,
      'user_answer': '',
      'label': exercise.character,
      'stroke': getXYStrokes(),
      'is_correct': false,
    });

    await anim.showWrongAndReset(
      onAfterReset: () {
        clearBoard();
        hasDrawnStroke = false;
      },
    );

    final isLastExercise = currentExerciseIndex.value >= exercises.length - 1;

    if (isLastExercise) {
      final durationSeconds = _sessionDurationSeconds;

      final summary = await submitExerciseBatch(
        List<Map<String, dynamic>>.from(attempts),
        durationSeconds: durationSeconds,
      );

      attempts.clear();
      hasDrawnStroke = false;
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
      setGuideForCharacter(selectedCharacter.value);
    } else {
      selectedCharacter.value = '';
      anim.setGuideFromNormalized(
        strokesNorm: const [],
        boundsH: 1,
        boundsW: 1,
      );
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
              "points": stroke.map((p) {
                return {
                  "x": (p["x"] as num).toDouble(),
                  "y": (p["y"] as num).toDouble(),
                  "time": (p["time"] as num?)?.toInt(),
                };
              }).toList(),
            },
          )
          .toList(),
      "model_type": modelType,
    };
  }

  void onRawPointerDown(PointerDownEvent e) {
    _currentStroke = [];
    _currentStroke!.add({
      "x": e.localPosition.dx,
      "y": e.localPosition.dy,
      "time": _relTimeMs(),
    });
    onPointerDown();
  }

  void onRawPointerMove(PointerMoveEvent e) {
    if (_currentStroke == null) return;
    _currentStroke!.add({
      "x": e.localPosition.dx,
      "y": e.localPosition.dy,
      "time": _relTimeMs(),
    });
  }

  void onRawPointerUp(PointerUpEvent e) {
    if (_currentStroke != null && _currentStroke!.isNotEmpty) {
      _rawStrokes.add(List<Map<String, dynamic>>.from(_currentStroke!));
    }
    _currentStroke = null;
    onPointerUp();
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

    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource(rel));
    } catch (e) {
      debugPrint('Audio missing: assets/$rel  ($e)');
    }
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

    final entry = items?[ch.trim()] as Map<String, dynamic>?;
    if (entry == null) {
      letterSubpathsNorm.clear();
      strokeStrokesNorm.clear();

      anim.setGuideFromNormalized(
        strokesNorm: const [],
        boundsW: 1.0,
        boundsH: 1.0,
      );
      return;
    }

    final bounds = entry['bounds'] as Map<String, dynamic>? ?? {};
    final bw = (bounds['w'] as num?)?.toDouble() ?? 1.0;
    final bh = (bounds['h'] as num?)?.toDouble() ?? 1.0;

    final letter = entry['letter'] as List<dynamic>? ?? [];
    final letterOut = <List<Offset>>[];

    for (final sub in letter) {
      final pts = <Offset>[];
      for (final p in (sub as List)) {
        pts.add(Offset((p[0] as num).toDouble(), (p[1] as num).toDouble()));
      }
      if (pts.isNotEmpty) letterOut.add(pts);
    }
    letterSubpathsNorm.assignAll(letterOut);

    final strokes = entry['strokes'] as List<dynamic>? ?? [];
    final strokesOut = <List<Offset>>[];

    for (final stroke in strokes) {
      final pts = <Offset>[];
      for (final p in (stroke as List)) {
        pts.add(Offset((p[0] as num).toDouble(), (p[1] as num).toDouble()));
      }
      if (pts.isNotEmpty) strokesOut.add(pts);
    }
    strokeStrokesNorm.assignAll(strokesOut);

    anim.setGuideFromNormalized(
      strokesNorm: strokesOut,
      boundsW: bw,
      boundsH: bh,
    );
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
