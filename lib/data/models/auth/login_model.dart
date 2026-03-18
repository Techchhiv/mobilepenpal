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
  int? enrollmentYear;
  int? isActive;
  String? schoolKey;
  String? createdAt;
  String? updatedAt;
  int? coin;
  int? xp;
  int? streak;
  List<String>? unlockedAvatars;

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
    this.enrollmentYear,
    this.isActive,
    this.schoolKey,
    this.createdAt,
    this.updatedAt,
    this.coin,
    this.xp,
    this.streak,
    this.unlockedAvatars,
  });

  static String? _s(dynamic v) => v?.toString();
  static int? _i(dynamic v) =>
      v == null ? null : (v is int ? v : int.tryParse(v.toString()));
  static List<String>? _l(dynamic v) {
    if (v == null) return null;
    if (v is List) return v.map((e) => e.toString()).toList();
    return null;
  }

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: _i(json['id']),
      schoolId: _i(json['school_id']),
      firstName: _s(json['first_name']),
      lastName: _s(json['last_name']),
      dateOfBirth: _s(json['date_of_birth']),
      gender: _s(json['gender']),
      email: _s(json['email']),
      phone: _s(json['phone']),
      parentFirstName: _s(json['parent_first_name']),
      parentLastName: _s(json['parent_last_name']),
      parentEmail: _s(json['parent_email']),
      parentPhone: _s(json['parent_phone']),
      address: _s(json['address']),
      enrollmentYear: _i(json['enrollment_year']),
      isActive: _i(json['is_active']),
      schoolKey: _s(json['school_key']),
      createdAt: _s(json['created_at']),
      updatedAt: _s(json['updated_at']),
      coin: _i(json['coin']) ?? 0,
      xp: _i(json['xp']) ?? 0,
      streak: _i(json['streak']) ?? 0,
      unlockedAvatars: _l(json['unlocked_avatars']) ?? [],
    );
  }

  String get fullName => '${firstName ?? ''} ${lastName ?? ''}'.trim();
  String get parentFullName =>
      '${parentFirstName ?? ''} ${parentLastName ?? ''}'.trim();
}
