import 'package:get/get.dart';
import 'package:mobilepenpal/data/models/level/level.dart';
import 'package:mobilepenpal/data/services/world_service.dart';

class LevelController extends GetxController {
  final WorldService _worldService = WorldService();
  
  var isLoading = false.obs;
  var currentLevel = Rxn<Level>();
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

  Future<void> fetchLevelDetail() async {
    isLoading.value = true;
    try {
      final response = await _worldService.getLevelById(levelId);
      if (response.code == 200) {
        currentLevel.value = response.data;
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