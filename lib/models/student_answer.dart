import 'dart:convert';

class StudentAnswer {
  final int questionNumber;
  final String? selectedOption;
  final String correctOption;
  final bool isCorrect;

  StudentAnswer({
    required this.questionNumber,
    this.selectedOption,
    required this.correctOption,
    bool? isCorrect,
  }) : isCorrect = isCorrect ?? (selectedOption == correctOption);

  Map<String, dynamic> toMap() {
    return {
      'questionNumber': questionNumber,
      'selectedOption': selectedOption,
      'correctOption': correctOption,
      'isCorrect': isCorrect,
    };
  }

  factory StudentAnswer.fromMap(Map<String, dynamic> map) {
    return StudentAnswer(
      questionNumber: map['questionNumber'] as int,
      selectedOption: map['selectedOption'] as String?,
      correctOption: map['correctOption'] as String,
      isCorrect: map['isCorrect'] as bool,
    );
  }

  String toJson() => json.encode(toMap());

  factory StudentAnswer.fromJson(String source) =>
      StudentAnswer.fromMap(json.decode(source) as Map<String, dynamic>);
}
