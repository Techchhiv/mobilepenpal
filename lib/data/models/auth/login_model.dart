class LoginResponse {
  final String token;
  final Student student;

  LoginResponse({required this.token, required this.student});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: (json['token'] as String?) ?? '',
      student: Student.fromJson(json['student'] ?? {}),
    );
  }
}

class Student {
  int? id;
  int? schoolId;
  String? firstName;
  String? lastName;
  String? dateOfBirth;
  String? gender;
  String? email;
  String? phone;
  String? parentFirstName;
  String? parentLastName;
  String? parentEmail;
  String? parentPhone;
  String? address;
  String? dateOfEnrollment;
  int? isActive;
  String? schoolKey;
  String? createdAt;
  String? updatedAt;

  Student({
    this.id,
    this.schoolId,
    this.firstName,
    this.lastName,
    this.dateOfBirth,
    this.gender,
    this.email,
    this.phone,
    this.parentFirstName,
    this.parentLastName,
    this.parentEmail,
    this.parentPhone,
    this.address,
    this.dateOfEnrollment,
    this.isActive,
    this.schoolKey,
    this.createdAt,
    this.updatedAt,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'],
      schoolId: json['school_id'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      dateOfBirth: json['date_of_birth'],
      gender: json['gender'],
      email: json['email'],
      phone: json['phone'],
      parentFirstName: json['parent_first_name'],
      parentLastName: json['parent_last_name'],
      parentEmail: json['parent_email'],
      parentPhone: json['parent_phone'],
      address: json['address'],
      dateOfEnrollment: json['data_of_enrollment'],
      isActive: json['is_active'],
      schoolKey: json['school_key'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  String get fullName => '$firstName $lastName';
  String get parentFullName => '$parentFirstName $parentLastName';
}
