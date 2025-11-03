class StudentEndpoints {
  static const String _base = '/student/v01';

  // Authentication
  static const String login = '$_base/auth/login';
  static const String register = '$_base/auth/register';
  static const String logout = '$_base/auth/logout';

  // Check Student
  static const String profile = '$_base/check';
}
