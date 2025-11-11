import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mobilepenpal/data/models/student/student.dart';
import 'package:mobilepenpal/data/models/student/student_progress.dart';
import 'package:mobilepenpal/data/services/home_service.dart';

class HomeController extends GetxController {
  final HomeService _homeService = HomeService();
  final _box = GetStorage();

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

        await _saveToStorage(
          student: response.data!.profile,
          progress: response.data!.progress,
        );
      } else {
        Get.snackbar(
          'error'.tr,
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

  Future<void> refreshCourses() async {
    isLoading.value = true;
    await fetchStudentProfile();
    isLoading.value = false;
  }

  String get fullName => student.value != null
      ? '${student.value!.firstName} ${student.value!.lastName}'
      : 'Student';

  String get parentName => student.value?.parentFirstName != null
      ? '${student.value!.parentFirstName} ${student.value?.parentLastName ?? ""}'.trim()
      : 'Parent';
}