import 'package:get/get.dart';
import '../models/auth/login_model.dart';
import '../models/auth/login_request.dart';
import '../services/auth_service.dart';

class AuthController extends GetxController {
  final AuthService _authService = AuthService();
  
  // Reactive state variables
  var currentStudent = Rxn<Student>();
  var isLoading = false.obs;
  var error = RxString('');
  
  // Getters
  Student? get student => currentStudent.value;
  bool get isLoggedIn => currentStudent.value != null;

  // Login method
  // Future<bool> login(String email, String password) async {
  //   try {
  //     isLoading.value = true;
  //     error.value = '';
      
  //     final request = LoginRequest(identifier: email, password: password);
  //     final response = await _authService.login(request);
      
  //     if (response.isSuccess) {
  //       currentStudent.value = response.data.student;
  //       isLoading.value = false;
  //       return true;
  //     } else {
  //       error.value = response.message;
  //       isLoading.value = false;
  //       return false;
  //     }
  //   } catch (e) {
  //     error.value = 'Network error: Please check your connection';
  //     isLoading.value = false;
  //     return false;
  //   }
  // }

  Future<void> logout() async {
    await _authService.logout();
    currentStudent.value = null;
    error.value = '';
    Get.offAllNamed('/login');
  }

  // Future<void> checkAuthStatus() async {
  //   final isAuthenticated = await _authService.isLoggedIn();
    
  //   if (isAuthenticated && currentStudent.value == null) {
  //     try {
  //       final response = await _authService.getProfile();
  //       if (response.isSuccess) {
  //         currentStudent.value = response.data;
  //       } else {
  //         await logout();
  //       }
  //     } catch (e) {
  //       await logout();
  //     }
  //   }
  // }
}