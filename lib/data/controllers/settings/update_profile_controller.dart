import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mobilepenpal/data/controllers/home/home_controller.dart';
import 'package:mobilepenpal/data/controllers/settings/setting_controller.dart';
import 'package:mobilepenpal/data/models/student/student.dart';
import 'package:mobilepenpal/data/services/home_service.dart';

class UpdateProfileController extends GetxController {
  final HomeService _homeService = HomeService();
  final box = GetStorage();

  final Rx<Student?> student = Rx<Student?>(null);
  final RxBool isLoading = false.obs;
  final RxBool isInitialized = false.obs;
  final RxString errorMessage = ''.obs;
  final RxBool showLoadingStatus = false.obs;

  final firstName = ''.obs;
  final lastName = ''.obs;
  final nickname = ''.obs;
  final age = ''.obs;
  final gender = ''.obs;
  final dateOfBirth = ''.obs;
  final parentFirstName = ''.obs;
  final parentLastName = ''.obs;
  final address = ''.obs;

  final ageTextController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    _loadCurrentProfile();
  }

  void _loadCurrentProfile() {
    try {
      final studentData = box.read('student');
      if (studentData != null) {
        student.value = Student.fromJson(studentData);
        _populateFormFields();
        isInitialized.value = true;
      } else {
        errorMessage.value = 'failed_to_load_profile'.tr;
      }
    } catch (e) {
      errorMessage.value = 'failed_to_load_profile'.tr;
    }
  }

  void _populateFormFields() {
    final currentStudent = student.value;
    if (currentStudent == null) return;

    firstName.value = currentStudent.firstName;
    lastName.value = currentStudent.lastName ?? '';
    nickname.value = currentStudent.nickname ?? '';
    age.value = currentStudent.age?.toString() ?? '';
    ageTextController.text = age.value;
    gender.value = currentStudent.gender ?? '';

    dateOfBirth.value = _formatDate(currentStudent.dateOfBirth ?? '');

    parentFirstName.value = currentStudent.parentFirstName ?? '';
    parentLastName.value = currentStudent.parentLastName ?? '';
    address.value = currentStudent.address ?? '';
  }

  String _formatDate(String dateString) {
    if (dateString.isEmpty) return '';

    try {
      final DateTime? parsedDate = DateTime.tryParse(dateString);
      if (parsedDate != null) {
        return "${parsedDate.year}-${parsedDate.month.toString().padLeft(2, '0')}-${parsedDate.day.toString().padLeft(2, '0')}";
      }

      final RegExp dateRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
      if (dateRegex.hasMatch(dateString)) {
        return dateString;
      }

      return dateString;
    } catch (e) {
      return dateString;
    }
  }

  Future<void> updateProfile() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      showLoadingStatus.value = true;

      final Map<String, dynamic> updateData = {};

      if (firstName.value.isNotEmpty &&
          firstName.value != student.value?.firstName) {
        updateData['first_name'] = firstName.value;
      }
      if (lastName.value.isNotEmpty &&
          lastName.value != student.value?.lastName) {
        updateData['last_name'] = lastName.value;
      }
      if (nickname.value != student.value?.nickname) {
        updateData['nickname'] = nickname.value;
      }
      if (age.value.isNotEmpty) {
        final ageInt = int.tryParse(age.value);
        if (ageInt != student.value?.age) {
          updateData['age'] = ageInt;
        }
      }
      if (gender.value.isNotEmpty && gender.value != student.value?.gender) {
        updateData['gender'] = gender.value;
      }
      if (dateOfBirth.value.isNotEmpty) {
        updateData['date_of_birth'] = dateOfBirth.value;
      }
      if (parentFirstName.value != student.value?.parentFirstName) {
        updateData['parent_first_name'] = parentFirstName.value;
      }
      if (parentLastName.value != student.value?.parentLastName) {
        updateData['parent_last_name'] = parentLastName.value;
      }
      if (address.value != student.value?.address) {
        updateData['address'] = address.value;
      }

      if (updateData.isEmpty) {
        Get.snackbar('Info'.tr, 'no_changes_detected'.tr);
        showLoadingStatus.value = false;
        isLoading.value = false;
        return;
      }

      final response = await _homeService.updateUser(updateData);

      if (response.code == 200 && response.data != null) {
        student.value = response.data!;
        box.write('student', response.data!.toJson());
        if (Get.isRegistered<HomeController>()) {
          Get.find<HomeController>().student.value = response.data!;
        }
        if (Get.isRegistered<SettingController>()) {
          Get.find<SettingController>().student.value = response.data!;
        }
      } else {
        errorMessage.value = response.message;
        showLoadingStatus.value = false;
        Get.snackbar('Error'.tr, errorMessage.value);
      }
    } catch (e) {
      errorMessage.value = 'an_error_occurred'.tr;
      showLoadingStatus.value = false;
      Get.snackbar('Error'.tr, errorMessage.value);
    } finally {
      isLoading.value = false;
    }
  }

  void updateDateOfBirth(DateTime pickedDate) {
    final formattedDate =
        "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
    dateOfBirth.value = formattedDate;

    final today = DateTime.now();
    int calculatedAge = today.year - pickedDate.year;
    if (today.month < pickedDate.month ||
        (today.month == pickedDate.month && today.day < pickedDate.day)) {
      calculatedAge--;
    }

    if (calculatedAge >= 0) {
      age.value = calculatedAge.toString();
      ageTextController.text = calculatedAge.toString();
    }
  }

  void clearError() {
    errorMessage.value = '';
  }

  void navigateBack() {
    Get.back();
  }

  String? validateFirstName(String? value) {
    if (value == null || value.isEmpty) {
      return 'first_name_is_required'.tr;
    }
    if (value.length > 100) {
      return 'first_name_cannot_exceed_100_characters'.tr;
    }
    return null;
  }

  String? validateLastName(String? value) {
    if (value != null && value.length > 100) {
      return 'last_name_cannot_exceed_100_characters'.tr;
    }
    return null;
  }

  String? validateAge(String? value) {
    if (value != null && value.isNotEmpty) {
      final age = int.tryParse(value);
      if (age == null) {
        return 'age_must_be_a_number'.tr;
      }
      if (age < 1 || age > 100) {
        return 'age_must_be_between_1_and_100'.tr;
      }
    }
    return null;
  }

  String? validateGender(String? value) {
    if (value != null && value.isNotEmpty) {
      if (!['male', 'female', 'other'].contains(value.toLowerCase())) {
        return 'gender_must_be_male_female_or_other'.tr;
      }
    }
    return null;
  }

  @override
  void onClose() {
    ageTextController.dispose();
    super.onClose();
  }
}
