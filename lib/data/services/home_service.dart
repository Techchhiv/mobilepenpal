import 'package:mobilepenpal/data/models/student/student.dart';
import 'package:mobilepenpal/data/models/api_response.dart';
import 'package:mobilepenpal/core/network/api_client.dart';
import 'package:mobilepenpal/core/network/endpoint/home.dart';
import 'package:mobilepenpal/data/models/student/student_progress.dart';

class ProfileResponse {
  final Student profile;
  final List<StudentProgress> progress;

  ProfileResponse({required this.profile, required this.progress});

  factory ProfileResponse.fromJson(Map<String, dynamic> json) {
    return ProfileResponse(
      profile: Student.fromJson(json['profile']),
      progress:
          (json['progress'] as List<dynamic>?)
              ?.map((progress) => StudentProgress.fromJson(progress))
              .toList() ??
          [],
    );
  }
}

class HomeService {
  final ApiClient _apiClient = ApiClient();

  Future<ApiResponse<ProfileResponse>> getStudentProfile() async {
    final result = await _apiClient.request<ProfileResponse>(
      method: 'GET',
      path: HomeEndpoints.profile,
      fromData: (data) => ProfileResponse.fromJson(data),
    );

    return result;
  }

  Future<ApiResponse<Student>> updateStudentProfile(
    Map<String, dynamic> data,
  ) async {
    final result = await _apiClient.request<Student>(
      method: 'PUT',
      path: HomeEndpoints.profile,
      data: data,
      fromData: (data) => Student.fromJson(data['profile']),
    );

    return result;
  }

  Future<ApiResponse<Map<String, dynamic>>> updateParentPin(String pin) async {
    final result = await _apiClient.request<Map<String, dynamic>>(
      method: 'PUT',
      path: HomeEndpoints.updatePin,
      data: {'parent_pin': pin},
      fromData: (data) => data as Map<String, dynamic>,
    );
    return result;
  }

  Future<ApiResponse<Map<String, dynamic>>> updatePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final result = await _apiClient.request<Map<String, dynamic>>(
      method: 'PUT',
      path: HomeEndpoints.password,
      data: {
        'current_password': currentPassword,
        'new_password': newPassword,
        'new_password_confirmation': confirmPassword,
      },
      fromData: (data) => data as Map<String, dynamic>,
    );

    return result;
  }

  Future<ApiResponse<Student>> updateUser(Map<String, dynamic> data) async {
    final result = await _apiClient.request<Student>(
      method: 'PUT',
      path: HomeEndpoints.update,
      data: data,
      fromData: (data) => Student.fromJson(data['students']),
    );

    return result;
  }
}
