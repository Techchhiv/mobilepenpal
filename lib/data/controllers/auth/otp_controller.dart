import 'dart:async';
import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mobilepenpal/core/theme/app_colors.dart';
import 'package:mobilepenpal/data/models/country_code.dart';
import 'package:mobilepenpal/data/services/analytics_service.dart';
import 'package:mobilepenpal/data/services/auth_service.dart';
import 'package:mobilepenpal/data/services/firebase_service.dart';
import 'package:mobilepenpal/presentation/routes/app_routes.dart';
import 'package:mobilepenpal/presentation/widgets/app_snackbar.dart';

class OtpController extends GetxController {
  final FirebaseService _firebaseService = Get.find<FirebaseService>();
  final AuthService _authService = AuthService();

  final RxString otpCode = ''.obs;
  final RxBool isLoading = false.obs;
  final RxBool hasError = false.obs;
  final RxInt countdown = 60.obs;
  final RxBool canResend = false.obs;
  final RxString countdownText = "".obs;

  final RxString verificationId = ''.obs;
  final RxString phoneNumber = ''.obs;
  Map<String, dynamic> registrationData = {};

  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    _loadArguments();
    _updateCountdownText();
    startCountdown();
  }

  void _loadArguments() {
    final args = Get.arguments;
    if (args is Map<String, dynamic>) {
      registrationData = args;
      verificationId.value = args['verificationId'] ?? '';
      phoneNumber.value = args['phone'] ?? '';
    } else if (args is Map) {
      registrationData = Map<String, dynamic>.from(args);
      verificationId.value = args['verificationId']?.toString() ?? '';
      phoneNumber.value = args['phone']?.toString() ?? '';
    }

    if (verificationId.isEmpty) {
      verificationId.value = _firebaseService.verificationId.value;
    }
  }

  void onOtpChanged(String code) {
    otpCode.value = code;
    hasError.value = false;
  }

  Future<void> verifyOtp() async {
    if (isLoading.value) return;
    if (otpCode.value.trim().length != 6) {
      hasError.value = true;
      return;
    }

    try {
      isLoading.value = true;
      hasError.value = false;

      // 1. Verify OTP with Firebase
      final user = await _firebaseService.verifyOtp(
        smsCode: otpCode.value.trim(),
        customVerificationId: verificationId.value,
      );

      if (user == null) {
        throw Exception('invalid_otp_code'.tr);
      }

      dev.log('Firebase phone verification successful for user: ${user.uid}', name: 'OtpController');

      // 2. Finalize account registration on backend
      final studentFirstName = registrationData['studentFirstName'] as String? ?? '';
      final studentLastName = registrationData['studentLastName'] as String?;
      final parentFirstName = registrationData['parentFirstName'] as String? ?? '';
      final parentLastName = registrationData['parentLastName'] as String? ?? '';
      final phone = registrationData['phone'] as String? ?? phoneNumber.value;
      final email = registrationData['email'] as String?;
      final password = registrationData['password'] as String? ?? '';

      final response = await _authService.registerParent(
        studentFirstName: studentFirstName,
        studentLastName: studentLastName,
        parentFirstName: parentFirstName,
        parentLastName: parentLastName,
        phone: phone.isNotEmpty ? phone : null,
        email: (email != null && email.isNotEmpty) ? email : null,
        password: password,
      );

      if (response.code == 200) {
        await GetStorage().write('is_logged_in', true);
        await GetStorage().write('has_token', true);

        if (Get.isRegistered<AnalyticsService>()) {
          Get.find<AnalyticsService>().logSignUp(signUpMethod: 'phone');
        }

        Get.offAllNamed(AppRoutes.home);

        AppSnackbar.show(
          'welcome'.tr,
          title: 'success'.tr,
          backgroundColor: Colors.green,
        );
      } else {
        hasError.value = true;
        String errorMessage = '';

        if (response.fieldErrors != null && response.fieldErrors!.isNotEmpty) {
          for (var list in response.fieldErrors!.values) {
            if (list.isNotEmpty) {
              errorMessage = list.first;
              break;
            }
          }
        }
        if (errorMessage.isEmpty && response.errors != null && response.errors!.isNotEmpty) {
          errorMessage = response.errors!.first;
        }
        if (errorMessage.isEmpty) {
          errorMessage = response.message;
        }

        AppSnackbar.show(
          errorMessage.isNotEmpty ? errorMessage : 'an_error_occurred'.tr,
          title: 'error'.tr,
          backgroundColor: Colors.red,
        );
      }
    } catch (e) {
      hasError.value = true;
      final message = e.toString().replaceFirst('Exception: ', '');
      AppSnackbar.show(
        message.isNotEmpty ? message : 'verification_failed'.tr,
        title: 'error'.tr,
        backgroundColor: Colors.red,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> resendOtp() async {
    if (!canResend.value || isLoading.value) return;

    final phone = phoneNumber.value;
    if (phone.isEmpty) {
      AppSnackbar.show(
        'Phone number not found. Please register again.',
        title: 'error'.tr,
        backgroundColor: Colors.red,
      );
      return;
    }

    try {
      canResend.value = false;
      countdown.value = 60;
      _updateCountdownText();

      await _firebaseService.sendOtp(
        phoneNumber: phone,
        onCodeSent: (newVerificationId) {
          verificationId.value = newVerificationId;
          startCountdown();
          AppSnackbar.show(
            'otp_resent_successfully'.tr,
            title: 'success'.tr,
            backgroundColor: AppColors.primary,
          );
        },
        onError: (error) {
          canResend.value = true;
          _updateCountdownText();
          AppSnackbar.show(
            error,
            title: 'error'.tr,
            backgroundColor: Colors.red,
          );
        },
        onAutoVerify: (credential) async {
          dev.log('Auto verified during resend', name: 'OtpController');
        },
      );
    } catch (e) {
      canResend.value = true;
      _updateCountdownText();
      AppSnackbar.show(
        'failed_to_resend_otp'.tr,
        title: 'error'.tr,
        backgroundColor: Colors.red,
      );
    }
  }

  void startCountdown() {
    _timer?.cancel();
    canResend.value = false;
    countdown.value = 60;
    _updateCountdownText();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (countdown.value > 0) {
        countdown.value--;
        _updateCountdownText();
      } else {
        canResend.value = true;
        _updateCountdownText();
        timer.cancel();
      }
    });
  }

  void _updateCountdownText() {
    if (canResend.value) {
      countdownText.value = "resend".tr;
    } else {
      countdownText.value = "${'resend_in'.tr} ${countdown.value}s";
    }
  }

  String get maskedPhoneNumber {
    final raw = phoneNumber.value.trim();
    if (raw.isEmpty) return '';

    String prefix = '+855';
    if (raw.startsWith('+')) {
      final digits = raw.substring(1);
      for (int len = 4; len >= 1; len--) {
        if (digits.length >= len) {
          final candidate = '+${digits.substring(0, len)}';
          final match = CountryCode.allCountries.firstWhereOrNull((c) => c.dialCode == candidate);
          if (match != null) {
            prefix = match.dialCode;
            break;
          }
        }
      }
    }

    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 6) {
      final lastThree = digits.substring(digits.length - 3);
      return '$prefix ••• ••• $lastThree';
    }
    return raw;
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}
