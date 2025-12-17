import 'package:get/get.dart';
import 'package:mobilepenpal/data/models/level/level.dart';
import 'package:mobilepenpal/data/models/level/level_stage.dart';
import 'package:mobilepenpal/data/services/world_service.dart';

class LevelController extends GetxController {
  final WorldService _worldService = WorldService();

  var isLoading = false.obs;
  var currentLevel = Rxn<Level>();

  final initialStageIndex = 0.obs;

  late int worldId;
  late int levelId;

  @override
  void onInit() {
    super.onInit();

    final parameters = Get.parameters;
    worldId = int.tryParse(parameters['worldId'] ?? '') ?? 0;
    levelId = int.tryParse(parameters['levelId'] ?? '') ?? 0;

    if (levelId > 0) {
      fetchLevelDetail();
    } else {
      Get.snackbar('Error', 'Invalid level ID');
    }
  }

  int _computeNextStageIndex(List<LevelStage> stages) {
    if (stages.isEmpty) return 0;

    // ✅ pick the first "unlocked but not completed" (best UX)
    final idx = stages.indexWhere((s) => s.status == "unlocked");
    if (idx != -1) return idx;

    // ✅ fallback: first not completed
    final idx2 = stages.indexWhere((s) => s.status != "completed");
    if (idx2 != -1) return idx2;

    // ✅ all completed -> last stage
    return stages.length - 1;
  }

  Future<void> fetchLevelDetail() async {
    isLoading.value = true;
    try {
      final response = await _worldService.getLevelById(levelId);
      if (response.code == 200) {
        currentLevel.value = response.data;

        // ✅ compute where to land
        final stages = response.data?.stages ?? <LevelStage>[];
        initialStageIndex.value = _computeNextStageIndex(stages);
      } else {
        Get.snackbar('Error', response.message);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load level details: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
