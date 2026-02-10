class Env {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    // defaultValue: 'https://api.dev.khmerpenpal.com/api/mobile',
        defaultValue: 'http://192.168.0.157:8000/api/mobile',
  );

  static const String aiApiBaseUrl = String.fromEnvironment(
    'AI_API_BASE_URL',
    defaultValue: 'https://api.khmerpenpal.com/predict',
  );

  static const String backendUrl = String.fromEnvironment(
    'BACKEND_URL',
    // defaultValue: 'https://api.dev.khmerpenpal.com',
    defaultValue: 'http://192.168.0.157:8000',
  );

  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );

  static bool get isDebug => environment == 'development';

  static const String apiVersion = 'v1';
  
  static const String accessToken = 'student_token';
}
