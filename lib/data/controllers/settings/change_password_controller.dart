import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobilepenpal/data/services/home_service.dart';

class ChangePasswordController extends GetxController {
  final HomeService _homeService = HomeService();
  var isLoading = false.obs;
  var currentPasswordError = ''.obs;
  var newPasswordError = ''.obs;
  var confirmPasswordError = ''.obs;

  var isCurrentPasswordVisible = false.obs;
  var isNewPasswordVisible = false.obs;
  var isConfirmPasswordVisible = false.obs;

  void toggleCurrentPasswordVisibility() {
    isCurrentPasswordVisible.value = !isCurrentPasswordVisible.value;
  }

  void toggleNewPasswordVisibility() {
    isNewPasswordVisible.value = !isNewPasswordVisible.value;
  }

  void toggleConfirmPasswordVisibility() {
    isConfirmPasswordVisible.value = !isConfirmPasswordVisible.value;
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    currentPasswordError.value = '';
    newPasswordError.value = '';
    confirmPasswordError.value = '';

    if (currentPassword.isEmpty) {
      currentPasswordError.value = 'current_password_required'.tr;
      return;
    }

    if (newPassword.isEmpty) {
      newPasswordError.value = 'new_password_required'.tr;
      return;
    }

    if (newPassword.length < 6) {
      newPasswordError.value = 'password_min_6_cha'.tr;
      return;
    }

    if (confirmPassword.isEmpty) {
      confirmPasswordError.value = 'confirm_password_required'.tr;
      return;
    }

    if (newPassword != confirmPassword) {
      confirmPasswordError.value = 'passwords_do_not_match'.tr;
      return;
    }

    try {
      isLoading.value = true;

      final response = await _homeService.updatePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );

      if (response.code == 200) {
        Get.back();
        Get.snackbar(
          'success'.tr,
          'password_updated_successfully'.tr,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        final errorMessage = response.message;

        if (errorMessage.toLowerCase().contains('current password')) {
          currentPasswordError.value = errorMessage;
        } else {
          Get.snackbar(
            'error'.tr,
            errorMessage,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      }
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        'network_error'.tr,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
