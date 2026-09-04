import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mobilepenpal/core/theme/app_colors.dart';
import 'package:mobilepenpal/data/controllers/home/pin_controller.dart';
import 'package:mobilepenpal/data/models/classroom/classroom.dart';
import 'package:mobilepenpal/data/models/report/daily_summary.dart';
import 'package:mobilepenpal/data/models/report/monthly_summary.dart';
import 'package:mobilepenpal/data/models/report/weekly_summary.dart';
import 'package:mobilepenpal/data/models/student/student.dart';
import 'package:mobilepenpal/data/models/student/student_progress.dart';
import 'package:mobilepenpal/data/services/home_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobilepenpal/presentation/widgets/app_snackbar.dart';
import 'package:mobilepenpal/presentation/widgets/confirm_modal.dart';
import 'package:mobilepenpal/presentation/widgets/home/pin_entry_widget.dart';
import 'package:mobilepenpal/data/controllers/shop/shop_controller.dart';
import 'package:mobilepenpal/data/services/mini_game_service.dart';
import 'package:mobilepenpal/data/controllers/world/heart_controller.dart';
import 'dart:developer' as dev;

enum SummaryView { daily, weekly }

class HomeController extends GetxController {
  final HomeService _homeService = HomeService();
  final _box = GetStorage();
  final _secure = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  var isLoading = false.obs;
  var isProfileLoading = false.obs;
  var isClassroomLoading = false.obs;
  var isJoiningClassroom = false.obs;
  var currentClassroom = Rxn<Classroom>();
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

  // Subscription settings (dynamic from backend)
  var subscriptionPrice = 5.0.obs;
  var subscriptionDiscount = 50.obs;
  var subscriptionBillingCycle = 'month'.obs;
  var contactPhone = '+855 935 248 60'.obs;
  var contactEmail = 'info@khmerpenpal.com'.obs;

  // Feature lock settings (dynamic from backend)
  var featureLocksEnabled = true.obs;
  var miniGameFreeDailyLimit = 3.obs;
  var aiWritingFreeCharLimit = 80.obs;
  var learningFreeStageLimit = 10.obs;

  String get avatarUrl => student.value?.avatar ?? '';

  bool _isWorldCompleted(bool Function(StudentProgress) testFunc) {
    return studentProgress
        .where(testFunc)
        .any((progress) => progress.isCompleted || progress.completed);
  }

  bool get isConsonantsWorldCompleted => _isWorldCompleted(_isConsonantsWorld);
  bool get isDependentVowelsWorldCompleted =>
      _isWorldCompleted(_isDependentVowelsWorld);
  bool get isIndependentVowelsWorldCompleted =>
      _isWorldCompleted(_isIndependentVowelsWorld);
  bool get isDigitsWorldCompleted => _isWorldCompleted(_isDigitsWorld);

  ShopAvatar? get currentShopAvatar {
    if (Get.isRegistered<ShopController>()) {
      final shop = Get.find<ShopController>();
      return shop.currentAvatar;
    }
    return null;
  }

  bool get hasSchool {
    final id = student.value?.schoolId;
    if (id == null) return false;
    return int.tryParse(id.toString()) != null && int.parse(id.toString()) > 0;
  }

  bool get hasSubscription => student.value?.hasSubscription ?? false;

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

    final cached = _box.read('student');
    if (cached is Map<String, dynamic>) {
      try {
        student.value = Student.fromJson(Map<String, dynamic>.from(cached));
        _initHeartController();
      } catch (_) {}
    }

    fetchStudentProfile();
    fetchSubscriptionSettings();
    fetchFeatureLockSettings();
    fetchQuestionTemplatesInBackground();
  }

  void _initHeartController() {
    final st = student.value;
    if (st != null) {
      if (!Get.isRegistered<HeartController>()) {
        Get.put(HeartController());
      }
      HeartController.to.initForStudent(
        studentId: st.id,
        hasSubscription: st.hasSubscription,
      );
    }
  }

  Future<void> fetchQuestionTemplatesInBackground() async {
    try {
      final service = MiniGameService();
      final response = await service.getQuestionTemplates();
      if (response.code == 200 &&
          response.data != null &&
          response.data!.isNotEmpty) {
        final templatesJson = response.data!.map((t) => t.toJson()).toList();
        await _box.write('cached_question_templates', templatesJson);
        dev.log(
          'HomeController: Background sync completed. Cached ${response.data!.length} templates.',
          name: 'HomeController',
        );
      }
    } catch (e) {
      dev.log(
        'HomeController: Failed to fetch question templates in background: $e',
        name: 'HomeController',
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
        await _box.write('student', student.value!.toJson());
        studentProgress.assignAll(response.data!.progress);

        _initHeartController();

        await _syncParentPin(student.value!);

        if (!hasSchool) {
          currentClassroom.value = null;
        } else {
          if (currentMode.value == 'parent' && currentClassroom.value == null) {
            await fetchCurrentClassroom();
          }
        }
      } else {
        AppSnackbar.show(
          title: 'error'.tr,
          response.message,
          backgroundColor: Colors.red,
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
        AppSnackbar.show(
          title: 'error'.tr,
          res.message,
          backgroundColor: Colors.red,
        );
      }
    } catch (e) {
      AppSnackbar.show(
        title: 'error'.tr,
        e.toString(),
        backgroundColor: Colors.red,
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
        AppSnackbar.show(
          title: 'error'.tr,
          res.message,
          backgroundColor: Colors.red,
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
        AppSnackbar.show(
          title: 'error'.tr,
          res.message,
          backgroundColor: Colors.red,
        );
      }
    } catch (e) {
      AppSnackbar.show(
        title: 'error'.tr,
        e.toString(),
        backgroundColor: Colors.red,
      );
    } finally {
      isMonthlyLoading.value = false;
    }
  }

  Future<void> fetchCurrentClassroom({bool force = false}) async {
    if (!hasSchool) {
      currentClassroom.value = null;
      return;
    }
    if (isClassroomLoading.value) return;

    isClassroomLoading.value = true;
    try {
      final res = await _homeService.getClassrooms();

      if (res.code == 200 && res.data != null) {
        final list = res.data!;
        currentClassroom.value = list.isNotEmpty ? list.first : null;
      }
    } catch (e) {
      AppSnackbar.show(
        title: 'error'.tr,
        e.toString(),
        backgroundColor: Colors.red,
      );
    } finally {
      isClassroomLoading.value = false;
    }
  }

  Future<bool> joinClassroomByCode(String code) async {
    if (!hasSchool) {
      AppSnackbar.show(
        title: 'error'.tr,
        'Your account is not linked to a school. Please contact your school admin.',
        backgroundColor: Colors.red,
      );
      return false;
    }
    if (isJoiningClassroom.value) return false;

    final joinCode = code.trim();
    if (joinCode.isEmpty) {
      AppSnackbar.show(
        title: 'error'.tr,
        'enter_code'.tr,
        backgroundColor: Colors.red,
      );
      return false;
    }

    isJoiningClassroom.value = true;
    try {
      final res = await _homeService.joinClassroomByCode(joinCode);

      if (res.code == 200) {
        if (res.data != null) {
          currentClassroom.value = res.data!;
        } else {
          await fetchCurrentClassroom();
        }
        AppSnackbar.show(
          title: 'success'.tr,
          'joined'.tr,
          backgroundColor: const Color(0xFF16A34A),
        );
        return true;
      }

      AppSnackbar.show(
        title: 'error'.tr,
        res.message,
        backgroundColor: Colors.red,
      );
      return false;
    } catch (e) {
      AppSnackbar.show(
        title: 'error'.tr,
        e.toString(),
        backgroundColor: Colors.red,
      );
      return false;
    } finally {
      isJoiningClassroom.value = false;
    }
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

        if (hasSchool && currentClassroom.value == null) {
          await fetchCurrentClassroom();
        }
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

          // ✅ Only fetch classroom if needed
          if (hasSchool && currentClassroom.value == null) {
            await fetchCurrentClassroom();
          }
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

          if (hasSchool && currentClassroom.value == null) {
            await fetchCurrentClassroom();
          }
        }
      } else {
        await _box.write('skip_parent_pin_setup', true);
        setCurrentMode('parent');

        if (hasSchool && currentClassroom.value == null) {
          await fetchCurrentClassroom();
        }
      }
    } else {
      setCurrentMode('student');
    }
  }

  Future<bool?> _showCreatePinPrompt() {
    return Get.dialog<bool>(
      ConfirmModal<bool>(
        icon: const Icon(
          Icons.lock_rounded,
          color: AppColors.primary,
          size: 28,
        ),
        title: Text('set_pin'.tr),
        message: Text('set_parent_pin_prompt'.tr),
        secondaryText: 'no'.tr,
        primaryText: 'yes'.tr,
        primaryColor: AppColors.primary,
        primaryTextColor: Colors.white,
        secondaryTextColor: const Color(0xFF111827),
        showCloseButton: false,

        primaryResult: true,
        secondaryResult: false,
      ),
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.55),
    );
  }

  Future<void> _syncParentPin(Student student) async {
    if (student.parentPin != null && student.parentPin!.isNotEmpty) {
      await _secure.write(key: 'parent_pin', value: student.parentPin!);
    } else {
      await _secure.delete(key: 'parent_pin');
    }
  }

  Future<void> refreshHome() async {
    isLoading.value = true;
    try {
      await fetchStudentProfile();
      await fetchSubscriptionSettings();

      if (currentMode.value == 'parent') {
        if (hasSchool) {
          await fetchCurrentClassroom(force: true);
        } else {
          currentClassroom.value = null;
        }

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

  Future<void> fetchSubscriptionSettings() async {
    try {
      final res = await _homeService.getSubscriptionSettings();
      if (res.code == 200 && res.data != null) {
        final s = res.data!;
        subscriptionPrice.value = (s['price'] is num)
            ? (s['price'] as num).toDouble()
            : double.tryParse(s['price']?.toString() ?? '') ?? 5.0;
        subscriptionDiscount.value = (s['discount'] is num)
            ? (s['discount'] as num).toInt()
            : int.tryParse(s['discount']?.toString() ?? '') ?? 50;
        subscriptionBillingCycle.value =
            s['billing_cycle']?.toString() ?? 'month';
        contactPhone.value =
            s['contact_phone']?.toString() ?? '+855 935 248 60';
        contactEmail.value =
            s['contact_email']?.toString() ?? 'info@khmerpenpal.com';
      }
    } catch (_) {
      // Keep defaults on error
    }
  }

  Future<void> fetchFeatureLockSettings() async {
    try {
      final res = await _homeService.getFeatureLockSettings();
      if (res.code == 200 && res.data != null) {
        final s = res.data!;
        featureLocksEnabled.value = s['enabled'] == true;
        miniGameFreeDailyLimit.value = (s['mini_game_free_daily_limit'] is num)
            ? (s['mini_game_free_daily_limit'] as num).toInt()
            : int.tryParse(s['mini_game_free_daily_limit']?.toString() ?? '') ??
                  1;
        aiWritingFreeCharLimit.value = (s['ai_writing_free_char_limit'] is num)
            ? (s['ai_writing_free_char_limit'] as num).toInt()
            : int.tryParse(s['ai_writing_free_char_limit']?.toString() ?? '') ??
                  80;
        learningFreeStageLimit.value = (s['learning_free_stage_limit'] is num)
            ? (s['learning_free_stage_limit'] as num).toInt()
            : int.tryParse(s['learning_free_stage_limit']?.toString() ?? '') ??
                  10;
      }
    } catch (_) {
      // Keep defaults on error
    }
  }

  String get fullName => student.value != null
      ? '${student.value!.firstName} ${student.value!.lastName}'
      : 'Student';

  String get parentName => student.value?.parentFirstName != null
      ? '${student.value!.parentFirstName} ${student.value?.parentLastName ?? ""}'
            .trim()
      : 'Parent';

  bool _isConsonantsWorld(StudentProgress progress) {
    final name = progress.nameEn.trim().toLowerCase();
    final desc = progress.descriptionEn.trim().toLowerCase();
    return name == 'consonants' ||
        name.contains('consonant') ||
        desc.contains('consonant');
  }

  bool _isDependentVowelsWorld(StudentProgress progress) {
    final name = progress.nameEn.trim().toLowerCase();
    final desc = progress.descriptionEn.trim().toLowerCase();
    return name.contains('dependent vowel') || desc.contains('dependent vowel');
  }

  bool _isIndependentVowelsWorld(StudentProgress progress) {
    final name = progress.nameEn.trim().toLowerCase();
    final desc = progress.descriptionEn.trim().toLowerCase();
    return name.contains('independent vowel') ||
        desc.contains('independent vowel');
  }

  bool _isDigitsWorld(StudentProgress progress) {
    final name = progress.nameEn.trim().toLowerCase();
    final desc = progress.descriptionEn.trim().toLowerCase();
    return name.contains('digit') ||
        name.contains('number') ||
        desc.contains('digit');
  }
}
