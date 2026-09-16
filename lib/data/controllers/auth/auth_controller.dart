import 'dart:developer' as dev;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mobilepenpal/core/network/api_client.dart';
import 'package:mobilepenpal/data/models/country_code.dart';
import 'package:mobilepenpal/data/models/student/student.dart';
import 'package:mobilepenpal/data/services/analytics_service.dart';
import 'package:mobilepenpal/data/services/auth_service.dart';
import 'package:mobilepenpal/presentation/routes/app_routes.dart';
import 'package:mobilepenpal/presentation/widgets/app_snackbar.dart';
import 'package:mobilepenpal/presentation/widgets/auth/unverified_email_dialog.dart';
import 'package:mobilepenpal/presentation/widgets/confirm_modal.dart';

class AuthController extends GetxController {
  final AuthService _authService = AuthService();

  final loginMethod = 'phone'.obs; // 'phone' or 'email'
  final selectedCountry = CountryCode.defaultCountry.obs;

  TextEditingController emailController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  var isPasswordVisible = false.obs;
  var isLoading = false.obs;

  var emailError = ''.obs;
  var phoneError = ''.obs;
  var passwordError = ''.obs;
  var isSubmitted = false.obs;

  String get fullPhoneNumber {
    String raw = phoneController.text.trim().replaceAll(RegExp(r'[^\d]'), '');
    if (raw.startsWith('0')) {
      raw = raw.substring(1);
    }
    if (raw.isEmpty) return '';
    return '${selectedCountry.value.dialCode}$raw';
  }

  void _ensureControllersActive() {
    try {
      emailController.text;
    } catch (_) {
      emailController = TextEditingController();
    }
    try {
      phoneController.text;
    } catch (_) {
      phoneController = TextEditingController();
    }
    try {
      passwordController.text;
    } catch (_) {
      passwordController = TextEditingController();
    }
  }

  @override
  void onInit() {
    super.onInit();
    _ensureControllersActive();
    _detectCountry();
    final args = Get.arguments;
    if (args is Map && args['email'] != null) {
      loginMethod.value = 'email';
      emailController.text = args['email'].toString();
    } else if (kDebugMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Pre-fill only if testing in debug mode
        if (emailController.text.isEmpty && phoneController.text.isEmpty) {
          phoneController.text = '81347800';
          passwordController.text = 'password123';
        }
      });
    }
  }

  Future<void> _detectCountry() async {
    final detected = await CountryCode.detectUserCountry();
    selectedCountry.value = detected;
  }

  void setLoginMethod(String method) {
    _ensureControllersActive();
    loginMethod.value = method;
    emailError.value = '';
    phoneError.value = '';
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

  void validatePhone(String value) {
    if (!isSubmitted.value) {
      phoneError.value = '';
      return;
    }

    final trimmed = value.trim().replaceAll(' ', '');
    if (trimmed.isEmpty) {
      phoneError.value = 'phone_required'.tr;
      return;
    }

    final digitsOnly = trimmed.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length < 6 || digitsOnly.length > 15) {
      phoneError.value = 'invalid_phone'.tr;
    } else {
      phoneError.value = '';
    }
  }

  void validatePassword(String value) {
    if (!isSubmitted.value) {
      passwordError.value = '';
      return;
    }

    if (value.isEmpty) {
      passwordError.value = 'password_required'.tr;
    } else {
      passwordError.value = '';
    }
  }

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  String? get firstLocalError {
    if (loginMethod.value == 'phone' && phoneError.value.isNotEmpty) return phoneError.value;
    if (loginMethod.value == 'email' && emailError.value.isNotEmpty) return emailError.value;
    if (passwordError.value.isNotEmpty) return passwordError.value;
    return null;
  }

  Future<void> login({bool confirm = false}) async {
    if (!confirm && isLoading.value) return;

    isSubmitted.value = true;
    final isPhoneTab = loginMethod.value == 'phone';

    if (isPhoneTab) {
      validatePhone(phoneController.text);
    } else {
      validateEmail(emailController.text);
    }
    validatePassword(passwordController.text);

    if ((isPhoneTab && phoneError.value.isNotEmpty) ||
        (!isPhoneTab && emailError.value.isNotEmpty) ||
        passwordError.value.isNotEmpty) {
      AppSnackbar.show(
        firstLocalError ?? "fill_all_fields_correctly".tr,
        title: "error".tr,
        backgroundColor: Colors.orange,
      );
      return;
    }

    final input = isPhoneTab ? fullPhoneNumber : emailController.text.trim();

    if (input.isEmpty || passwordController.text.isEmpty) {
      AppSnackbar.show(
        "fill_all_fields".tr,
        title: "error".tr,
        backgroundColor: Colors.orange,
      );
      return;
    }

    try {
      isLoading.value = true;

      final isEmailInput = !isPhoneTab && input.contains('@');

      final response = await _authService.loginStudent(
        login: input,
        password: passwordController.text,
        confirm: confirm,
      );

      if (response.code == 200) {
        final studentObj = response.data?['student'];
        final Student? student = studentObj is Student ? studentObj : null;

        // If account is school user or phone login, bypass Firebase email verification check
        final isSchoolUser = student != null && student.isSchoolAccount;

        if (!isSchoolUser && isEmailInput) {
          // Check Firebase Email Verification for regular email accounts
          try {
            User? fbUser = FirebaseAuth.instance.currentUser;
            if (fbUser == null || fbUser.email != input) {
              final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
                email: input,
                password: passwordController.text,
              );
              fbUser = cred.user;
            }

            if (fbUser != null) {
              await fbUser.reload();
              fbUser = FirebaseAuth.instance.currentUser;

              if (fbUser != null && !fbUser.emailVerified) {
                // Clear token saved by loginStudent so session is not kept active
                await ApiClient().clearToken();
                isLoading.value = false;
                final email = input;
                final password = passwordController.text;
                showUnverifiedEmailDialog(
                  email: email,
                  onResend: () => resendVerificationEmail(
                    email: email,
                    password: password,
                  ),
                );
                return;
              }
            }
          } catch (fbErr) {
            // Continue if Firebase user check fails or is not required for dev accounts
          }
        }

        FocusManager.instance.primaryFocus?.unfocus();
        await GetStorage().write('is_logged_in', true);
        await GetStorage().write('has_token', true);

        if (Get.isRegistered<AnalyticsService>()) {
          final analytics = Get.find<AnalyticsService>();
          analytics.logLogin(loginMethod: isPhoneTab ? 'phone' : 'email');
          if (student != null) {
            analytics.setUserId(student.id.toString());
          }
        }

        Get.offAllNamed(AppRoutes.home);
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
            body: Text(
              'already_logged_in_message'.tr,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF4B5563),
                height: 1.5,
              ),
            ),
          ),
        );

        if (proceed == true) {
          login(confirm: true);
        }
      } else {
        AppSnackbar.show(
          response.message,
          title: "error".tr,
          backgroundColor: Colors.red,
        );
      }
    } catch (e) {
      AppSnackbar.show(
        'something_went_wrong'.tr,
        title: "error".tr,
        backgroundColor: Colors.red,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void showUnverifiedEmailDialog({
    required String email,
    required Future<bool> Function() onResend,
  }) {
    Get.dialog(
      UnverifiedEmailDialog(
        email: email,
        onResend: onResend,
      ),
      barrierDismissible: false,
    );
  }

  Future<bool> resendVerificationEmail({
    required String email,
    required String password,
  }) async {
    try {
      User? fbUser = FirebaseAuth.instance.currentUser;

      if (fbUser == null || fbUser.email != email) {
        final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        fbUser = cred.user;
      }

      if (fbUser == null) {
        AppSnackbar.show(
          'something_went_wrong'.tr,
          title: 'error'.tr,
          backgroundColor: Colors.red,
        );
        return false;
      }

      await fbUser.reload();
      fbUser = FirebaseAuth.instance.currentUser;

      if (fbUser != null && fbUser.emailVerified) {
        AppSnackbar.show(
          'email_already_verified'.tr,
          title: 'success'.tr,
          backgroundColor: Colors.green,
        );
        return false;
      }

      await fbUser?.sendEmailVerification();

      AppSnackbar.show(
        'verification_email_resent'.tr,
        title: 'success'.tr,
        backgroundColor: Colors.green,
      );
      return true;
    } on FirebaseAuthException catch (e) {
      dev.log('Resend verification error: ${e.code} - ${e.message}', name: 'AuthController');
      if (e.code == 'too-many-requests') {
        AppSnackbar.show(
          'too_many_requests'.tr,
          title: 'error'.tr,
          backgroundColor: Colors.red,
        );
      } else {
        AppSnackbar.show(
          'something_went_wrong'.tr,
          title: 'error'.tr,
          backgroundColor: Colors.red,
        );
      }
      return false;
    } catch (e) {
      dev.log('Resend verification general error: $e', name: 'AuthController');
      AppSnackbar.show(
        'something_went_wrong'.tr,
        title: 'error'.tr,
        backgroundColor: Colors.red,
      );
      return false;
    }
  }
}
