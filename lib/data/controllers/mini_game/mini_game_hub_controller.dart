import 'dart:developer' as dev;

import 'package:get/get.dart';
import 'package:mobilepenpal/data/models/mini_game/mini_game_model.dart';
import 'package:mobilepenpal/data/services/mini_game_service.dart';

class MiniGameHubController extends GetxController {
  final MiniGameService _service = MiniGameService();

  final isLoading = true.obs;
  final miniGames = <MiniGameModel>[].obs;
  final errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchMiniGames();
  }

  Future<void> fetchMiniGames() async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final response = await _service.getMiniGames();
      if (response.code == 200 && response.data != null) {
        miniGames.assignAll(response.data!);
      } else {
        errorMessage.value = response.message;
      }
    } catch (e) {
      dev.log('Failed to fetch mini games: $e', name: 'MiniGameHubController');
      errorMessage.value = 'Failed to load mini games';
    } finally {
      isLoading.value = false;
    }
  }
}
