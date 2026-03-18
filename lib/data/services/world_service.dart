import 'package:dio/dio.dart';
import 'package:mobilepenpal/core/config/env.dart';
import 'package:mobilepenpal/core/network/endpoint/world.dart';
import 'package:mobilepenpal/data/models/api_response.dart';
import 'package:mobilepenpal/core/network/api_client.dart';
import 'package:mobilepenpal/data/models/exercise/exercise.dart';
import 'package:mobilepenpal/data/models/level/level.dart';
import 'package:mobilepenpal/data/models/stage/stage.dart';
import 'package:mobilepenpal/data/models/world/world.dart';

class WorldService {
  final ApiClient _apiClient = ApiClient();
  final Dio dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 6),
      receiveTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
      headers: const {'Content-Type': 'application/json'},
    ),
  );

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

  Future<ApiResponse<List<Exercise>>> getExercises() async {
    final result = await _apiClient.request<List<Exercise>>(
      method: 'GET',
      path: WorldEndpoints.exercises,
      fromData: (data) {
        // Backend returns {"exercises": [...]} via setResult('exercises', ...)
        List? list;
        if (data is Map && data['exercises'] is List) {
          list = data['exercises'] as List;
        } else if (data is List) {
          list = data;
        }
        if (list != null) {
          return list.map((e) => Exercise.fromJson(e)).toList();
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
    int? stageId,
    int? durationSeconds,
    int? coinsEarned,
    int? xpEarned,
    bool isAdventure = false,
  }) async {
    final Map<String, dynamic> payload = {
      'attempts': attempts,
    };

    if (stageId != null && stageId > 0) {
      payload['stage_id'] = stageId;
    }

    if (isAdventure) {
      payload['is_adventure'] = true;
    }

    if (durationSeconds != null && durationSeconds > 0) {
      payload['duration_seconds'] = durationSeconds;
    }

    if (coinsEarned != null && coinsEarned > 0) {
      payload['coins_earned'] = coinsEarned;
    }

    if (xpEarned != null && xpEarned > 0) {
      payload['xp_earned'] = xpEarned;
    }

    final result = await _apiClient.request<Map<String, dynamic>>(
      method: 'POST',
      path: WorldEndpoints.submitExercise,
      data: payload,
      fromData: (data) => data as Map<String, dynamic>,
    );

    return result;
  }

  Future<Map<String, dynamic>> predictDrawingVector({
    required List<Map<String, dynamic>> strokes,
    required String modelType,
    CancelToken? cancelToken,
  }) async {
    final payload = {'strokes': strokes, 'model_type': modelType};

    final res = await dio.post(
      Env.aiApiBaseUrl,
      data: payload,
      cancelToken: cancelToken,
    );

    if (res.statusCode != 200) {
      throw Exception('Predict API error: ${res.statusCode} ${res.data}');
    }

    final data = res.data;
    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid predict response format');
    }

    return Map<String, dynamic>.from(data);
  }
}
