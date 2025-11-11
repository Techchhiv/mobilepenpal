import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mobilepenpal/core/theme/app_colors.dart';
import 'package:mobilepenpal/data/services/firebase_service.dart';
import 'package:mobilepenpal/data/services/auth_service.dart';
import 'package:mobilepenpal/presentation/widgets/loading_model.dart';

class OtpController extends GetxController {
  final FirebaseService _firebaseService = Get.find<FirebaseService>();
  final AuthService _authService = Get.find<AuthService>();
  final _box = GetStorage();

  final RxString otpCode = ''.obs;
  final RxBool isLoading = false.obs;
  final RxBool hasError = false.obs;
  final RxInt countdown = 60.obs;
  final RxBool canResend = false.obs;
  final RxString countdownText = "".obs;

  String get phoneNumber {
    final phone = _box.read('user_phone');
    return phone ?? '';
  }

  @override
  void onInit() {
    super.onInit();
    _updateCountdownText();
    startCountdown();
  }

  void onOtpChanged(String code) {
    otpCode.value = code;
    hasError.value = false;
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

      Get.dialog(
        const LoadingModal(message: 'Verifying...'),
        barrierDismissible: false,
        barrierColor: Colors.transparent,
      );

      final user = await _firebaseService.verifyOtp(otpCode.value);

      if (user != null) {
        final idToken = await user.getIdToken();

        final response = await _authService.verifyOtpAndGetToken(
          phone: phoneNumber,
          firebaseToken: idToken,
        );

        if (response.code == 200) {
          if (Get.isDialogOpen ?? false) {
            Get.back();
          }

          Get.dialog(
            const LoadingModal(message: 'Success!', isSuccess: true),
            barrierDismissible: false,
            barrierColor: Colors.transparent,
          );

          await Future.delayed(const Duration(seconds: 1));

          if (Get.isDialogOpen ?? false) {
            Get.back();
          }

          Get.offAllNamed('/home');
        } else {
          _handleError(response.message);
        }
      } else {
        _handleError('invalid_otp_code'.tr);
      }
    } catch (e) {
      _handleError('verification_failed'.tr);
    } finally {
      isLoading.value = false;
    }
  }

  void _handleError(String errorMessage) {
    hasError.value = true;

    if (Get.isDialogOpen ?? false) {
      Get.back();
    }

    Get.snackbar(
      'error'.tr,
      errorMessage,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
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
      _updateCountdownText();

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
        _updateCountdownText();
      }
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        'failed_to_resend_otp'.tr,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      canResend.value = true;
      _updateCountdownText();
    }
  }

  void startCountdown() {
    canResend.value = false;
    countdown.value = 60;
    _updateCountdownText();

    _runCountdown();
  }

  void _runCountdown() {
    if (countdown.value > 0) {
      Future.delayed(const Duration(seconds: 1), () {
        countdown.value--;
        _updateCountdownText();
        _runCountdown();
      });
    } else {
      canResend.value = true;
      _updateCountdownText();
    }
  }

  void _updateCountdownText() {
    if (canResend.value) {
      countdownText.value = "resend".tr;
    } else {
      countdownText.value = "${'resend_in'.tr} ${countdown.value}s";
    }
  }

  String get maskedPhoneNumber {
    if (phoneNumber.isEmpty || phoneNumber.length < 4) return phoneNumber;
    final lastFour = phoneNumber.substring(phoneNumber.length - 3);
    return '+855 ••• ••• $lastFour';
  }
}
