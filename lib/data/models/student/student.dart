class Student {
  final int id;
  final int? schoolId;
  final String? firstName;
  final String? lastName;
  final String? dateOfBirth;
  final String? gender;
  final String? email;
  final String? phone;
  final String? parentFirstName;
  final String? parentLastName;
  final String? parentEmail;
  final String? parentPhone;
  final String? address;
  final String? dataOfEnrollment;
  final int? isActive;
  final String? schoolKey;
  final String? createdAt;
  final String? updatedAt;

  Student({
    required this.id,
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
    this.dataOfEnrollment,
    this.isActive,
    this.schoolKey,
    this.createdAt,
    this.updatedAt,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'] as int,
      schoolId: json['school_id'] as int?,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      dateOfBirth: json['date_of_birth'] as String?,
      gender: json['gender'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      parentFirstName: json['parent_first_name'] as String?,
      parentLastName: json['parent_last_name'] as String?,
      parentEmail: json['parent_email'] as String?,
      parentPhone: json['parent_phone'] as String?,
      address: json['address'] as String?,
      dataOfEnrollment: json['data_of_enrollment'] as String?,
      isActive: json['is_active'] as int?,
      schoolKey: json['school_key'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'school_id': schoolId,
      'first_name': firstName,
      'last_name': lastName,
      'date_of_birth': dateOfBirth,
      'gender': gender,
      'email': email,
      'phone': phone,
      'parent_first_name': parentFirstName,
      'parent_last_name': parentLastName,
      'parent_email': parentEmail,
      'parent_phone': parentPhone,
      'address': address,
      'data_of_enrollment': dataOfEnrollment,
      'is_active': isActive,
      'school_key': schoolKey,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  String get fullName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    } else if (firstName != null) {
      return firstName!;
    } else if (lastName != null) {
      return lastName!;
    }
    return 'Unknown';
  }

  String get parentFullName {
    if (parentFirstName != null && parentLastName != null) {
      return '$parentFirstName $parentLastName';
    } else if (parentFirstName != null) {
      return parentFirstName!;
    } else if (parentLastName != null) {
      return parentLastName!;
    }
    return 'Unknown';
  }

  bool get isStudentActive => isActive == 1;

  @override
  String toString() {
    return 'Student(id: $id, name: $fullName, email: $email, phone: $phone)';
  }
}