import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mobilepenpal/core/theme/app_colors.dart';
import 'package:mobilepenpal/data/controllers/home/pin_controller.dart';
import 'package:mobilepenpal/data/models/report/daily_summary.dart';
import 'package:mobilepenpal/data/models/report/monthly_summary.dart';
import 'package:mobilepenpal/data/models/report/weekly_summary.dart';
import 'package:mobilepenpal/data/models/student/student.dart';
import 'package:mobilepenpal/data/models/student/student_progress.dart';
import 'package:mobilepenpal/data/services/home_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobilepenpal/presentation/widgets/pin_entry_widget.dart';

enum SummaryView { daily, weekly }

class HomeController extends GetxController {
  final HomeService _homeService = HomeService();
  final _box = GetStorage();
  final _secure = const FlutterSecureStorage();

  var isLoading = false.obs;
  var isProfileLoading = false.obs;
  var student = Rxn<Student>();
  var currentMode = ''.obs;
  var studentProgress = <StudentProgress>[].obs;

  var summaryView = SummaryView.daily.obs;

  var isWeeklyLoading = false.obs;
  var weeklySummary = Rxn<WeeklySummary>();

  var isSummaryLoading = false.obs;
  var dailySummary = Rxn<DailySummary>();

  var isMonthlyLoading = false.obs;
  var monthlySummary = Rxn<MonthlySummary>();
  var selectedMonth = ''.obs;

  String get avatarUrl => student.value?.avatar ?? '';

  @override
  void onInit() {
    super.onInit();
    loadInitialData();
  }

  void setCurrentMode(String mode) {
    _box.write('mode', mode);
    currentMode.value = mode;
  }

  void loadInitialData() {
    setCurrentMode(_box.read('mode') ?? 'student');
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

  Future<void> fetchDailySummary({String? date}) async {
    if (isSummaryLoading.value) return;

    isSummaryLoading.value = true;
    try {
      final res = await _homeService.getDailySummary(date: date);

      if (res.code == 200 && res.data != null) {
        dailySummary.value = res.data!;
      } else {
        Get.snackbar(
          'Error',
          res.message,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isSummaryLoading.value = false;
    }
  }

  Future<void> fetchWeeklySummary({String? fromDate, String? toDate}) async {
    if (isWeeklyLoading.value) return;

    isWeeklyLoading.value = true;
    try {
      final res = await _homeService.getWeeklySummary(
        fromDate: fromDate,
        toDate: toDate,
      );
      if (res.code == 200 && res.data != null) {
        weeklySummary.value = res.data!;
      } else {
        Get.snackbar(
          'Error',
          res.message,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } finally {
      isWeeklyLoading.value = false;
    }
  }

  Future<void> fetchMonthlySummary({String? month}) async {
    if (isMonthlyLoading.value) return;

    isMonthlyLoading.value = true;
    try {
      final m = month ?? selectedMonth.value;
      final res = await _homeService.getMonthlySummary(
        month: (m.isEmpty ? null : m),
      );

      if (res.code == 200 && res.data != null) {
        monthlySummary.value = res.data!;
        if (res.data!.month.isNotEmpty) {
          selectedMonth.value = res.data!.month;
        }
      } else {
        Get.snackbar(
          'Error',
          res.message,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isMonthlyLoading.value = false;
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
    newMode = newMode.toLowerCase();

    if (newMode == currentMode.value) {
      return;
    }

    if (newMode == 'parent') {
      final skip = _box.read('skip_parent_pin_setup') ?? false;

      if (skip == true) {
        setCurrentMode('parent');
        return;
      }

      final storedPin = await _secure.read(key: 'parent_pin');
      final apiPin = student.value?.parentPin;

      if ((storedPin != null && storedPin.isNotEmpty) ||
          (apiPin != null && apiPin.isNotEmpty)) {
        if ((storedPin == null || storedPin.isEmpty) &&
            apiPin != null &&
            apiPin.isNotEmpty) {
          await _secure.write(key: 'parent_pin', value: apiPin);
        }

        final ok = await Get.to<bool>(
          () => PinWidget(mode: PinMode.verify, title: 'unlock_parent_mode'.tr),
        );

        if (ok == true) {
          await Future.delayed(const Duration(milliseconds: 200));
          setCurrentMode('parent');
        }

        return;
      }

      final create = await _showCreatePinPrompt();

      if (create == null) {
        return;
      }

      if (create == true) {
        final created = await Get.to<bool>(
          () => const PinWidget(mode: PinMode.create),
        );

        if (created == true) {
          setCurrentMode('parent');
        }
      } else {
        await _box.write('skip_parent_pin_setup', true);
        setCurrentMode('parent');
      }
    } else {
      setCurrentMode('student');
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
            onPressed: () {
              Navigator.of(Get.overlayContext!).pop(false);
            },
            child: Text('no'.tr),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(Get.overlayContext!).pop(true);
            },
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

  Future<void> refreshHome() async {
    isLoading.value = true;
    try {
      await fetchStudentProfile();

      if (currentMode.value == 'parent') {
        if (summaryView.value == SummaryView.daily) {
          await fetchDailySummary();
        } else {
          await fetchWeeklySummary();
        }
      }
    } finally {
      isLoading.value = false;
    }
  }

  String get fullName => student.value != null
      ? '${student.value!.firstName} ${student.value!.lastName}'
      : 'Student';

  String get parentName => student.value?.parentFirstName != null
      ? '${student.value!.parentFirstName} ${student.value?.parentLastName ?? ""}'
            .trim()
      : 'Parent';
}
