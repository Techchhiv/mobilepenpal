class HomeEndpoints {
  static const String _base = '/student/v01';

  // Profile
  static const String profile = '$_base/profile';
  static const String update = '$_base/profile';
  static const String password = '$_base/profile/password';
  static const String updatePin = '$_base/profile/update-pin';
  static const String uploadImage = '$_base/profile/upload-avatar';

  // Check Student
  static const String switchMode = '$_base/switch-mode';
}
