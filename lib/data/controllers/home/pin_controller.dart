import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobilepenpal/data/services/home_service.dart';
import 'package:mobilepenpal/presentation/widgets/loading_status.dart';
import 'package:mobilepenpal/data/models/student/student.dart';
import 'package:mobilepenpal/data/controllers/home/home_controller.dart';
import 'package:mobilepenpal/data/controllers/settings/setting_controller.dart';

enum PinMode { create, verify, update }

class PinController extends GetxController {
  final HomeService homeService;

  PinController({HomeService? homeService})
    : homeService = homeService ?? HomeService();

  final RxBool _isConfirmStep = false.obs;
  final RxBool _loading = false.obs;
  final RxString _error = ''.obs;
  final RxString _pressedButton = ''.obs;
  final RxInt _updateStep = 0.obs;
  final RxBool _returnToSettings = false.obs;

  final TextEditingController pinController = TextEditingController();
  final TextEditingController confirmController = TextEditingController();

  final _secure = const FlutterSecureStorage();

  bool get isConfirmStep => _isConfirmStep.value;
  bool get loading => _loading.value;
  String get error => _error.value;
  String get pressedButton => _pressedButton.value;
  int get updateStep => _updateStep.value;
  bool get returnToSettings => _returnToSettings.value;
  RxString get errorRx => _error;

  set isConfirmStep(bool value) => _isConfirmStep.value = value;
  set loading(bool value) => _loading.value = value;
  set error(String value) => _error.value = value;
  set pressedButton(String value) => _pressedButton.value = value;
  set updateStep(int value) => _updateStep.value = value;
  set returnToSettings(bool value) => _returnToSettings.value = value;

  void initialize(PinMode mode, bool shouldReturnToSettings) {
    isConfirmStep = mode == PinMode.create ? false : false;
    updateStep = 0;
    error = '';
    returnToSettings = shouldReturnToSettings;
    pinController.clear();
    confirmController.clear();
  }

  void animatePressed(String id) {
    pressedButton = id;
    Future.delayed(const Duration(milliseconds: 140), () {
      pressedButton = '';
    });
  }

  void onNumberTap(int n, PinMode mode) {
    if (loading) return;

    final controller = getActiveController(mode);
    if (controller.text.length >= 4) return;

    animatePressed(n.toString());
    controller.text = controller.text + n.toString();
    controller.selection = TextSelection.fromPosition(
      TextPosition(offset: controller.text.length),
    );

    if (controller.text.length == 4) {
      Future.delayed(const Duration(milliseconds: 120), () {
        if (mode == PinMode.verify) {
          verifyPin();
        } else if (mode == PinMode.create) {
          if (!isConfirmStep) {
            isConfirmStep = true;
            error = '';
          } else {
            createPin();
          }
        } else if (mode == PinMode.update) {
          if (updateStep == 0) {
            verifyForUpdate();
          } else {
            if (!isConfirmStep) {
              isConfirmStep = true;
              error = '';
            } else {
              createPin(isUpdate: true);
            }
          }
        }
      });
    }
  }

  void onBackspace(PinMode mode) {
    if (loading) return;

    final controller = getActiveController(mode);
    animatePressed('backspace');

    if (controller.text.isEmpty) {
      if (isConfirmStep) {
        isConfirmStep = false;
        error = '';
      }
      return;
    }

    controller.text = controller.text.substring(0, controller.text.length - 1);
    controller.selection = TextSelection.fromPosition(
      TextPosition(offset: controller.text.length),
    );
  }

  void onClear(PinMode mode) {
    if (loading) return;
    final controller = getActiveController(mode);
    animatePressed('clear');
    controller.clear();
    error = '';
  }

  TextEditingController getActiveController(PinMode mode) {
    if (mode == PinMode.create) {
      return isConfirmStep ? confirmController : pinController;
    } else if (mode == PinMode.verify) {
      return pinController;
    } else {
      if (updateStep == 0) return pinController;
      return isConfirmStep ? confirmController : pinController;
    }
  }

  Future<void> verifyPin() async {
    error = '';

    final entered = pinController.text;
    final stored = await _secure.read(key: 'parent_pin');

    if (stored != null && stored == entered) {
      Get.key.currentState?.pop<bool>(true);
    } else {
      error = 'invalid_pin'.tr;
      pinController.clear();
    }
  }

  Future<void> verifyForUpdate() async {
    error = '';

    final entered = pinController.text;
    final stored = await _secure.read(key: 'parent_pin');

    if (stored != null && stored == entered) {
      updateStep = 1;
      isConfirmStep = false;
      pinController.clear();
      confirmController.clear();
    } else {
      error = 'invalid_pin'.tr;
      pinController.clear();
    }
  }

  Future<void> createPin({bool isUpdate = false}) async {
    final pin = pinController.text;
    final confirm = confirmController.text;

    if (pin.length != 4 || confirm.length != 4) {
      error = 'enter_digits'.tr;
      return;
    }
    if (pin != confirm) {
      error = 'pins_do_not_match'.tr;
      confirmController.clear();
      return;
    }

    loading = true;

    try {
      final res = await homeService.updateParentPin(pin);

      if (res.code == 200) {
        await _secure.write(key: 'parent_pin', value: pin);

        // Synchronize PIN code changes to local caches instantly
        final studentBox = GetStorage();
        final raw = studentBox.read('student');
        Student? updatedStudent;

        if (raw is Map) {
          final mergedJson = Map<String, dynamic>.from(raw);
          mergedJson['parent_pin'] = pin;
          updatedStudent = Student.fromJson(mergedJson);
          await studentBox.write('student', mergedJson);
        }

        if (Get.isRegistered<HomeController>()) {
          final dynamic homeController = Get.find<HomeController>();
          final currentStudent = homeController.student.value;
          if (currentStudent != null) {
            final updatedJson = currentStudent.toJson();
            updatedJson['parent_pin'] = pin;
            final syncedStudent = Student.fromJson(updatedJson);
            homeController.student.value = syncedStudent;
            await studentBox.write('student', updatedJson);
          } else if (updatedStudent != null) {
            homeController.student.value = updatedStudent;
          }
        }

        if (Get.isRegistered<SettingController>()) {
          final dynamic settingController = Get.find<SettingController>();
          final currentStudent = settingController.student.value;
          if (currentStudent != null) {
            final updatedJson = currentStudent.toJson();
            updatedJson['parent_pin'] = pin;
            settingController.student.value = Student.fromJson(updatedJson);
          } else if (updatedStudent != null) {
            settingController.student.value = updatedStudent;
          }
        }

        Get.offAll(
          () => LoadingStatus(
            isLoading: false,
            isSuccess: true,
            successText: isUpdate
                ? 'success_pin_updated'.tr
                : 'success_pin_created'.tr,
            buttonText: 'continue'.tr,
            onButtonPressed: () {
              GetStorage().write('skip_parent_pin_setup', false);

              if (returnToSettings) {
                Get.offNamed('/setting');
              } else {
                Get.offAllNamed('/home');
              }
            },
          ),
        );
      } else {
        error = res.message;
        Get.snackbar(
          'error'.tr,
          error,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      error = e.toString();
      Get.snackbar(
        'error'.tr,
        error,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      loading = false;
    }
  }

  String getTitle(PinMode mode, String? title, String? confirmTitle) {
    if (mode == PinMode.verify) {
      return title ?? 'enter_pin'.tr;
    } else if (mode == PinMode.create) {
      return isConfirmStep
          ? (confirmTitle ?? 'confirm_pin'.tr)
          : (title ?? 'create_pin'.tr);
    } else {
      if (updateStep == 0) {
        return 'enter_current_pin'.tr;
      } else {
        return isConfirmStep
            ? (confirmTitle ?? 'confirm_new_pin'.tr)
            : (title ?? 'create_new_pin'.tr);
      }
    }
  }

  @override
  void onClose() {
    pinController.dispose();
    confirmController.dispose();
    super.onClose();
  }
}
