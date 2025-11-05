import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobilepenpal/data/models/student/student.dart';
import 'package:mobilepenpal/data/services/auth_service.dart';

class HomeController extends GetxController {
  final AuthService _authService = AuthService();
  
  var isLoading = false.obs;
  var student = Rxn<Student>();
  var errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    // Optionally load profile automatically when home page opens
    // getProfile();
  }

  Future<void> getProfile() async {
    if (isLoading.value) return;

    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await _authService.getProfile();

      if (response.code == 200 && response.data != null) {
        student.value = response.data;
        Get.snackbar(
          "Success",
          "Profile loaded successfully!",
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        errorMessage.value = response.message ?? "Failed to load profile";
        Get.snackbar(
          "Error",
          errorMessage.value,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      errorMessage.value = "Network error: $e";
      Get.snackbar(
        "Error",
        errorMessage.value,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      print("Profile error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void logout() {
    Get.dialog(
      AlertDialog(
        title: Text('Logout'),
        content: Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Get.back(),
          ),
          TextButton(
            child: Text('Logout'),
            onPressed: () async {
              await _authService.logout();
              Get.back();
              Get.offAllNamed('/login');
            },
          ),
        ],
      ),
    );
  }
}