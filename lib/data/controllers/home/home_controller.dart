import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mobilepenpal/data/models/student/student.dart';
import 'package:mobilepenpal/data/services/home_service.dart';

class HomeController extends GetxController {
  final HomeService _homeService = HomeService();
  final _box = GetStorage();

  var isLoading = false.obs;
  var isProfileLoading = false.obs;
  var userName = ''.obs;
  var userAvatar = ''.obs;
  var student = Rxn<Student>();
  var currentMode = 'student'.obs;

  var courses = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadInitialData();
  }

  void setCurrentMode(String mode) {
    currentMode.value = mode;
  }

  void loadInitialData() {
    loadUserDataFromStorage();
    fetchStudentProfile();
    loadCourses();
  }

  void loadUserDataFromStorage() {
    final studentData = _box.read('student');
    if (studentData != null && studentData is Map<String, dynamic>) {
      student.value = Student.fromJson(studentData);
      userName.value =
          '${student.value?.firstName ?? ''} ${student.value?.lastName ?? ''}'
              .trim();
    } else {
      userName.value = _box.read('full_name') ?? 'Student';
    }
    userAvatar.value = _box.read('user_avatar') ?? '';
  }

  Future<void> fetchStudentProfile() async {
    if (isProfileLoading.value) return;

    isProfileLoading.value = true;

    try {
      final response = await _homeService.getStudentProfile();

      if (response.code == 200 && response.data != null) {
        student.value = response.data;
        userName.value =
            '${response.data?.firstName ?? ''} ${response.data?.lastName ?? ''}'
                .trim();

        await _saveStudentToStorage(response.data!);
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

  Future<void> _saveStudentToStorage(Student student) async {
    await _box.write('student', student.toJson());
    await _box.write(
      'full_name',
      '${student.firstName} ${student.lastName}'.trim(),
    );
    await _box.write('user_phone', student.phone);
  }

  void loadCourses() {
    courses.assignAll([
      {
        'title': 'ផ្នែកអក្សរ',
        'subtitle': 'រៀនសរសេរអក្សរខ្មែរ',
        'progress': 9,
        'total': 20,
        'color': Colors.pink,
        'icon': '📝',
      },
      {
        'title': 'ផ្នែកសូរ',
        'subtitle': 'ការបញ្ចេញសូរ និងអានសៀវភៅ',
        'progress': 9,
        'total': 20,
        'color': Colors.blue,
        'icon': '🔊',
      },
    ]);
  }

  double calculateProgress(int progress, int total) {
    if (total == 0) return 0;
    return progress / total;
  }

  Future<void> refreshCourses() async {
    isLoading.value = true;

    await Future.wait([
      fetchStudentProfile(),
      Future.delayed(const Duration(seconds: 1)),
    ]);

    loadCourses();
    isLoading.value = false;
  }

  String get fullName => student.value != null
      ? '${student.value!.firstName} ${student.value!.lastName}'
      : userName.value;
  String get studentAddress => student.value?.address ?? 'No address';
  String get parentName => student.value?.parentFirstName != null
      ? '${student.value!.parentFirstName} ${student.value?.parentLastName ?? ""}'
            .trim()
      : 'Parent';
}
