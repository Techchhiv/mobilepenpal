import 'package:flutter/material.dart';
import 'package:mobilepenpal/data/models/student/student.dart';
import 'package:mobilepenpal/data/services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final service = AuthService();

  const identifier = '081347800';
  const password = 'password123';
  const schoolKey = 'GHS2024';

  final result = await service.loginStudent(
    identifier: identifier,
    password: password,
    schoolKey: schoolKey,
  );

  final result1 = await service.getProfile();

  print('\n==================== API RESULT ====================');
  print('Code: ${result.code}');
  print('Message: ${result.message}');
  print('Error: ${result.error}');
  print('---------------------------------------------------');

  print('Profile Fetch Result:');
  print('Code: ${result1.data}');

  if (result.code == 200) {
    final student = result.data?['student'] as Student;
    print('✅ Login successful!');
    print('Student: ${student.firstName} ${student.lastName}');
    print('Token stored securely.');
  } else {
    print('❌ Login failed.');
  }

  print('====================================================\n');
}
