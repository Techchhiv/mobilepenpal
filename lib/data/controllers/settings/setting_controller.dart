import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';

import 'package:mobilepenpal/core/theme/app_colors.dart';
import 'package:mobilepenpal/data/models/student/student.dart';
import 'package:mobilepenpal/data/services/auth_service.dart';
import 'package:mobilepenpal/data/services/home_service.dart';
import 'package:mobilepenpal/presentation/routes/app_routes.dart';
import 'package:mobilepenpal/presentation/widgets/app_snackbar.dart';
import 'package:mobilepenpal/presentation/widgets/confirm_modal.dart';

class SettingController extends GetxController {
  final AuthService authService = AuthService();
  final HomeService homeService = HomeService();
  final ImagePicker imagePicker = ImagePicker();
  final box = GetStorage();

  var currentMode = 'student'.obs;
  var student = Rxn<Student>();
  var isLoading = false.obs;

  var isParentPinRequired = true.obs;

  String get parentPin => student.value?.parentPin ?? '';

  @override
  void onInit() {
    super.onInit();
    currentMode.value = box.read('mode') ?? 'student';
    student.value = Student.fromJson(box.read('student') ?? {});

    final skip = box.read('skip_parent_pin_setup') ?? false;
    isParentPinRequired.value = !skip;
  }

  String get avatarUrl => student.value?.avatar ?? '';

  void setParentPinRequired(bool value) {
    isParentPinRequired.value = value;
    box.write('skip_parent_pin_setup', !value);
  }

  Future<void> pickAndUploadImage() async {
    try {
      final XFile? image = await imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image == null) return;

      final fileSize = await image.length();
      const maxSize = 2 * 1024 * 1024;

      if (fileSize > maxSize) {
        AppSnackbar.show(
          'image_too_large'.tr,
          title: 'warning'.tr,
          backgroundColor: Colors.orange,
        );
        return;
      }

      isLoading.value = true;

      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);

      final ext = (image.name.split('.').last).toLowerCase();
      final mime = (ext == 'png') ? 'image/png' : 'image/jpeg';

      final imageData = 'data:$mime;base64,$base64Image';

      final response = await homeService.uploadAvatar(imageData);

      isLoading.value = false;

      if (response.code == 200 && response.data != null) {
        student.value = response.data;
        box.write('student', student.value?.toJson());

        AppSnackbar.show(
          'Profile picture updated successfully'.tr,
          title: 'success'.tr,
          backgroundColor: Colors.green,
        );
      } else {
        AppSnackbar.show(
          response.message,
          title: 'error'.tr,
          backgroundColor: Colors.red,
        );
      }
    } catch (e) {
      isLoading.value = false;
      AppSnackbar.show(
        'Failed to pick image: $e',
        title: 'error'.tr,
        backgroundColor: Colors.red,
      );
    }
  }

  void logout() {
    showConfirmModal(
      modal: ConfirmModal(
        icon: const Icon(Icons.logout_rounded, color: Colors.red, size: 28),
        title: Text('logout'.tr),
        message: Text('are_you_sure_you_want_to_logout'.tr),
        primaryText: 'confirmed'.tr,
        secondaryText: 'cancel'.tr,

        primaryColor: Colors.red,
        primaryTextColor: Colors.white,

        secondaryTextColor: const Color(0xFF111827),
        secondaryBorderColor: const Color(0xFFE5E7EB),

        onPrimary: () async {
          Get.back();
          await authService.logout();
          box.remove("student");
          await GetStorage().write('is_logged_in', false);
          Get.offAllNamed(AppRoutes.login);
        },
      ),
    );
  }

  String get fullName => student.value != null
      ? '${student.value!.firstName} ${student.value!.lastName}'
      : 'Student';

  String get parentName => student.value?.parentFirstName != null
      ? '${student.value!.parentFirstName} ${student.value?.parentLastName ?? ""}'
            .trim()
      : 'Parent';
}
