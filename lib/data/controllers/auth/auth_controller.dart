import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class AuthController extends GetxController {
  final _box = GetStorage();

  final identifierController = TextEditingController();
  final schoolIdController = TextEditingController();
  final passwordController = TextEditingController();

  var isPasswordVisible = false.obs;
  var isLoading = false.obs;

  var identifierError = ''.obs;
  var schoolIdError = ''.obs;
  var passwordError = ''.obs;

  void validateIdentifier(String value) {
    if (value.isEmpty) {
      identifierError.value = "email_or_phone_required".tr;
    } else if (!GetUtils.isPhoneNumber(value.replaceAll(' ', ''))) {
      identifierError.value = 'invalid_email_or_phone'.tr;
    } else {
      identifierError.value = '';
    }
  }

  void validateSchoolId(String value) {
    if (value.isEmpty) {
      schoolIdError.value = "school_id_required".tr;
    } else if (value.length < 2) {
      schoolIdError.value = 'school_id_min_2_cha'.tr;
    } else {
      schoolIdError.value = '';
    }
  }

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

    validateIdentifier(identifierController.text);
    validateSchoolId(schoolIdController.text);
    validatePassword(passwordController.text);

    if (identifierController.text.isNotEmpty &&
        schoolIdController.text.isNotEmpty &&
        passwordController.text.isNotEmpty &&
        identifierError.value.isEmpty &&
        schoolIdError.value.isEmpty &&
        passwordError.value.isEmpty) {
      try {
        isLoading.value = true;
        
        Get.snackbar(
          "success".tr,
          "login_successful".tr,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        await Future.delayed(const Duration(seconds: 2));

        Get.offAllNamed('/otp');
      } catch (e) {
        // Get.snackbar(
        //   "error".tr,
        //   "login_error".tr,
        //   backgroundColor: Colors.red,
        //   colorText: Colors.white,
        // );
        print("Login error: $e");
      } finally {
        isLoading.value = false;
      }
    } else {
      // Get.snackbar(
      //   "error".tr,
      //   "fill_all_fields_correctly".tr,
      //   backgroundColor: Colors.orange,
      //   colorText: Colors.white,
      // );;
    }
  }

  void logout() {
    Get.dialog(
      AlertDialog(
        title: Text('logout'.tr),
        content: Text('confirm_logout'.tr),
        actions: [
          TextButton(child: Text('cancel'.tr), onPressed: () => Get.back()),
          TextButton(
            child: Text('ok'.tr),
            onPressed: () {
              _box.remove('token');
              _box.remove('user_phone');
              _box.remove('school_id');
              _box.remove('is_logged_in');

              Get.back();
              Get.offAllNamed('/login');
            },
          ),
        ],
      ),
    );
  }

  bool get isLoggedIn => _box.read('is_logged_in') ?? false;

  @override
  void onClose() {
    identifierController.dispose();
    schoolIdController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
