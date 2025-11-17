import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mobilepenpal/core/theme/app_colors.dart';
import 'package:mobilepenpal/data/models/student/student.dart';
import 'package:mobilepenpal/data/services/auth_service.dart';

class SettingController extends GetxController {
  final AuthService authService = AuthService();
  final box = GetStorage();

  var currentMode = 'student'.obs;
  var student = Rxn<Student>();

  @override
  void onInit() {
    super.onInit();
    currentMode.value = box.read('mode') ?? 'student';
    student.value = Student.fromJson(box.read('student') ?? {});
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
