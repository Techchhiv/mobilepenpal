import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mobilepenpal/core/theme/app_colors.dart';
import 'package:mobilepenpal/data/services/firebase_service.dart';
import 'package:mobilepenpal/data/services/auth_service.dart';

class OtpController extends GetxController {
  final FirebaseService _firebaseService = Get.find<FirebaseService>();
  final AuthService _authService = Get.find<AuthService>();
  final _box = GetStorage();

  final RxString otpCode = ''.obs;
  final RxBool isLoading = false.obs;
  final RxBool hasError = false.obs;
  final RxInt countdown = 60.obs;
  final RxBool canResend = false.obs;

  String get phoneNumber {
    final phone = _box.read('user_phone');
    return phone ?? '';
  }

  @override
  void onInit() {
    super.onInit();
    startCountdown();
  }

  void onOtpChanged(String code) {
    otpCode.value = code;
    hasError.value = false;
    
    if (code.length == 6) {
      verifyOtp();
    }
  }

  Future<void> verifyOtp() async {
    if (otpCode.value.length != 6) return;

    if (phoneNumber.isEmpty) {
      Get.snackbar(
        'error'.tr,
        'Phone number not found. Please login again.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    try {
      isLoading.value = true;
      hasError.value = false;

      final user = await _firebaseService.verifyOtp(otpCode.value);
      
      if (user != null) {
        final idToken = await user.getIdToken();

        final response = await _authService.verifyOtpAndGetToken(
          phone: phoneNumber,
          firebaseToken: idToken,
        );

        if (response.code == 200) {
          Get.snackbar(
            'success'.tr,
            'otp_verified_successfully'.tr,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
          
          // Navigate to home page
          Get.offAllNamed('/home');
        } else {
          hasError.value = true;
          Get.snackbar(
            'error'.tr,
            response.message ?? 'verification_failed'.tr,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
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

  Future<void> resendOtp() async {
    if (!canResend.value) return;

    if (phoneNumber.isEmpty) {
      Get.snackbar(
        'error'.tr,
        'Phone number not found. Please login again.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    try {
      countdown.value = 60;
      canResend.value = false;
      
      final error = await _firebaseService.sendOtp(phoneNumber);
      
      if (error == null) {
        Get.snackbar(
          'info'.tr,
          'otp_resent_successfully'.tr,
          backgroundColor: Colors.blue[50],
          colorText: AppColors.primary,
        );
        startCountdown();
      } else {
        Get.snackbar(
          'error'.tr,
          error,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        canResend.value = true;
      }
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        'failed_to_resend_otp'.tr,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      canResend.value = true;
    }
  }

  void startCountdown() {
    canResend.value = false;
    countdown.value = 60;

    Future.delayed(const Duration(seconds: 1), () {
      if (countdown.value > 0) {
        countdown.value--;
        startCountdown();
      } else {
        canResend.value = true;
      }
    });
  }

  String get countdownText {
    if (canResend.value) return "resend".tr;
    return "${'resend_in'.tr} ${countdown.value}s";
  }

  String get maskedPhoneNumber {
    if (phoneNumber.isEmpty || phoneNumber.length < 4) return phoneNumber;
    final lastFour = phoneNumber.substring(phoneNumber.length - 4);
    return '+855 ••• ••• $lastFour';
  }
}