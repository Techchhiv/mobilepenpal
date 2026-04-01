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
  static const String _unlockedKey = 'adventure_unlocked_categories';
  static const String _starsKey = 'adventure_stage_stars';
  
  final isLoading = false.obs;
  final isTransitioning = false.obs;
  final stages = <AdventureStage>[].obs;
  final allExercises = <Exercise>[].obs;
  
  // Track unlocked stage index per category
  final categoryUnlockedIndex = <String, int>{}.obs;

  // Track max stars earned per stage index
  final stageStars = <int, int>{}.obs;

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
    final val = _box.read(_unlockedKey);
    if (val != null && val is Map) {
      final map = Map<String, dynamic>.from(val);
      categoryUnlockedIndex.assignAll(map.map((k, v) => MapEntry(k, v as int)));
    } else {
      categoryUnlockedIndex.assignAll({
        'consonants': 0,
        'dependent_vowels': 25,
        'independent_vowels': 50,
        'digits': 75,
      });
    }

    final starsVal = _box.read(_starsKey);
    if (starsVal != null && starsVal is Map) {
      final starsMap = Map<String, dynamic>.from(starsVal);
      stageStars.assignAll(starsMap.map((k, v) => MapEntry(int.parse(k), v as int)));
    }
  }

  int getUnlockedStageIndexForCategory(String category) {
    switch (category) {
      case 'dependent_vowels': return categoryUnlockedIndex[category] ?? 25;
      case 'independent_vowels': return categoryUnlockedIndex[category] ?? 50;
      case 'digits': return categoryUnlockedIndex[category] ?? 75;
      default: return categoryUnlockedIndex[category] ?? 0;
    }
  }

  int _getMaxIndexForCategory(String category) {
    switch (category) {
      case 'consonants': return 24;
      case 'dependent_vowels': return 49;
      case 'independent_vowels': return 74;
      case 'digits': return 99;
      default: return 99;
    }
  }

  Future<void> completeStage(AdventureStage stage, {int stars = 0}) async {
    final currentUnlocked = getUnlockedStageIndexForCategory(stage.categoryType);
    final maxIndex = _getMaxIndexForCategory(stage.categoryType);
    
    final currentStars = stageStars[stage.index] ?? 0;
    if (stars > currentStars) {
      stageStars[stage.index] = stars;
      // Convert map to string keys for JSON serialization in GetStorage
      final mapToSave = stageStars.map((k, v) => MapEntry(k.toString(), v));
      await _box.write(_starsKey, mapToSave);
    }

    // Only unlock next if we completed the current highest unlocked stage in this category
    if (stage.index == currentUnlocked && stage.index < maxIndex) {
      categoryUnlockedIndex[stage.categoryType] = currentUnlocked + 1;
      await _box.write(_unlockedKey, categoryUnlockedIndex);
      dev.log('Unlocked stage ${currentUnlocked + 1} for ${stage.categoryType}', name: 'AdventureController');
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

    // Fixed categories and exactly 25 stages each
    const order = [
      'consonants',
      'dependent_vowels',
      'independent_vowels',
      'digits',
    ];
    
    // Reset category map if it's empty
    if (categoryUnlockedIndex.isEmpty) {
      categoryUnlockedIndex.assignAll({
        'consonants': 0,
        'dependent_vowels': 25,
        'independent_vowels': 50,
        'digits': 75,
      });
    }

    final allStages = <AdventureStage>[];
    int globalIndex = 0;

    for (final type in order) {
      final exercises = grouped[type];
      if (exercises == null || exercises.isEmpty) {
        // Skip entirely and assign empty stages just to keep the indices aligned
        // Wait, if we don't increment globalIndex by 25, the indices will shift!
        // We must increment globalIndex by 25 anyway.
        for (int i = 0; i < 25; i++) {
          allStages.add(
            AdventureStage(
              index: globalIndex,
              label: '${categoryLabels[type] ?? type} ${i + 1}',
              categoryType: type,
              exercises: const [],
            ),
          );
          globalIndex++;
        }
        continue;
      }

      // Shuffle exercises
      final shuffled = List<Exercise>.from(exercises)..shuffle(rng);
      final categoryLabel = categoryLabels[type] ?? type;

      // Ensure we generate EXACTLY 25 stages for this category
      for (int i = 0; i < 25; i++) {
        // Collect exercises safely wrapping around the available exercises
        final chunk = <Exercise>[];
        for (int j = 0; j < maxExercisesPerStage; j++) {
          final exerciseIndex = (i * maxExercisesPerStage + j) % shuffled.length;
          chunk.add(shuffled[exerciseIndex]);
        }

        allStages.add(
          AdventureStage(
            index: globalIndex,
            label: '$categoryLabel ${i + 1}',
            categoryType: type,
            exercises: chunk,
          ),
        );
        globalIndex++;
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
