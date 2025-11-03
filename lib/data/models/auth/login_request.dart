class LoginRequest {
  final String identifier;
  final String password;
  // final String? schoolKey;

  LoginRequest({
    required this.identifier,
    required this.password,
    // this.schoolKey,
  });

  Map<String, dynamic> toJson() {
    return {
      'identifier': identifier,
      'password': password,
      // if (schoolKey != null) 'school_key': schoolKey,
    };
  }
}