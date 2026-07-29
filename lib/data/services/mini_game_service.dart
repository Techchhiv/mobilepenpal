import 'package:mobilepenpal/core/network/api_client.dart';
import 'package:mobilepenpal/core/network/endpoint/mini_game.dart';
import 'package:mobilepenpal/data/models/api_response.dart';
import 'package:mobilepenpal/data/models/mini_game/mini_game_model.dart';
import 'package:mobilepenpal/data/models/mini_game/question_template_model.dart';

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

  Future<ApiResponse<List<QuestionTemplateModel>>> getQuestionTemplates() async {
    final result = await _apiClient.request<List<QuestionTemplateModel>>(
      method: 'GET',
      path: MiniGameEndpoints.questionTemplates,
      fromData: (data) {
        final list = (data['question_templates'] as List<dynamic>?) ?? [];
        return list
            .whereType<Map<String, dynamic>>()
            .map((e) => QuestionTemplateModel.fromJson(e))
            .toList();
      },
    );
    return result;
  }

  Future<ApiResponse<Map<String, dynamic>>> recordPlay(int miniGameId) async {
    final result = await _apiClient.request<Map<String, dynamic>>(
      method: 'POST',
      path: MiniGameEndpoints.recordPlay,
      data: {'mini_game_id': miniGameId},
      fromData: (data) => (data as Map<String, dynamic>?) ?? {},
    );
    return result;
  }

  Future<ApiResponse<Map<String, dynamic>>> getDailyPlays() async {
    final result = await _apiClient.request<Map<String, dynamic>>(
      method: 'GET',
      path: MiniGameEndpoints.dailyPlays,
      fromData: (data) => (data as Map<String, dynamic>?) ?? {},
    );
    return result;
  }
}
