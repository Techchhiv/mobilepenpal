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

  /// Silently refresh daily play counts from server.
  Future<void> refreshDailyPlays() async {
    try {
      final response = await _service.getDailyPlays();
      if (response.code == 200 && response.data != null) {
        final playsData = response.data!['plays'];
        if (playsData is Map) {
          final updated = miniGames.map((g) {
            final count = (playsData[g.id.toString()] ?? playsData[g.id] ?? g.todayPlayCount) as num;
            return g.copyWith(todayPlayCount: count.toInt());
          }).toList();
          miniGames.assignAll(updated);
        }
      }
    } catch (e) {
      dev.log('Failed to refresh daily plays: $e', name: 'MiniGameHubController');
    }
  }

  /// Increment today's play count locally for a list of played game IDs.
  void recordPlayCounts(List<int> gameIds) {
    if (gameIds.isEmpty) return;
    final updated = miniGames.map((g) {
      if (gameIds.contains(g.id)) {
        return g.copyWith(todayPlayCount: g.todayPlayCount + 1);
      }
      return g;
    }).toList();
    miniGames.assignAll(updated);
  }

  /// Returns the remaining daily plays for a single game.
  int getRemainingPlaysForGame(int gameId, int dailyLimit) {
    final game = miniGames.firstWhereOrNull((g) => g.id == gameId);
    if (game == null) return dailyLimit;
    final remaining = dailyLimit - game.todayPlayCount;
    return remaining < 0 ? 0 : remaining;
  }

  /// Returns the minimum remaining plays across selected games (or all games if none selected).
  int getRemainingPlaysForSelected(List<int> selectedIds, int dailyLimit) {
    if (miniGames.isEmpty) return dailyLimit;
    final targetGames = selectedIds.isEmpty
        ? miniGames
        : miniGames.where((g) => selectedIds.contains(g.id)).toList();

    if (targetGames.isEmpty) return dailyLimit;

    int minRemaining = dailyLimit;
    for (final game in targetGames) {
      final remaining = dailyLimit - game.todayPlayCount;
      final clamped = remaining < 0 ? 0 : remaining;
      if (clamped < minRemaining) {
        minRemaining = clamped;
      }
    }
    return minRemaining;
  }
}
