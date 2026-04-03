import 'dart:convert';
import 'student_answer.dart';

class ScanResult {
  final int? id;
  final int examId;
  final String studentName;
  final String studentNumber;
  final int totalScore;
  final int totalQuestions;
  final List<StudentAnswer> answers;
  final DateTime scannedAt;
  final String? imagePath;

  ScanResult({
    this.id,
    required this.examId,
    this.studentName = '',
    this.studentNumber = '',
    required this.totalScore,
    required this.totalQuestions,
    required this.answers,
    DateTime? scannedAt,
    this.imagePath,
  }) : scannedAt = scannedAt ?? DateTime.now();

  double get percentage =>
      totalQuestions > 0 ? (totalScore / totalQuestions) * 100 : 0;

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'exam_id': examId,
      'student_name': studentName,
      'student_number': studentNumber,
      'total_score': totalScore,
      'total_questions': totalQuestions,
      'answers_json': json.encode(answers.map((a) => a.toMap()).toList()),
      'scanned_at': scannedAt.toIso8601String(),
      'image_path': imagePath,
    };
  }

  factory ScanResult.fromMap(Map<String, dynamic> map) {
    final answersList = (json.decode(map['answers_json'] as String) as List)
        .map((a) => StudentAnswer.fromMap(a as Map<String, dynamic>))
        .toList();

    return ScanResult(
      id: map['id'] as int?,
      examId: map['exam_id'] as int,
      studentName: map['student_name'] as String? ?? '',
      studentNumber: map['student_number'] as String? ?? '',
      totalScore: map['total_score'] as int,
      totalQuestions: map['total_questions'] as int,
      answers: answersList,
      scannedAt: DateTime.parse(map['scanned_at'] as String),
      imagePath: map['image_path'] as String?,
    );
  }

  ScanResult copyWith({
    int? id,
    int? examId,
    String? studentName,
    String? studentNumber,
    int? totalScore,
    int? totalQuestions,
    List<StudentAnswer>? answers,
    DateTime? scannedAt,
    String? imagePath,
  }) {
    return ScanResult(
      id: id ?? this.id,
      examId: examId ?? this.examId,
      studentName: studentName ?? this.studentName,
      studentNumber: studentNumber ?? this.studentNumber,
      totalScore: totalScore ?? this.totalScore,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      answers: answers ?? this.answers,
      scannedAt: scannedAt ?? this.scannedAt,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}
