class Exam {
  final int? id;
  final String name;
  final int questionCount;
  final int optionCount;
  final DateTime createdAt;

  Exam({
    this.id,
    required this.name,
    required this.questionCount,
    this.optionCount = 5,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'question_count': questionCount,
      'option_count': optionCount,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Exam.fromMap(Map<String, dynamic> map) {
    return Exam(
      id: map['id'] as int?,
      name: map['name'] as String,
      questionCount: map['question_count'] as int,
      optionCount: map['option_count'] as int? ?? 5,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Exam copyWith({
    int? id,
    String? name,
    int? questionCount,
    int? optionCount,
    DateTime? createdAt,
  }) {
    return Exam(
      id: id ?? this.id,
      name: name ?? this.name,
      questionCount: questionCount ?? this.questionCount,
      optionCount: optionCount ?? this.optionCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() => 'Exam(id: $id, name: $name, questions: $questionCount)';
}
