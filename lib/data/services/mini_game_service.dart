import 'package:mobilepenpal/core/network/api_client.dart';
import 'package:mobilepenpal/core/network/endpoint/mini_game.dart';
import 'package:mobilepenpal/data/models/api_response.dart';
import 'package:mobilepenpal/data/models/mini_game/mini_game_model.dart';

class MiniGameService {
  final ApiClient _apiClient = ApiClient();

  Future<ApiResponse<List<MiniGameModel>>> getMiniGames() async {
    final result = await _apiClient.request<List<MiniGameModel>>(
      method: 'GET',
      path: MiniGameEndpoints.miniGames,
      fromData: (data) {
        final list = (data['mini_games'] as List<dynamic>?) ?? [];
        return list
            .whereType<Map<String, dynamic>>()
            .map((e) => MiniGameModel.fromJson(e))
            .toList();
      },
    );
    return result;
  }
}
