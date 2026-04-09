import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mobilepenpal/core/config/env.dart';
import 'package:mobilepenpal/data/services/auth_service.dart';
import 'package:mobilepenpal/presentation/routes/app_routes.dart';
import 'package:mobilepenpal/presentation/widgets/app_snackbar.dart';

class AuthController extends GetxController {
  final AuthService _authService = AuthService();

  final phoneController = TextEditingController();
  // final schoolIdController = TextEditingController();
  final passwordController = TextEditingController();

  var isPasswordVisible = false.obs;
  var isLoading = false.obs;

  var phoneError = ''.obs;
  var schoolIdError = ''.obs;
  var passwordError = ''.obs;
  var isSubmitted = false.obs;

  @override
  void onInit() {
    super.onInit();
    if (kDebugMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        phoneController.text = '069558076';
        passwordController.text = 'password123';
      });
    }
  }

  void validatePhone(String value) {
    if (!isSubmitted.value) {
      phoneError.value = '';
      return;
    }

    if (value.isEmpty) {
      phoneError.value = "phone_required".tr;
    } else if (!GetUtils.isPhoneNumber(value.replaceAll(' ', ''))) {
      phoneError.value = 'invalid_phone'.tr;
    } else {
      phoneError.value = '';
    }
  }

  // void validateSchoolId(String value) {
  //   if (value.isEmpty) {
  //     schoolIdError.value = "school_id_required".tr;
  //   } else if (value.length < 2) {
  //     schoolIdError.value = 'school_id_min_2_cha'.tr;
  //   } else {
  //     schoolIdError.value = '';
  //   }
  // }

  void validatePassword(String value) {
    if (!isSubmitted.value) {
      passwordError.value = '';
      return;
    }

    if (value.isEmpty) {
      passwordError.value = 'password_required'.tr;
    } else if (value.length < 6) {
      passwordError.value = 'password_min_6_cha'.tr;
    } else {
      passwordError.value = '';
    }
  }

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  Future<void> login() async {
    if (isLoading.value) return;

    isSubmitted.value = true;
    validatePhone(phoneController.text);
    validatePassword(passwordController.text);

    if (phoneError.value.isNotEmpty ||
        // schoolIdError.value.isNotEmpty ||
        passwordError.value.isNotEmpty) {
      AppSnackbar.show(
        "fill_all_fields_correctly".tr,
        title: "error".tr,
        backgroundColor: Colors.orange,
      );
      return;
    }

    if (phoneController.text.isEmpty ||
        // schoolIdController.text.isEmpty ||
        passwordController.text.isEmpty) {
      AppSnackbar.show(
        "fill_all_fields".tr,
        title: "error".tr,
        backgroundColor: Colors.orange,
      );
      return;
    }

    try {
      isLoading.value = true;

      final response = await _authService.loginStudent(
        phone: phoneController.text.trim(),
        password: passwordController.text,
        // schoolKey: schoolIdController.text.trim(),
      );

      if (response.code == 200) {
        // final firebaseService = Get.find<FirebaseService>();
        // String phoneNumber = phoneController.text.trim();

        // final error = await firebaseService.sendOtp(phoneNumber);

        // if (error == null) {
        //   Get.snackbar(
        //     "success".tr,
        //     "otp_sent_successfully".tr,
        //     backgroundColor: Colors.green,
        //     colorText: Colors.white,
        //   );
        FocusManager.instance.primaryFocus?.unfocus();
        final token = await const FlutterSecureStorage().read(
          key: Env.accessToken,
        );
        final ok = token != null && token.trim().isNotEmpty;

        await GetStorage().write('is_logged_in', ok);
        Get.offAllNamed(AppRoutes.home);
        // } else {
        //   Get.snackbar(
        //     "error".tr,
        //     error,
        //     backgroundColor: Colors.red,
        //     colorText: Colors.white,
        //   );
        // }
      } else {
        AppSnackbar.show(
          response.message,
          title: "error".tr,
          backgroundColor: Colors.red,
        );
      }
    } finally {
      isLoading.value = false;
    }
  }
}
