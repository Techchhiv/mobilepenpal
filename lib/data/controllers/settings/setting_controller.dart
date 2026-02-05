import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobilepenpal/core/localization/locale_controller.dart';

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

  final localeController = Get.find<LocaleController>();

  var currentMode = 'student'.obs;
  var student = Rxn<Student>();
  var isLoading = false.obs;

  var isParentPinRequired = true.obs;

  String get parentPin => student.value?.parentPin ?? '';

  @override
  void onInit() {
    super.onInit();

    currentMode.value = box.read('mode') ?? 'student';

    final raw = box.read('student');
    if (raw is Map) {
      student.value = Student.fromJson(Map<String, dynamic>.from(raw));
    } else if (raw is String && raw.isNotEmpty) {
      student.value = Student.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } else {
      student.value = null;
    }

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
        final updated = response.data!;
        final prev = student.value;

        if (prev != null) {
          final mergedJson = Map<String, dynamic>.from(prev.toJson());

          final updatedJson = updated.toJson();
          updatedJson.forEach((k, v) {
            if (v != null) mergedJson[k] = v;
          });

          final merged = Student.fromJson(mergedJson);

          student.value = merged;
          box.write('student', merged.toJson());
        } else {
          student.value = updated;
          box.write('student', updated.toJson());
        }

        AppSnackbar.show(
          'profile_updated_successfully'.tr,
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
