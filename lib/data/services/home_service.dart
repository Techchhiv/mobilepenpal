import 'package:mobilepenpal/data/models/report/daily_summary.dart';
import 'package:mobilepenpal/data/models/report/monthly_summary.dart';
import 'package:mobilepenpal/data/models/report/weekly_summary.dart';
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

  Future<ApiResponse<Student>> uploadAvatar(String base64Image) async {
    final result = await _apiClient.request<Student>(
      method: 'POST',
      path: HomeEndpoints.uploadImage,
      data: {'image': base64Image},
      fromData: (data) => Student.fromJson(data['student']),
    );

    return result;
  }

  Future<ApiResponse<DailySummary>> getDailySummary({String? date}) async {
    final result = await _apiClient.request<DailySummary>(
      method: 'GET',
      path: HomeEndpoints.dailySummary,
      queryParameters: date != null ? {'date': date} : null,
      fromData: (data) {
        final summaryJson = (data['summary'] as Map<String, dynamic>? ?? {});
        return DailySummary.fromJson(summaryJson);
      },
    );

    return result;
  }

  Future<ApiResponse<WeeklySummary>> getWeeklySummary({
    String? fromDate,
    String? toDate,
  }) async {
    final query = <String, dynamic>{};
    if (fromDate != null) query['from_date'] = fromDate;
    if (toDate != null) query['to_date'] = toDate;

    final result = await _apiClient.request<WeeklySummary>(
      method: 'GET',
      path: HomeEndpoints.weeklySummary,
      queryParameters: query.isEmpty ? null : query,
      fromData: (data) => WeeklySummary.fromJson(data['summary']),
    );

    return result;
  }

  Future<ApiResponse<MonthlySummary>> getMonthlySummary({String? month}) async {
    final result = await _apiClient.request<MonthlySummary>(
      method: 'GET',
      path: HomeEndpoints.monthlySummary,
      queryParameters: month == null ? null : {'month': month},
      fromData: (data) => MonthlySummary.fromJson(data['summary']),
    );

    return result;
  }
}
