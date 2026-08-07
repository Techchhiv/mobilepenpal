import 'package:firebase_auth/firebase_auth.dart';
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

  final emailController = TextEditingController();
  // final phoneController = TextEditingController();
  // final schoolIdController = TextEditingController();
  final passwordController = TextEditingController();

  var isPasswordVisible = false.obs;
  var isLoading = false.obs;

  var emailError = ''.obs;
  // var phoneError = ''.obs;
  var schoolIdError = ''.obs;
  var passwordError = ''.obs;
  var isSubmitted = false.obs;

  // var selectedCountryCode = '+855'.obs;

  /*
  String get fullPhoneNumber {
    final number = phoneController.text.trim().replaceAll(' ', '');
    if (number.isEmpty) return '';
    if (number.startsWith('+')) {
      return number;
    }
    final sanitized = number.startsWith('0') ? number.substring(1) : number;
    return '${selectedCountryCode.value}$sanitized';
  }
  */

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map && args['email'] != null) {
      emailController.text = args['email'].toString();
    } else if (kDebugMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        emailController.text = 'amara@gmail.com';
        passwordController.text = 'password123';
      });
    }
  }

  void validateEmail(String value) {
    if (!isSubmitted.value) {
      emailError.value = '';
      return;
    }

    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      emailError.value = 'email_required'.tr;
      return;
    }

    if (!GetUtils.isEmail(trimmed)) {
      emailError.value = 'invalid_email'.tr;
    } else {
      emailError.value = '';
    }
  }

  /*
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
  */

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

  String? get firstLocalError {
    if (emailError.value.isNotEmpty) return emailError.value;
    if (passwordError.value.isNotEmpty) return passwordError.value;
    return null;
  }

  Future<void> login({bool confirm = false}) async {
    if (!confirm && isLoading.value) return;

    isSubmitted.value = true;
    validateEmail(emailController.text);
    validatePassword(passwordController.text);

    if (emailError.value.isNotEmpty ||
        // phoneError.value.isNotEmpty ||
        // schoolIdError.value.isNotEmpty ||
        passwordError.value.isNotEmpty) {
      AppSnackbar.show(
        firstLocalError ?? "fill_all_fields_correctly".tr,
        title: "error".tr,
        backgroundColor: Colors.orange,
      );
      return;
    }

    if (emailController.text.trim().isEmpty ||
        // phoneController.text.isEmpty ||
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

      // Check Firebase Email Verification
      try {
        User? fbUser = FirebaseAuth.instance.currentUser;
        if (fbUser == null || fbUser.email != emailController.text.trim()) {
          final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text,
          );
          fbUser = cred.user;
        }

        if (fbUser != null) {
          await fbUser.reload();
          fbUser = FirebaseAuth.instance.currentUser;

          if (fbUser != null && !fbUser.emailVerified) {
            isLoading.value = false;
            AppSnackbar.show(
              'email_not_verified'.tr,
              title: 'error'.tr,
              backgroundColor: Colors.orange,
            );
            return;
          }
        }
      } catch (fbErr) {
        // Continue if Firebase user check fails or is not required for dev accounts
      }

      final response = await _authService.loginStudent(
        email: emailController.text.trim(),
        password: passwordController.text,
        confirm: confirm,
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
        String errorMsg = response.message;
        if (response.fieldErrors != null && response.fieldErrors!.isNotEmpty) {
          for (var list in response.fieldErrors!.values) {
            if (list.isNotEmpty) {
              errorMsg = list.first;
              break;
            }
          }
        } else if (response.errors != null && response.errors!.isNotEmpty) {
          errorMsg = response.errors!.first;
        }

        AppSnackbar.show(
          errorMsg,
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
