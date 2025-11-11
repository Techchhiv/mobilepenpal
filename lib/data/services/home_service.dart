import 'package:mobilepenpal/data/models/student/student.dart';
import 'package:mobilepenpal/data/models/api_response.dart';
import 'package:mobilepenpal/core/network/api_client.dart';
import 'package:mobilepenpal/core/network/endpoint/home.dart';

class HomeService {
  final ApiClient _apiClient = ApiClient();

  Future<ApiResponse<Student>> getStudentProfile() async {
    final result = await _apiClient.request<Student>(
      method: 'GET',
      path: HomeEndpoints.profile,
      fromData: (data) => Student.fromJson(data['profile']),
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
}
