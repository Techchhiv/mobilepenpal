import 'package:mobilepenpal/core/network/api_client.dart';
import 'package:mobilepenpal/core/network/endpoint/shop.dart';
import 'package:mobilepenpal/data/models/api_response.dart';
import 'package:mobilepenpal/data/models/student/student.dart';

class ShopService {
  final ApiClient _apiClient = ApiClient();

  /// Submits the purchase of an avatar to the backend.
  Future<ApiResponse<Student>> purchaseAvatar({
    required String avatarName,
    required int cost,
  }) async {
    final result = await _apiClient.request<Student>(
      method: 'POST',
      path: ShopEndpoints.purchaseAvatar,
      data: {
        'avatar': avatarName,
        'cost': cost,
      },
      fromData: (data) => Student.fromJson(data['student']),
    );

    return result;
  }
}
