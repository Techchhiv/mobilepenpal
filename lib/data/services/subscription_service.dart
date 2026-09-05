import 'package:mobilepenpal/core/network/api_client.dart';
import 'package:mobilepenpal/core/network/endpoint/subscription.dart';
import 'package:mobilepenpal/data/models/api_response.dart';
import 'package:mobilepenpal/data/models/subscription/bakong_checkout.dart';

class SubscriptionService {
  final ApiClient _apiClient = ApiClient();

  /// Fetch system subscription pricing and Bakong account details.
  Future<ApiResponse<Map<String, dynamic>>> getPricing() async {
    return await _apiClient.request<Map<String, dynamic>>(
      method: 'GET',
      path: SubscriptionEndpoints.pricing,
      fromData: (data) => data is Map<String, dynamic> ? data['pricing'] ?? data : {},
    );
  }

  /// Request a dynamic Bakong KHQR checkout.
  Future<ApiResponse<BakongCheckoutModel>> checkout({
    String plan = 'monthly',
  }) async {
    return await _apiClient.request<BakongCheckoutModel>(
      method: 'POST',
      path: SubscriptionEndpoints.checkout,
      data: {
        'plan': plan,
      },
      fromData: (data) {
        final checkoutData = data is Map<String, dynamic>
            ? (data['checkout'] ?? data)
            : <String, dynamic>{};
        return BakongCheckoutModel.fromJson(Map<String, dynamic>.from(checkoutData));
      },
    );
  }

  /// Verify if the transaction has settled on Bakong network and unlock subscription.
  Future<ApiResponse<Map<String, dynamic>>> verifyPayment({
    required String md5,
    bool simulate = false,
  }) async {
    return await _apiClient.request<Map<String, dynamic>>(
      method: 'POST',
      path: SubscriptionEndpoints.verifyPayment,
      data: {
        'md5': md5,
        if (simulate) 'simulate': true,
      },
      fromData: (data) => data is Map<String, dynamic> ? data : {},
    );
  }
}
