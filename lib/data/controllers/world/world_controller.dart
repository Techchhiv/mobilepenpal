import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobilepenpal/data/models/world/world_level.dart';
import 'package:mobilepenpal/data/models/world/world.dart';
import 'package:mobilepenpal/data/services/world_service.dart';

class WorldController extends GetxController {
  final WorldService _worldService = WorldService();

  var isLoading = false.obs;
  var currentWorld = Rxn<World>();
  var worldsList = <World>[].obs;
  var levelsList = <WorldLevel>[].obs;


  Future<void> fetchWorlds() async {
    isLoading.value = true;
    try {
      final response = await _worldService.getWorlds();
      if (response.code == 200) {
        worldsList.assignAll(response.data ?? []);
      } else {
        Get.snackbar(
          'Error',
          response.message,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchWorldById(int worldId) async {
    isLoading.value = true;
    try {
      final response = await _worldService.getWorldById(worldId);

      if (response.code == 200) {
        currentWorld.value = response.data;
        levelsList.assignAll(response.data?.levels ?? []);
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchLevelById(int levelId) async {
    isLoading.value = true;
    try {
      final response = await _worldService.getLevelById(levelId);
      if (response.code == 200) {
        Get.snackbar(
          'Success',
          'Level loaded successfully',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Error',
          response.message,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load level: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  World? getWorldById(int worldId) {
    return worldsList.firstWhereOrNull((world) => world.id == worldId);
  }

  WorldLevel? getLevelById(int levelId) {
    for (final world in worldsList) {
      final level = world.levels.firstWhereOrNull(
        (level) => level.id == levelId,
      );
      if (level != null) return level;
    }
    return null;
  }
}
