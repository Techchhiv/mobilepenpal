import 'package:mobilepenpal/data/models/student/student.dart';
import '../models/api_response.dart';
import 'package:mobilepenpal/core/network/api_client.dart';
import 'package:mobilepenpal/core/network/endpoint/auth.dart';

class AuthService {
  final ApiClient _apiClient = ApiClient();

  Future<ApiResponse<Map<String, dynamic>>> loginStudent({
    required String identifier,
    required String password,
    required String schoolKey,
  }) async {
    final result = await _apiClient.request<Map<String, dynamic>>(
      method: 'POST',
      path: AuthtEndpoints.login,
      data: {
        "identifier": identifier,
        "password": password,
        "school_key": schoolKey,
      },
      fromData: (data) {
        final student = Student.fromJson(data['student']);
        return {"student": student};
      },
    );

    return result;
  }

  Future<void> logout() async {
    await _apiClient.request(method: 'POST', path: AuthtEndpoints.logout);
    await _apiClient.clearToken();
  }

  Future<bool> isLoggedIn() async {
    return await _apiClient.isAuthenticated();
  }

  Future<ApiResponse<Student>> getProfile() async {
    final result = await _apiClient.request<Student>(
      method: 'GET',
      path: AuthtEndpoints.profile,
      fromData: (data) => Student.fromJson(data['student']),
    );

    return result;
  }

  Future<ApiResponse<Map<String, dynamic>>> verifyOtpAndGetToken({
    required String phone,
    required String? firebaseToken,
  }) async {
    final result = await _apiClient.request<Map<String, dynamic>>(
      method: 'POST',
      path: AuthtEndpoints.otp,
      data: {"phone": phone, "firebase_token": firebaseToken},
      fromData: (data) {
        final token = data['token'];
        final student = Student.fromJson(data['student']);
        return {"token": token, "student": student};
      },
    );

    if (result.code == 200) {
      await _apiClient.saveToken(result.data?['token']);
    }

    return result;
  }
}
