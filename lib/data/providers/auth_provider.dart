import 'package:flutter/foundation.dart';
import '../models/auth/login_model.dart';
import '../models/auth/login_request.dart';
import 'package:mobilepenpal/data/services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  Student? _currentStudent;
  bool _isLoading = false;
  String? _error;

  Student? get currentStudent => _currentStudent;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Future<bool> login(String identifier, String password) async {
  //   _isLoading = true;
  //   _error = null;
  //   notifyListeners();

  //   try {
  //     final request = LoginRequest(identifier: identifier, password: password);
  //     final response = await _authService.login(request);

  //     if (response.isSuccess) {
  //       _currentStudent = response.data.student;
  //       _isLoading = false;
  //       notifyListeners();
  //       return true;
  //     } else {
  //       _error = response.message;
  //       _isLoading = false;
  //       notifyListeners();
  //       return false;
  //     }
  //   } catch (e) {
  //     _error = 'Network error: Please check your connection';
  //     _isLoading = false;
  //     notifyListeners();
  //     return false;
  //   }
  // }

  Future<void> logout() async {
    await _authService.logout();
    _currentStudent = null;
    _error = null;
    notifyListeners();
  }

  // Future<bool> checkAuthStatus() async {
  //   final isLoggedIn = await _authService.isLoggedIn();

  //   if (isLoggedIn && _currentStudent == null) {
  //     try {
  //       final response = await _authService.getProfile();
  //       if (response.isSuccess) {
  //         _currentStudent = response.data;
  //         notifyListeners();
  //       } else {
  //         await logout();
  //       }
  //     } catch (e) {
  //       await logout();
  //     }
  //   } else if (!isLoggedIn) {
  //     _currentStudent = null;
  //     notifyListeners();
  //   }

  //   return isLoggedIn && _currentStudent != null;
  // }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
