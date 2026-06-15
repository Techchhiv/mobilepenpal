/// A bilingual question template fetched from the backend.
///
/// Templates contain placeholders like `{a}`, `{b}`, `{fruit}` that are
/// substituted at runtime with randomly-generated values.
class QuestionTemplateModel {
  final int id;
  final String questionEn;
  final String questionKh;
  final String operation; // 'add', 'sub', 'mul', 'div'
  final String difficulty; // 'easy', 'medium', 'hard'
  final bool isActive;

  QuestionTemplateModel({
    required this.id,
    required this.questionEn,
    required this.questionKh,
    required this.operation,
    required this.difficulty,
    required this.isActive,
  });

  factory QuestionTemplateModel.fromJson(Map<String, dynamic> json) {
    return QuestionTemplateModel(
      id: json['id'] as int,
      questionEn: json['question_en'] as String,
      questionKh: json['question_kh'] as String,
      operation: json['operation'] as String? ?? 'add',
      difficulty: json['difficulty'] as String? ?? 'easy',
      isActive: json['is_active'] == true || json['is_active'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question_en': questionEn,
      'question_kh': questionKh,
      'operation': operation,
      'difficulty': difficulty,
      'is_active': isActive,
    };
  }
}
