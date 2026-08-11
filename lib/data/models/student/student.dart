class Student {
  final int id;
  final int? schoolId;
  final String? schoolKey;
  final String firstName;
  final String? lastName;
  final String? nickname;
  final int? age;
  final String? gender;
  final String? dateOfBirth;
  final String? avatar;

  final String? parentPin;
  final String? parentFirstName;
  final String? parentLastName;

  final String? email;
  final String? phone;

  final String? address;
  final int? enrollmentYear;

  final bool isActive;
  final bool hasSubscription;
  final String? subscriptionPlan;
  final String? subscriptionStartDate;
  final String? subscriptionEndDate;
  
  final int coin;
  final int xp;
  final int streak;
  final List<String> unlockedAvatars;

  Student({
    required this.id,
    this.schoolId,
    this.schoolKey,
    required this.firstName,
    this.lastName,
    this.nickname,
    this.age,
    this.gender,
    this.dateOfBirth,
    this.avatar,
    this.parentPin,
    this.parentFirstName,
    this.parentLastName,
    this.email,
    this.phone,
    this.address,
    this.enrollmentYear,
    required this.isActive,
    this.hasSubscription = false,
    this.subscriptionPlan,
    this.subscriptionStartDate,
    this.subscriptionEndDate,
    this.coin = 0,
    this.xp = 0,
    this.streak = 0,
    this.unlockedAvatars = const [],
  });

  bool get isSchoolAccount =>
      schoolId != null || (schoolKey != null && schoolKey!.trim().isNotEmpty);

  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  static String? _toStringOrNull(dynamic v) {
    if (v == null) return null;
    return v.toString();
  }

  static bool _toBool(dynamic v) {
    if (v == null) return false;
    if (v is bool) return v;
    if (v is int) return v == 1;
    return v.toString() == '1' || v.toString().toLowerCase() == 'true';
  }

  static List<String> _toStringList(dynamic v) {
    if (v == null) return [];
    if (v is List) return v.map((e) => e.toString()).toList();
    return [];
  }

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: _toInt(json['id']) ?? 0,
      schoolId: _toInt(json['school_id']),
      schoolKey: _toStringOrNull(json['school_key']),
      firstName: _toStringOrNull(json['first_name']) ?? '',
      lastName: _toStringOrNull(json['last_name']),
      nickname: _toStringOrNull(json['nickname']),
      age: _toInt(json['age']),
      gender: _toStringOrNull(json['gender']),
      dateOfBirth: _toStringOrNull(json['date_of_birth']),
      avatar: _toStringOrNull(json['avatar']),
      parentPin: _toStringOrNull(json['parent_pin']),
      parentFirstName: _toStringOrNull(json['parent_first_name']),
      parentLastName: _toStringOrNull(json['parent_last_name']),
      email: _toStringOrNull(json['email']),
      phone: _toStringOrNull(json['phone']),
      address: _toStringOrNull(json['address']),
      enrollmentYear: _toInt(json['enrollment_year']),
      isActive: _toBool(json['is_active']),
      hasSubscription: _toBool(json['has_subscription']),
      subscriptionPlan: _toStringOrNull(json['subscription_plan']),
      subscriptionStartDate: _toStringOrNull(json['subscription_start_date']),
      subscriptionEndDate: _toStringOrNull(json['subscription_end_date']),
      coin: _toInt(json['coin']) ?? 0,
      xp: _toInt(json['xp']) ?? 0,
      streak: _toInt(json['streak']) ?? 0,
      unlockedAvatars: _toStringList(json['unlocked_avatars']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'school_id': schoolId,
      'school_key': schoolKey,
      'first_name': firstName,
      'last_name': lastName,
      'nickname': nickname,
      'age': age,
      'gender': gender,
      'date_of_birth': dateOfBirth,
      'avatar': avatar,
      'parent_pin': parentPin,
      'parent_first_name': parentFirstName,
      'parent_last_name': parentLastName,
      'email': email,
      'phone': phone,
      'address': address,
      'enrollment_year': enrollmentYear,
      'is_active': isActive,
      'has_subscription': hasSubscription,
      'subscription_plan': subscriptionPlan,
      'subscription_start_date': subscriptionStartDate,
      'subscription_end_date': subscriptionEndDate,
      'coin': coin,
      'xp': xp,
      'streak': streak,
      'unlocked_avatars': unlockedAvatars,
    };
  }
}
