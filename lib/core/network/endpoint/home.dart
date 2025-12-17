class HomeEndpoints {
  static const String _base = '/student/v01';

  // Profile
  static const String profile = '$_base/profile';
  static const String update = '$_base/profile';
  static const String password = '$_base/profile/password';
  static const String updatePin = '$_base/profile/update-pin';
  static const String uploadImage = '$_base/profile/upload-avatar';

  static const String dailySummary = '$_base/profile/summary/daily';
  static const String weeklySummary = '$_base/profile/summary/weekly';
  static const String monthlySummary = '$_base/profile/summary/monthly';

  // Check Student
  static const String switchMode = '$_base/switch-mode';
}
