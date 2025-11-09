import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mobilepenpal/data/services/auth_service.dart';
import 'package:mobilepenpal/data/services/firebase_service.dart';

class AuthController extends GetxController {
  final AuthService _authService = AuthService();
  final _box = GetStorage();

  final identifierController = TextEditingController();
  final schoolIdController = TextEditingController();
  final passwordController = TextEditingController();

  var isPasswordVisible = false.obs;
  var isLoading = false.obs;

  var identifierError = ''.obs;
  var schoolIdError = ''.obs;
  var passwordError = ''.obs;

  Map<String, dynamic>? get studentData => _box.read('student_data');

  bool get isLoggedIn => _box.read('is_logged_in') ?? false;

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
    identifierController.text = '069558076';
    schoolIdController.text = 'SCHOOL2024';
    passwordController.text = 'password123';

    validateIdentifier(identifierController.text);
    validateSchoolId(schoolIdController.text);
    validatePassword(passwordController.text);

    if (identifierError.value.isNotEmpty ||
        schoolIdError.value.isNotEmpty ||
        passwordError.value.isNotEmpty) {
      Get.snackbar(
        "error".tr,
        "fill_all_fields_correctly".tr,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    if (identifierController.text.isEmpty ||
        schoolIdController.text.isEmpty ||
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
        identifier: identifierController.text.trim(),
        password: passwordController.text,
        schoolKey: schoolIdController.text.trim(),
      );

      _saveStudentInfo(response.data?["student"]);

      if (response.code == 200) {
        final firebaseService = Get.find<FirebaseService>();
        String phoneNumber = identifierController.text.trim();

        final error = await firebaseService.sendOtp(phoneNumber);

        if (error == null) {
          Get.snackbar(
            "success".tr,
            "otp_sent_successfully".tr,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );

          Get.offAllNamed('/verify_otp');
        } else {
          Get.snackbar(
            "error".tr,
            error,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      } else {
        Get.snackbar(
          "error".tr,
          response.message ?? "login_failed".tr,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  void logout() async {
    Get.dialog(
      AlertDialog(
        title: Text('logout'.tr),
        content: Text('confirm_logout'.tr),
        actions: [
          TextButton(child: Text('cancel'.tr), onPressed: () => Get.back()),
          TextButton(
            child: Text('ok'.tr),
            onPressed: () async {
              await _authService.logout();
              await _box.erase();

              Get.back();
              Get.offAllNamed('/login');
            },
          ),
        ],
      ),
    );
  }

  Future<void> _saveStudentInfo(student) async {
    await _box.write('user_phone', student.phone ?? '');
    await _box.write('first_name', student.firstName ?? '');
    await _box.write('last_name', student.lastName ?? '');
    await _box.write(
      'full_name',
      '${student.firstName ?? ''} ${student.lastName ?? ''}'.trim(),
    );
  }

  @override
  void onClose() {
    identifierController.dispose();
    schoolIdController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
