import 'package:mobilepenpal/data/models/student/student.dart';
import '../models/api_response.dart';
import 'package:mobilepenpal/core/network/api_client.dart';
import 'package:mobilepenpal/core/network/endpoint/auth.dart';

class AuthService {
  final ApiClient _apiClient = ApiClient();

  Future<ApiResponse<Map<String, dynamic>>> loginStudent({
    String? email,
    String? phone,
    String? login,
    required String password,
    bool? confirm,
    // required String schoolKey,
  }) async {
    final String? loginInput = (login ?? email ?? phone)?.trim();
    final bool isEmail = loginInput != null && loginInput.contains('@');

    final Map<String, dynamic> payload = {
      "password": password,
      if (confirm != null) "confirm": confirm,
    };

    if (loginInput != null && loginInput.isNotEmpty) {
      payload["login"] = loginInput;
      if (isEmail) {
        payload["email"] = loginInput;
      } else {
        payload["phone"] = loginInput;
      }
    }

    final result = await _apiClient.request<Map<String, dynamic>>(
      method: 'POST',
      path: AuthEndpoints.login,
      data: payload,
      fromData: (data) {
        final token = data['token'];
        final student = Student.fromJson(data['student']);
        return {"student": student, "token": token};
      },
    );

    if (result.code == 200) {
      await _apiClient.saveToken(result.data?['token']);
    }

    return result;
  }

  Future<void> logout() async {
    await _apiClient.request(method: 'POST', path: AuthEndpoints.logout);
    await _apiClient.clearToken();
  }

  Future<bool> isLoggedIn() async {
    return await _apiClient.isAuthenticated();
  }

  Future<ApiResponse<Student>> getProfile() async {
    final result = await _apiClient.request<Student>(
      method: 'GET',
      path: AuthEndpoints.profile,
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
      path: AuthEndpoints.otp,
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

  Future<ApiResponse<Map<String, dynamic>>> registerParent({
    required String studentFirstName,
    String? studentLastName,
    required String parentFirstName,
    required String parentLastName,
    String? email,
    String? phone,
    required String password,
  }) async {
    final result = await _apiClient.request<Map<String, dynamic>>(
      method: 'POST',
      path: AuthEndpoints.register,
      data: {
        "first_name": studentFirstName,
        if (studentLastName != null && studentLastName.trim().isNotEmpty)
          "last_name": studentLastName.trim(),
        "parent_first_name": parentFirstName,
        "parent_last_name": parentLastName,

        if (email != null && email.trim().isNotEmpty) "email": email.trim(),
        if (phone != null && phone.trim().isNotEmpty) "phone": phone.trim(),
        "password": password,
      },
      fromData: (data) {
        final token = data['token'];
        final student = data['student'];
        return {"token": token, "student": student};
      },
    );

    if (result.code == 200 && result.data?['token'] != null) {
      await _apiClient.saveToken(result.data?['token']);
    }

    return result;
  }
}
