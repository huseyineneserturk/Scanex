class AnswerKeyEntry {
  final int? id;
  final int examId;
  final int questionNumber;
  final String correctOption;

  AnswerKeyEntry({
    this.id,
    required this.examId,
    required this.questionNumber,
    required this.correctOption,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'exam_id': examId,
      'question_number': questionNumber,
      'correct_option': correctOption,
    };
  }

  factory AnswerKeyEntry.fromMap(Map<String, dynamic> map) {
    return AnswerKeyEntry(
      id: map['id'] as int?,
      examId: map['exam_id'] as int,
      questionNumber: map['question_number'] as int,
      correctOption: map['correct_option'] as String,
    );
  }

  AnswerKeyEntry copyWith({
    int? id,
    int? examId,
    int? questionNumber,
    String? correctOption,
  }) {
    return AnswerKeyEntry(
      id: id ?? this.id,
      examId: examId ?? this.examId,
      questionNumber: questionNumber ?? this.questionNumber,
      correctOption: correctOption ?? this.correctOption,
    );
  }
}
