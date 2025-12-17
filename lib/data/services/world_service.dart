import 'package:mobilepenpal/core/network/endpoint/world.dart';
import 'package:mobilepenpal/data/models/api_response.dart';
import 'package:mobilepenpal/core/network/api_client.dart';
import 'package:mobilepenpal/data/models/level/level.dart';
import 'package:mobilepenpal/data/models/stage/stage.dart';
import 'package:mobilepenpal/data/models/world/world.dart';

class WorldService {
  final ApiClient _apiClient = ApiClient();

  Future<ApiResponse<List<World>>> getWorlds() async {
    final result = await _apiClient.request<List<World>>(
      method: 'GET',
      path: WorldEndpoints.worlds,
      fromData: (data) {
        if (data is List) {
          return data.map((world) => World.fromJson(world)).toList();
        }
        return [];
      },
    );

    return result;
  }

  Future<ApiResponse<World>> getWorldById(int worldId) async {
    final result = await _apiClient.request<World>(
      method: 'GET',
      path: WorldEndpoints.getWorldById(worldId),
      fromData: (data) {
        if (data == null || data['world'] == null) {
          throw Exception("Invalid world structure");
        }
        return World.fromJson(data['world']);
      },
    );

    return result;
  }

  Future<ApiResponse<Level>> getLevelById(int levelId) async {
    final result = await _apiClient.request<Level>(
      method: 'GET',
      path: WorldEndpoints.getLevelById(levelId),
      fromData: (data) {
        if (data == null || data['level'] == null) {
          throw Exception("Invalid level structure: $data");
        }
        return Level.fromJson(data['level']);
      },
    );

    return result;
  }

  Future<ApiResponse<Stage>> getStageById(int stageId) async {
    final result = await _apiClient.request<Stage>(
      method: 'GET',
      path: WorldEndpoints.getStageById(stageId),
      fromData: (data) {
        if (data == null || data['stage'] == null) {
          throw Exception("Invalid stage structure: $data");
        }
        return Stage.fromJson(data['stage']);
      },
    );

    return result;
  }

  Future<ApiResponse<Map<String, dynamic>>> submitExerciseBatch(
    List<Map<String, dynamic>> attempts, {
    int? durationSeconds,
  }) async {
    final Map<String, dynamic> payload = {'attempts': attempts};

    if (durationSeconds != null && durationSeconds > 0) {
      payload['duration_seconds'] = durationSeconds;
    }

    final result = await _apiClient.request<Map<String, dynamic>>(
      method: 'POST',
      path: WorldEndpoints.submitExercise,
      data: payload,
      fromData: (data) => data as Map<String, dynamic>,
    );

    return result;
  }
}
