import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mobilepenpal/core/network/api_client.dart';
import 'package:mobilepenpal/data/services/firebase_service.dart';

class AppBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<GetStorage>(GetStorage(), permanent: true);
    Get.lazyPut<ApiClient>(() => ApiClient(), fenix: true);
    Get.lazyPut<FirebaseService>(() => FirebaseService(), fenix: true);
  }
}
