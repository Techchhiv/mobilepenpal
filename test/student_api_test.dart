import 'package:mobilepenpal/data/models/auth/login_request.dart';
import 'package:mobilepenpal/data/services/auth_service.dart';

class ApiTester {
  static Future<void> testConnection() async {
    print('🚀 Starting API Connection Test...\n');
    
    try {
      final authService = AuthService();
      final testRequest = LoginRequest(
        identifier: "081347800",
        password: "password123",
      );

      print('📤 Sending login request...');
      print('Email: ${testRequest.identifier}');
      print('Password: ${testRequest.password}');
      
      final response = await authService.login(testRequest);
      
      print('\n✅ SUCCESS! API is working!');
      print('Status: ${response.code}');
      print('Message: ${response.message}');
      
      if (response.isSuccess) {
        print('Token: ${response.data.token}');
        print('User: ${response.data.student.fullName}');
        print('Email: ${response.data.student.email}');
      } else {
        print('❌ Login failed but API is reachable');
        print('Error: ${response.message}');
      }
      
    } catch (e) {
      print('\n❌ API TEST FAILED!');
      print('Error: $e');
      print('\n🔧 Troubleshooting:');
      print('1. Check base URL in env.dart');
      print('2. Verify backend server is running');
      print('3. Check network connection');
      print('4. Verify CORS settings');
    }
  }
}