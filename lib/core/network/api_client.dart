import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobilepenpal/core/config/env.dart';
import 'package:mobilepenpal/core/config/app_constants.dart';
import 'package:mobilepenpal/data/models/api_response.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio dio;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  ApiClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: Env.apiBaseUrl,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _secureStorage.read(
            key: AppConstants.accessToken,
          );

          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          return handler.next(options);
        },
        onResponse: (response, handler) {
          // if (response.data is Map && response.data['data'] != null) {
          //   response.data = response.data['data'];
          // }

          return handler.next(response);
        },
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401) {
            await _secureStorage.delete(key: AppConstants.accessToken);
          }
          return handler.next(e);
        },
      ),
    );
  }

  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: AppConstants.accessToken, value: token);
  }

  Future<void> clearToken() async {
    await _secureStorage.delete(key: AppConstants.accessToken);
  }

  Future<bool> isAuthenticated() async {
    final token = await _secureStorage.read(key: AppConstants.accessToken);
    return token != null && token.isNotEmpty;
  }

  Future<ApiResponse<T>> request<T>({
    required String method,
    required String path,
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic data)? fromData,
  }) async {
    try {
      final response = await dio.request(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(method: method),
      );

      return ApiResponse.fromJson(response.data, fromData ?? (d) => d as T);
    } on DioException catch (e) {
      if (e.response != null && e.response!.data != null) {
        return ApiResponse.fromJson(
          e.response!.data,
          fromData ?? (d) => d as T,
        );
      } else {
        return ApiResponse(code: 500, message: e.message ?? 'Unexpected error');
      }
    }
  }
}
