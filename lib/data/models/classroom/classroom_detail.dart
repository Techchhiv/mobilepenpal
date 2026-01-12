class ClassroomTeacher {
  final int id;
  final String name;

  ClassroomTeacher({required this.id, required this.name});

  factory ClassroomTeacher.fromJson(Map<String, dynamic> json) {
    return ClassroomTeacher(
      id: (json['id'] ?? 0) as int,
      name: (json['name'] ?? '').toString(),
    );
  }
}

class ClassroomEnrollment {
  final String status;
  final DateTime? enrolledAt;

  ClassroomEnrollment({required this.status, this.enrolledAt});

  factory ClassroomEnrollment.fromJson(Map<String, dynamic> json) {
    final raw = json['enrolled_at'];
    DateTime? dt;
    if (raw != null && raw.toString().isNotEmpty) {
      dt = DateTime.tryParse(raw.toString());
    }
    return ClassroomEnrollment(
      status: (json['status'] ?? '').toString(),
      enrolledAt: dt,
    );
  }
}

class Classmate {
  final int id;
  final String firstName;
  final String? lastName;
  final String? nickname;
  final String? avatar;

  Classmate({
    required this.id,
    required this.firstName,
    this.lastName,
    this.nickname,
    this.avatar,
  });

  factory Classmate.fromJson(Map<String, dynamic> json) {
    return Classmate(
      id: (json['id'] ?? 0) as int,
      firstName: (json['first_name'] ?? '').toString(),
      lastName: json['last_name']?.toString(),
      nickname: json['nickname']?.toString(),
      avatar: json['avatar']?.toString(),
    );
  }

  String get displayName {
    final nick = (nickname ?? '').trim();
    if (nick.isNotEmpty) return nick;
    final ln = (lastName ?? '').trim();
    return ln.isEmpty ? firstName : '$firstName $ln';
    }
}

class ClassroomDetail {
  final int id;
  final String name;
  final bool isActive;
  final int studentsCount;
  final ClassroomTeacher? teacher;
  final ClassroomEnrollment? enrollment;
  final List<Classmate> classmates;

  ClassroomDetail({
    required this.id,
    required this.name,
    required this.isActive,
    required this.studentsCount,
    required this.teacher,
    required this.enrollment,
    required this.classmates,
  });

  factory ClassroomDetail.fromJson(Map<String, dynamic> json) {
    return ClassroomDetail(
      id: (json['id'] ?? 0) as int,
      name: (json['name'] ?? '').toString(),
      isActive: (json['is_active'] ?? false) == true,
      studentsCount: (json['students_count'] ?? 0) as int,
      teacher: json['teacher'] is Map<String, dynamic>
          ? ClassroomTeacher.fromJson(json['teacher'])
          : null,
      enrollment: json['enrollment'] is Map<String, dynamic>
          ? ClassroomEnrollment.fromJson(json['enrollment'])
          : null,
      classmates: (json['classmates'] is List)
          ? (json['classmates'] as List)
              .whereType<Map<String, dynamic>>()
              .map(Classmate.fromJson)
              .toList()
          : <Classmate>[],
    );
  }
}
