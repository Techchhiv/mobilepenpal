import 'package:mobilepenpal/core/network/api_client.dart';
import 'package:mobilepenpal/core/network/endpoint/home.dart';
import 'package:mobilepenpal/data/models/api_response.dart';
import 'package:mobilepenpal/data/models/classroom/classroom_detail.dart';

class ClassroomService {
  final ApiClient _apiClient = ApiClient();

  Future<ApiResponse<ClassroomDetail>> getClassroomDetail(
    int classroomId,
  ) async {
    return _apiClient.request<ClassroomDetail>(
      method: 'GET',
      path: HomeEndpoints.getClassroomById(classroomId),
      fromData: (data) {
        final obj = (data['classroom'] as Map<String, dynamic>? ?? {});
        return ClassroomDetail.fromJson(obj);
      },
    );
  }
}
