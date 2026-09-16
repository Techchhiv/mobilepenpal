import 'dart:developer' as dev;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mobilepenpal/data/models/country_code.dart';
import 'package:mobilepenpal/data/services/analytics_service.dart';
import 'package:mobilepenpal/data/services/auth_service.dart';
import 'package:mobilepenpal/data/services/firebase_service.dart';
import 'package:mobilepenpal/presentation/routes/app_routes.dart';
import 'package:mobilepenpal/presentation/widgets/app_snackbar.dart';

class RegisterController extends GetxController {
  final AuthService _authService = AuthService();

  final studentFirstNameController = TextEditingController();
  final studentLastNameController = TextEditingController();

  final parentFirstNameController = TextEditingController();
  final parentLastNameController = TextEditingController();

  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final isLoading = false.obs;
  final isPasswordVisible = false.obs;
  final isConfirmPasswordVisible = false.obs;
  final isSubmitted = false.obs;

  final registerMethod = 'phone'.obs; // 'phone' or 'email'
  final showSecondaryContact = false.obs;
  final selectedCountry = CountryCode.defaultCountry.obs;

  @override
  void onInit() {
    super.onInit();
    _detectCountry();
  }

  Future<void> _detectCountry() async {
    final detected = await CountryCode.detectUserCountry();
    selectedCountry.value = detected;
  }

  String get fullPhoneNumber {
    String raw = phoneController.text.trim().replaceAll(RegExp(r'[^\d]'), '');
    if (raw.startsWith('0')) {
      raw = raw.substring(1);
    }
    if (raw.isEmpty) return '';
    return '${selectedCountry.value.dialCode}$raw';
  }

  final studentFirstNameError = ''.obs;
  final studentLastNameError = ''.obs;

  final parentFirstNameError = ''.obs;
  final parentLastNameError = ''.obs;

  final phoneError = ''.obs;
  final emailError = ''.obs;
  final passwordError = ''.obs;
  final confirmPasswordError = ''.obs;

  void setRegisterMethod(String method) {
    registerMethod.value = method;
    showSecondaryContact.value = false;
    _clearFieldErrors();
  }

  void toggleSecondaryContact() {
    showSecondaryContact.value = !showSecondaryContact.value;
    if (!showSecondaryContact.value) {
      if (registerMethod.value == 'phone') {
        emailController.clear();
        emailError.value = '';
      } else {
        phoneController.clear();
        phoneError.value = '';
      }
    }
  }

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  void toggleConfirmPasswordVisibility() {
    isConfirmPasswordVisible.value = !isConfirmPasswordVisible.value;
  }

  void validateStudentFirstName(String v) {
    if (!isSubmitted.value) {
      studentFirstNameError.value = '';
      return;
    }
    studentFirstNameError.value = v.trim().isEmpty ? 'field_required'.tr : '';
  }

  void validateStudentLastName(String v) {
    if (!isSubmitted.value) {
      studentLastNameError.value = '';
      return;
    }
    studentLastNameError.value = '';
  }

  void validateParentFirstName(String v) {
    if (!isSubmitted.value) {
      parentFirstNameError.value = '';
      return;
    }
    parentFirstNameError.value = v.trim().isEmpty ? 'field_required'.tr : '';
  }

  void validateParentLastName(String v) {
    if (!isSubmitted.value) {
      parentLastNameError.value = '';
      return;
    }
    parentLastNameError.value = v.trim().isEmpty ? 'field_required'.tr : '';
  }

  void validatePhone(String v) {
    if (!isSubmitted.value) {
      phoneError.value = '';
      return;
    }
    final value = v.trim().replaceAll(' ', '');
    final isPrimary = registerMethod.value == 'phone';

    if (value.isEmpty) {
      if (isPrimary && emailController.text.trim().isEmpty) {
        phoneError.value = 'phone_required'.tr;
      } else {
        phoneError.value = '';
      }
      return;
    }
    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length < 6 || digitsOnly.length > 15) {
      phoneError.value = 'invalid_phone'.tr;
    } else {
      phoneError.value = '';
    }
  }

  void validateEmail(String v) {
    if (!isSubmitted.value) {
      emailError.value = '';
      return;
    }
    final value = v.trim();
    final isPrimary = registerMethod.value == 'email';

    if (value.isEmpty) {
      if (isPrimary && phoneController.text.trim().isEmpty) {
        emailError.value = 'email_required'.tr;
      } else {
        emailError.value = '';
      }
      return;
    }
    emailError.value = GetUtils.isEmail(value) ? '' : 'invalid_email'.tr;
  }

  void validatePassword(String v) {
    if (!isSubmitted.value) {
      passwordError.value = '';
      return;
    }
    if (v.isEmpty) {
      passwordError.value = 'password_required'.tr;
    } else if (v.length < 6) {
      passwordError.value = 'password_min_6_cha'.tr;
    } else {
      passwordError.value = '';
    }
  }

  void validateConfirmPassword(String v) {
    if (!isSubmitted.value) {
      confirmPasswordError.value = '';
      return;
    }
    if (v.isEmpty) {
      confirmPasswordError.value = 'confirm_password_required'.tr;
    } else if (v != passwordController.text) {
      confirmPasswordError.value = 'passwords_do_not_match'.tr;
    } else {
      confirmPasswordError.value = '';
    }
  }

  bool get hasErrors =>
      studentFirstNameError.value.isNotEmpty ||
      studentLastNameError.value.isNotEmpty ||
      parentFirstNameError.value.isNotEmpty ||
      parentLastNameError.value.isNotEmpty ||
      phoneError.value.isNotEmpty ||
      emailError.value.isNotEmpty ||
      passwordError.value.isNotEmpty ||
      confirmPasswordError.value.isNotEmpty;

  void _clearFieldErrors() {
    studentFirstNameError.value = '';
    studentLastNameError.value = '';
    parentFirstNameError.value = '';
    parentLastNameError.value = '';
    phoneError.value = '';
    emailError.value = '';
    passwordError.value = '';
    confirmPasswordError.value = '';
  }

  void _applyServerErrors(Map<String, List<String>>? fieldErrors) {
    if (fieldErrors == null || fieldErrors.isEmpty) return;

    String? firstMsg(String key) {
      final list = fieldErrors[key];
      if (list == null || list.isEmpty) return null;
      return list.first;
    }

    final fn = firstMsg('first_name');
    if (fn != null) studentFirstNameError.value = fn;

    final ln = firstMsg('last_name');
    if (ln != null) studentLastNameError.value = ln;

    final pfn = firstMsg('parent_first_name');
    if (pfn != null) parentFirstNameError.value = pfn;

    final pln = firstMsg('parent_last_name');
    if (pln != null) parentLastNameError.value = pln;

    final ph = firstMsg('phone');
    if (ph != null) phoneError.value = ph;

    final em = firstMsg('email');
    if (em != null) emailError.value = em;

    final pw = firstMsg('password');
    if (pw != null) passwordError.value = pw;
  }

  String? get firstLocalError {
    if (studentFirstNameError.value.isNotEmpty) return studentFirstNameError.value;
    if (studentLastNameError.value.isNotEmpty) return studentLastNameError.value;
    if (parentFirstNameError.value.isNotEmpty) return parentFirstNameError.value;
    if (parentLastNameError.value.isNotEmpty) return parentLastNameError.value;
    if (emailError.value.isNotEmpty) return emailError.value;
    if (phoneError.value.isNotEmpty) return phoneError.value;
    if (passwordError.value.isNotEmpty) return passwordError.value;
    if (confirmPasswordError.value.isNotEmpty) return confirmPasswordError.value;
    return null;
  }

  Future<void> registerParent() async {
    if (isLoading.value) return;

    isSubmitted.value = true;

    validateStudentFirstName(studentFirstNameController.text);
    validateStudentLastName(studentLastNameController.text);

    validateParentFirstName(parentFirstNameController.text);
    validateParentLastName(parentLastNameController.text);

    validatePhone(phoneController.text);
    validateEmail(emailController.text);

    validatePassword(passwordController.text);
    validateConfirmPassword(confirmPasswordController.text);

    if (hasErrors) {
      AppSnackbar.show(
        firstLocalError ?? 'fill_all_fields_correctly'.tr,
        title: 'error'.tr,
        backgroundColor: Colors.orange,
      );
      return;
    }

    try {
      final registeredEmail = emailController.text.trim();
      final registeredPhone = fullPhoneNumber;
      final rawPassword = passwordController.text;

      isLoading.value = true;

      // 1. Check if user (phone and/or email) already exists in backend database first
      final checkResponse = await _authService.checkExists(
        phone: registeredPhone.isNotEmpty ? registeredPhone : null,
        email: registeredEmail.isNotEmpty ? registeredEmail : null,
      );

      if (checkResponse.code != 200) {
        isLoading.value = false;
        _clearFieldErrors();
        _applyServerErrors(checkResponse.fieldErrors);

        String errorMsg = '';
        if (checkResponse.fieldErrors != null && checkResponse.fieldErrors!.isNotEmpty) {
          for (var list in checkResponse.fieldErrors!.values) {
            if (list.isNotEmpty) {
              errorMsg = list.first;
              break;
            }
          }
        }
        if (errorMsg.isEmpty && checkResponse.errors != null && checkResponse.errors!.isNotEmpty) {
          errorMsg = checkResponse.errors!.first;
        }
        if (errorMsg.isEmpty) {
          errorMsg = checkResponse.message;
        }

        // If field error wasn't mapped by key, set on appropriate field
        if (phoneError.value.isEmpty && emailError.value.isEmpty) {
          if (registerMethod.value == 'phone') {
            phoneError.value = errorMsg;
          } else {
            emailError.value = errorMsg;
          }
        }

        AppSnackbar.show(
          errorMsg.isNotEmpty ? errorMsg : 'user_already_exists'.tr,
          title: 'error'.tr,
          backgroundColor: Colors.red,
        );
        return;
      }

      // 2. When registering via phone, verify ownership using Firebase Phone OTP first
      if (registerMethod.value == 'phone' && registeredPhone.isNotEmpty) {
        final firebaseService = Get.find<FirebaseService>();

        await firebaseService.sendOtp(
          phoneNumber: registeredPhone,
          onCodeSent: (verificationId) {
            isLoading.value = false;

            final regData = {
              'verificationId': verificationId,
              'phone': registeredPhone,
              'studentFirstName': studentFirstNameController.text.trim(),
              'studentLastName': studentLastNameController.text.trim().isEmpty
                  ? null
                  : studentLastNameController.text.trim(),
              'parentFirstName': parentFirstNameController.text.trim(),
              'parentLastName': parentLastNameController.text.trim(),
              'email': registeredEmail.isEmpty ? null : registeredEmail,
              'password': rawPassword,
              'createdAt': DateTime.now().millisecondsSinceEpoch,
            };

            GetStorage().write('pending_registration', regData);

            Get.toNamed(
              AppRoutes.otp,
              arguments: regData,
            );
          },
          onError: (error) {
            isLoading.value = false;
            AppSnackbar.show(
              error,
              title: 'error'.tr,
              backgroundColor: Colors.red,
            );
          },
          onAutoVerify: (credential) async {
            dev.log('Auto verification detected in registration', name: 'RegisterController');
          },
        );
        return;
      }

      isLoading.value = true;

      final response = await _authService.registerParent(
        studentFirstName: studentFirstNameController.text.trim(),
        studentLastName: studentLastNameController.text.trim().isEmpty
            ? null
            : studentLastNameController.text.trim(),
        parentFirstName: parentFirstNameController.text.trim(),
        parentLastName: parentLastNameController.text.trim(),
        email: registeredEmail.isEmpty ? null : registeredEmail,
        phone: registeredPhone.isEmpty ? null : registeredPhone,
        password: rawPassword,
      );

      if (response.code == 200) {
        FocusManager.instance.primaryFocus?.unfocus();

        // If email was provided, create Firebase account in background without sending verification email yet
        if (registeredEmail.isNotEmpty) {
          try {
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
              email: registeredEmail,
              password: rawPassword,
            );
          } catch (e) {
            dev.log('Firebase user creation background info: $e', name: 'RegisterController');
          }
        }

        if (Get.isRegistered<AnalyticsService>()) {
          Get.find<AnalyticsService>().logSignUp(
            signUpMethod: registeredPhone.isNotEmpty ? 'phone' : 'email',
          );
        }

        final bool hasPhone = registeredPhone.isNotEmpty;

        // Prioritize phone: auto-login immediately if phone was provided or auth token is present
        if (hasPhone || response.data?['token'] != null) {
          await GetStorage().write('is_logged_in', true);
          await GetStorage().write('has_token', true);

          clearForm();

          Get.offAllNamed(AppRoutes.home);
          AppSnackbar.show(
            'welcome'.tr,
            title: 'success'.tr,
            backgroundColor: Colors.green,
          );
          return;
        }

        clearForm();

        Get.offAllNamed(
          AppRoutes.login,
          arguments: {'email': registeredEmail},
        );

        AppSnackbar.show(
          'verification_email_sent'.trParams({'email': registeredEmail}),
          title: 'success'.tr,
          backgroundColor: Colors.green,
        );
        return;
      }

      _clearFieldErrors();
      _applyServerErrors(response.fieldErrors);

      String firstError = '';
      if (response.fieldErrors != null && response.fieldErrors!.isNotEmpty) {
        for (var list in response.fieldErrors!.values) {
          if (list.isNotEmpty) {
            firstError = list.first;
            break;
          }
        }
      }

      if (firstError.isEmpty && response.errors != null && response.errors!.isNotEmpty) {
        firstError = response.errors!.first;
      }

      if (firstError.isEmpty) {
        firstError = response.message;
      }

      AppSnackbar.show(
        firstError,
        title: 'error'.tr,
        backgroundColor: Colors.red,
      );
    } catch (e) {
      AppSnackbar.show(
        'an_error_occurred'.tr,
        title: 'error'.tr,
        backgroundColor: Colors.red,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void clearForm() {
    studentFirstNameController.clear();
    studentLastNameController.clear();
    parentFirstNameController.clear();
    parentLastNameController.clear();
    phoneController.clear();
    emailController.clear();
    passwordController.clear();
    confirmPasswordController.clear();

    isSubmitted.value = false;
    _clearFieldErrors();
    GetStorage().remove('pending_registration');
  }

  @override
  void onClose() {
    studentFirstNameController.dispose();
    studentLastNameController.dispose();
    parentFirstNameController.dispose();
    parentLastNameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}
