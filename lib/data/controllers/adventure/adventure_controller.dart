import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:math';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mobilepenpal/data/models/exercise/exercise.dart';
import 'package:mobilepenpal/data/services/world_service.dart';

/// A group of max 10 randomized exercises that acts like a "stage"
class AdventureStage {
  final int index;
  final String label;
  final String categoryType;
  final List<Exercise> exercises;

  AdventureStage({
    required this.index,
    required this.label,
    required this.categoryType,
    required this.exercises,
  });
}

class AdventureController extends GetxController {
  final WorldService _worldService = WorldService();
  final GetStorage _box = GetStorage();

  static const String _storageKey = 'adventure_exercises';
  static const int maxExercisesPerStage = 6;
  static const String _unlockedKey = 'adventure_unlocked_index';
  
  final isLoading = false.obs;
  final isTransitioning = false.obs;
  final stages = <AdventureStage>[].obs;
  final allExercises = <Exercise>[].obs;
  final unlockedStageIndex = 0.obs;

  /// Display labels for each character_type
  static const Map<String, String> categoryLabels = {
    'consonants': 'Consonants',
    'dependent_vowels': 'Dependent Vowels',
    'independent_vowels': 'Independent Vowels',
    'digits': 'Digits',
    'math': 'Math',
  };

  @override
  void onInit() {
    super.onInit();
    _loadUnlockedIndex();
    _loadExercises();
  }

  void _loadUnlockedIndex() {
    final val = _box.read<int>(_unlockedKey);
    if (val != null) {
      unlockedStageIndex.value = val;
    }
  }

  Future<void> completeStage(int index) async {
    // Only unlock next if we completed the current highest unlocked stage
    if (index == unlockedStageIndex.value) {
      unlockedStageIndex.value++;
      await _box.write(_unlockedKey, unlockedStageIndex.value);
      dev.log('Unlocked stage ${unlockedStageIndex.value}', name: 'AdventureController');
    }
  }

  Future<void> _loadExercises() async {
    // Try loading from local storage first
    final cached = _box.read(_storageKey);
    if (cached != null && cached is String) {
      try {
        final list = jsonDecode(cached) as List;
        final exercises = list
            .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
            .toList();
        if (exercises.isNotEmpty) {
          allExercises.assignAll(exercises);
          _buildStages();
          return;
        }
      } catch (_) {
        // Cache is corrupted, fetch fresh
      }
    }

    // Fetch from server
    await fetchExercises();
  }

  Future<void> fetchExercises() async {
    isLoading.value = true;

    try {
      final response = await _worldService.getExercises();
      dev.log(
        'fetchExercises response: code=${response.code}, data=${response.data?.length ?? 0} items',
        name: 'AdventureController',
      );

      if (response.code == 200 && response.data != null) {
        final exercises = response.data!;
        allExercises.assignAll(exercises);

        // Cache to GetStorage
        final jsonList = exercises.map((e) => e.toJson()).toList();
        await _box.write(_storageKey, jsonEncode(jsonList));

        _buildStages();
      } else {
        dev.log(
          'fetchExercises failed: code=${response.code}, msg=${response.message}',
          name: 'AdventureController',
        );
      }
    } catch (e) {
      dev.log('fetchExercises error: $e', name: 'AdventureController');
    } finally {
      isLoading.value = false;
    }
  }

  void _buildStages() {
    final rng = Random();

    // Group exercises by character_type
    final Map<String, List<Exercise>> grouped = {};
    for (final exercise in allExercises) {
      final type = exercise.characterType ?? 'unknown';
      grouped.putIfAbsent(type, () => []).add(exercise);
    }

    // Order categories consistently
    const order = [
      'consonants',
      'dependent_vowels',
      'independent_vowels',
      'digits',
      'math',
    ];

    final allStages = <AdventureStage>[];
    int stageIndex = 0;

    for (final type in order) {
      final exercises = grouped[type];
      if (exercises == null || exercises.isEmpty) continue;

      // Shuffle exercises within the category
      final shuffled = List<Exercise>.from(exercises)..shuffle(rng);

      // Split into chunks of maxExercisesPerStage
      for (int i = 0; i < shuffled.length; i += maxExercisesPerStage) {
        final chunk = shuffled.sublist(
          i,
          min(i + maxExercisesPerStage, shuffled.length),
        );
        final categoryLabel = categoryLabels[type] ?? type;
        final chunkNum = (i ~/ maxExercisesPerStage) + 1;
        final totalChunks = (shuffled.length / maxExercisesPerStage).ceil();

        allStages.add(
          AdventureStage(
            index: stageIndex,
            label: totalChunks > 1 ? '$categoryLabel $chunkNum' : categoryLabel,
            categoryType: type,
            exercises: chunk,
          ),
        );
        stageIndex++;
      }
    }

    // Add any unexpected types at the end
    for (final entry in grouped.entries) {
      if (!order.contains(entry.key)) {
        final shuffled = List<Exercise>.from(entry.value)..shuffle(rng);
        for (int i = 0; i < shuffled.length; i += maxExercisesPerStage) {
          final chunk = shuffled.sublist(
            i,
            min(i + maxExercisesPerStage, shuffled.length),
          );
          allStages.add(
            AdventureStage(
              index: stageIndex,
              label: entry.key,
              categoryType: entry.key,
              exercises: chunk,
            ),
          );
          stageIndex++;
        }
      }
    }

    stages.assignAll(allStages);
    dev.log(
      'Built ${allStages.length} adventure stages',
      name: 'AdventureController',
    );
  }

  /// Refresh exercises from server
  Future<void> refreshExercises() async {
    await fetchExercises();
  }
}
