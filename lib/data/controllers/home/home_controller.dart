import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mobilepenpal/core/theme/app_colors.dart';
import 'package:mobilepenpal/data/models/student/student.dart';
import 'package:mobilepenpal/data/models/student/student_progress.dart';
import 'package:mobilepenpal/data/services/home_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobilepenpal/presentation/widgets/pin_entry_widget.dart';

class HomeController extends GetxController {
  final HomeService _homeService = HomeService();
  final _box = GetStorage();
  final _secure = const FlutterSecureStorage();

  var isLoading = false.obs;
  var isProfileLoading = false.obs;
  var student = Rxn<Student>();
  var currentMode = 'student'.obs;
  var studentProgress = <StudentProgress>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadInitialData();
  }

  void setCurrentMode(String mode) {
    currentMode.value = mode;
  }

  void loadInitialData() {
    loadCachedData();
    fetchStudentProfile();
  }

  void loadCachedData() {
    final studentData = _box.read('student');
    if (studentData != null && studentData is Map<String, dynamic>) {
      student.value = Student.fromJson(studentData);
    }

    final progressData = _box.read('student_progress');
    if (progressData != null && progressData is List<dynamic>) {
      studentProgress.assignAll(
        progressData.map((data) => StudentProgress.fromJson(data)).toList(),
      );
    }
  }

  Future<void> fetchStudentProfile() async {
    if (isProfileLoading.value) return;

    isProfileLoading.value = true;
    try {
      final response = await _homeService.getStudentProfile();
      if (response.code == 200 && response.data != null) {
        student.value = response.data!.profile;
        studentProgress.assignAll(response.data!.progress);

        await _syncParentPin(student.value!);

        await _saveToStorage(
          student: response.data!.profile,
          progress: response.data!.progress,
        );
      } else {
        Get.snackbar(
          'Error',
          response.message,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } finally {
      isProfileLoading.value = false;
    }
  }

  Future<void> _saveToStorage({
    required Student student,
    required List<StudentProgress> progress,
  }) async {
    await _box.write('student', student.toJson());

    final progressList = progress.map((p) => p.toJson()).toList();
    await _box.write('student_progress', progressList);
  }

  Future<void> requestModeChange(String newMode) async {
    if (newMode == currentMode.value) return;

    if (newMode == 'parent') {
      final skip = _box.read('skip_parent_pin_setup') ?? false;

      final storedPin = await _secure.read(key: 'parent_pin');
      final apiPin = student.value?.parentPin;

      if ((storedPin != null && storedPin.isNotEmpty) ||
          (apiPin != null && apiPin.isNotEmpty)) {
        if (storedPin == null && apiPin != null && apiPin.isNotEmpty) {
          await _secure.write(key: 'parent_pin', value: apiPin);
        }

        final ok = await Get.to<bool>(
          () => PinWidget(
            mode: PinMode.verify,
            title: 'unlock_parent_mode'.tr,
            autoCloseOnSuccess: false,
          ),
        );

        if (ok == true) {
          currentMode.value = 'parent';
        }
        return;
      }

      if (skip) {
        currentMode.value = 'parent';
        return;
      }

      final create = await _showCreatePinPrompt();
      if (create == true) {
        final created = await Get.to<bool>(
          () => const PinWidget(mode: PinMode.create),
        );
        if (created == true) {
          currentMode.value = 'parent';
        }
      } else if (create == false) {
        _box.write('skip_parent_pin_setup', true);
        currentMode.value = 'parent';
      }
    } else {
      currentMode.value = 'student';
    }
  }

  Future<bool?> _showCreatePinPrompt() {
    return Get.dialog<bool>(
      AlertDialog(
        title: Text('set_pin'.tr),
        backgroundColor: AppColors.textWhiteOff,
        content: Text("set_parent_pin_prompt".tr),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('no'.tr),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            child: Text('yes'.tr),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  Future<void> _syncParentPin(Student student) async {
    if (student.parentPin != null && student.parentPin!.isNotEmpty) {
      await _secure.write(key: 'parent_pin', value: student.parentPin!);
    }
  }

  Future<void> refreshCourses() async {
    isLoading.value = true;
    await fetchStudentProfile();
    isLoading.value = false;
  }

  String get fullName => student.value != null
      ? '${student.value!.firstName} ${student.value!.lastName}'
      : 'Student';

  String get parentName => student.value?.parentFirstName != null
      ? '${student.value!.parentFirstName} ${student.value?.parentLastName ?? ""}'
            .trim()
      : 'Parent';
}
