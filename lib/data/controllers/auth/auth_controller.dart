import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mobilepenpal/data/services/auth_service.dart';

class AuthController extends GetxController {
  final AuthService _authService = AuthService();
  final _box = GetStorage();

  final phoneController = TextEditingController();
  // final schoolIdController = TextEditingController();
  final passwordController = TextEditingController();

  var isPasswordVisible = false.obs;
  var isLoading = false.obs;

  var phoneError = ''.obs;
  var schoolIdError = ''.obs;
  var passwordError = ''.obs;

  Map<String, dynamic>? get studentData => _box.read('student_data');

  bool get isLoggedIn => _box.read('is_logged_in') ?? false;

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

    validatePhone(phoneController.text);
    validatePassword(passwordController.text);

    if (phoneError.value.isNotEmpty ||
        // schoolIdError.value.isNotEmpty ||
        passwordError.value.isNotEmpty) {
      Get.snackbar(
        "error".tr,
        "fill_all_fields_correctly".tr,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    if (phoneController.text.isEmpty ||
        // schoolIdController.text.isEmpty ||
        passwordController.text.isEmpty) {
      Get.snackbar(
        "error".tr,
        "fill_all_fields".tr,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
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

        Get.offAllNamed('/home');
        // } else {
        //   Get.snackbar(
        //     "error".tr,
        //     error,
        //     backgroundColor: Colors.red,
        //     colorText: Colors.white,
        //   );
        // }
      } else {
        Get.snackbar(
          "error".tr,
          response.message,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  // @override
  // void onClose() {
  //   phoneController.dispose();
  //   passwordController.dispose();
  //   super.onClose();
  // }
}
