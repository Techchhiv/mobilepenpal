class Classroom {
  final int id;
  final String name;
  final bool isActive;
  final int studentsCount;
  final String? teacherName;
  final DateTime? enrolledAt;

  Classroom({
    required this.id,
    required this.name,
    required this.isActive,
    required this.studentsCount,
    this.teacherName,
    this.enrolledAt,
  });

  factory Classroom.fromJson(Map<String, dynamic> json) {
    final teacher = json['teacher'] as Map<String, dynamic>?;
    final enrollment = json['enrollment'] as Map<String, dynamic>?;

    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      final s = v.toString().trim();
      if (s.isEmpty) return null;
      return DateTime.tryParse(s);
    }

    return Classroom(
      id: (json['id'] as num).toInt(),
      name: (json['name'] ?? '').toString(),
      isActive: json['is_active'] == true || json['is_active'] == 1,
      studentsCount: (json['students_count'] is num)
          ? (json['students_count'] as num).toInt()
          : int.tryParse(json['students_count']?.toString() ?? '0') ?? 0,
      teacherName: teacher?['name']?.toString(),
      enrolledAt: parseDate(enrollment?['enrolled_at']),
    );
  }
}
