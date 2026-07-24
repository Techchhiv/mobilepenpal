import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mobilepenpal/data/services/auth_service.dart';
import 'package:mobilepenpal/presentation/routes/app_routes.dart';
import 'package:mobilepenpal/presentation/widgets/app_snackbar.dart';
import 'package:mobilepenpal/presentation/widgets/confirm_modal.dart';

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

  var selectedCountryCode = '+855'.obs;

  String get fullPhoneNumber {
    final number = phoneController.text.trim().replaceAll(' ', '');
    if (number.isEmpty) return '';
    if (number.startsWith('+')) {
      return number;
    }
    final sanitized = number.startsWith('0') ? number.substring(1) : number;
    return '${selectedCountryCode.value}$sanitized';
  }

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
      return;
    }
    final fullNumber = fullPhoneNumber;
    final digitsOnly = fullNumber.replaceAll(RegExp(r'\D'), '');
    if (!GetUtils.isPhoneNumber(fullNumber) || digitsOnly.length < 7 || digitsOnly.length > 15) {
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

  Future<void> login({bool confirm = false}) async {
    if (!confirm && isLoading.value) return;

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
        phone: fullPhoneNumber,
        password: passwordController.text,
        confirm: confirm,
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
        await GetStorage().write('is_logged_in', true);
        await GetStorage().write('has_token', true);
        Get.offAllNamed(AppRoutes.home);
        // } else {
        //   Get.snackbar(
        //     "error".tr,
        //     error,
        //     backgroundColor: Colors.red,
        //     colorText: Colors.white,
        //   );
        // }
      } else if (response.code == 409) {
        isLoading.value = false;
        final proceed = await showConfirmModal<bool>(
          dismissible: false,
          modal: ConfirmModal<bool>(
            icon: const Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange,
              size: 28,
            ),
            title: Text('already_logged_in_title'.tr),
            primaryText: 'yes'.tr,
            secondaryText: 'no'.tr,
            primaryColor: Colors.orange,
            primaryTextColor: Colors.white,
            secondaryTextColor: const Color(0xFF111827),
            showCloseButton: false,
            primaryResult: true,
            secondaryResult: false,
          ),
        );

        if (proceed == true) {
          await login(confirm: true);
        }
      } else {
        AppSnackbar.show(
          response.message,
          title: "error".tr,
          backgroundColor: Colors.red,
        );
      }
    } finally {
      if (!confirm || isLoading.value) {
        isLoading.value = false;
      }
    }
  }
}
