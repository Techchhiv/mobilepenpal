import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobilepenpal/core/theme/app_colors.dart';

class OtpController extends GetxController {
  final RxString otpCode = ''.obs;
  final RxBool isLoading = false.obs;
  final RxBool hasError = false.obs;

  void onOtpChanged(String code) {
    otpCode.value = code;
    hasError.value = false;
  }

  Future<void> verifyOtp() async {
    if (otpCode.value.length != 6) return;

    try {
      isLoading.value = true;
      
      await Future.delayed(const Duration(seconds: 2));
      
      if (otpCode.value == "123456") {
        Get.snackbar(
          'success'.tr,
          'otp_verified_successfully'.tr,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        Get.offAllNamed('/');
      } else {
        hasError.value = true;
        Get.snackbar(
          'error'.tr,
          'invalid_otp_code'.tr,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      hasError.value = true;
      Get.snackbar(
        'error'.tr,
        'verification_failed'.tr,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void resendOtp() {
    Get.snackbar(
      'info'.tr,
      'otp_resent_successfully'.tr,
      backgroundColor: Colors.blue[50],
      colorText: AppColors.primary,
    );
  }
}