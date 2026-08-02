import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mobilepenpal/core/config/env.dart';
import 'package:mobilepenpal/data/models/api_response.dart';
import 'package:mobilepenpal/presentation/routes/app_routes.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio dio;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );
  final GetStorage _box = GetStorage();

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
          final token = await _secureStorage.read(key: Env.accessToken);
          final currentLocale = Get.locale?.languageCode;
          final storedLocale = _box.read('locale');

          final languageCode = storedLocale != null && storedLocale['languageCode'] != null
              ? storedLocale['languageCode']
              : (currentLocale ?? 'en');

          options.headers['Accept-Language'] = languageCode;

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
            await _secureStorage.delete(key: Env.accessToken);
            await _box.write('has_token', false);
            await _box.write('is_logged_in', false);

            final current = Get.currentRoute;
            if (current != AppRoutes.login && current != AppRoutes.splash) {
              Get.offAllNamed(AppRoutes.login);
            }
          }
          return handler.next(e);
        },
      ),
    );
  }

  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: Env.accessToken, value: token);

    await _box.write('has_token', true);
    await _box.write('is_logged_in', true);
  }

  Future<void> clearToken() async {
    await _secureStorage.delete(key: Env.accessToken);

    await _box.write('has_token', false);
    await _box.write('is_logged_in', false);
  }

  Future<bool> isAuthenticated() async {
    final token = await _secureStorage.read(key: Env.accessToken);
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
      if (e.response != null && e.response!.data != null && e.response!.data is Map<String, dynamic>) {
        return ApiResponse.fromJson(
          e.response!.data as Map<String, dynamic>,
          fromData ?? (d) => d as T,
        );
      } else {
        String msg = e.message ?? 'Unexpected error';
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.sendTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.connectionError ||
            msg.contains('SocketException') ||
            msg.contains('Connection failed') ||
            msg.contains('Network is unreachable')) {
          msg = 'network_error'.tr;
        }
        return ApiResponse(code: 500, message: msg);
      }
    }
  }
}
