import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';

import 'package:mobilepenpal/core/theme/app_colors.dart';
import 'package:mobilepenpal/data/models/student/student.dart';
import 'package:mobilepenpal/data/services/auth_service.dart';
import 'package:mobilepenpal/data/services/home_service.dart';

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

      if (image != null) {
        final fileSize = await image.length();
        const maxSize = 2 * 1024 * 1024;

        if (fileSize > maxSize) {
          Get.snackbar(
            'warning'.tr,
            'image_too_large'.tr,
            backgroundColor: Colors.orange,
            colorText: Colors.white,
            duration: Duration(seconds: 3),
          );
          return;
        }

        isLoading.value = true;

        final bytes = await image.readAsBytes();
        final String base64Image = base64Encode(bytes);
        final String imageData = 'data:image/jpeg;base64,$base64Image';

        final response = await homeService.uploadAvatar(imageData);

        isLoading.value = false;

        if (response.code == 200 && response.data != null) {
          student.value = response.data;
          box.write('student', student.value?.toJson());

          Get.snackbar(
            'success'.tr,
            'Profile picture updated successfully'.tr,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        } else {
          Get.snackbar(
            'Error'.tr,
            response.message,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      }
    } catch (e) {
      isLoading.value = false;
      Get.snackbar(
        'Error'.tr,
        'Failed to pick image: $e'.tr,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void logout() {
    Get.dialog(
      AlertDialog(
        backgroundColor: Colors.white,
        title: Text('logout'.tr),
        content: Text('are_you_sure_you_want_to_logout'.tr),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Color(0xFFF5F5F5),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              padding: EdgeInsets.symmetric(horizontal: 12),
            ),
            child: Text('cancel'.tr),
            onPressed: () => Get.back(),
          ),
          SizedBox(width: 4),
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              padding: EdgeInsets.symmetric(horizontal: 12),
            ),
            child: Text('confirmed'.tr),
            onPressed: () async {
              await authService.logout();
              box.remove("student");
              Get.offAllNamed('/login');
            },
          ),
        ],
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
