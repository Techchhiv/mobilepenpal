class Student {
  final int id;
  final String firstName;
  final String lastName;
  final String? nickname;
  final int? age;
  final String? gender;
  final String? dateOfBirth;
  final String? avatar;
  final String? mode;
  final String? parentPin;
  final String? parentFirstName;
  final String? parentLastName;
  final String? email;
  final String phone;
  final int? level;
  final int? streak;
  final int? timeSpent;
  final String? lastPlayed;
  final String? address;
  final String? enrollmentYear;

  Student({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.nickname,
    this.age,
    this.gender,
    this.dateOfBirth,
    this.avatar,
    this.mode,
    this.parentPin,
    this.parentFirstName,
    this.parentLastName,
    this.email,
    required this.phone,
    this.level,
    this.streak,
    this.timeSpent,
    this.lastPlayed,
    this.address,
    this.enrollmentYear,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'] ?? 0,
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      nickname: json['nickname'],
      age: json['age'],
      gender: json['gender'],
      dateOfBirth: json['date_of_birth'],
      avatar: json['avatar'],
      mode: json['mode'],
      parentPin: json['parent_pin'],
      parentFirstName: json['parent_first_name'],
      parentLastName: json['parent_last_name'],
      email: json['email'],
      phone: json['phone'] ?? '',
      level: json['level'],
      streak: json['streak'] ?? 0,
      timeSpent: json['time_spent'] ?? 0,
      lastPlayed: json['last_played'],
      address: json['address'],
      enrollmentYear: json['enrollment_year'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'nickname': nickname,
      'age': age,
      'gender': gender,
      'date_of_birth': dateOfBirth,
      'avatar': avatar,
      'mode': mode,
      'parent_pin': parentPin,
      'parent_first_name': parentFirstName,
      'parent_last_name': parentLastName,
      'email': email,
      'phone': phone,
      'level': level,
      'streak': streak,
      'time_spent': timeSpent,
      'last_played': lastPlayed,
      'address': address,
      'enrollment_year': enrollmentYear,
    };
  }
}
