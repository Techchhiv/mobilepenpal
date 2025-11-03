class Student {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String? address;
  final String schoolKey;

  Student({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    this.address,
    required this.schoolKey,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'],
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'],
      schoolKey: json['school_key'] ?? '',
    );
  }
}
