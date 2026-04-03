import 'package:flutter/foundation.dart';
import '../core/database/database_helper.dart';
import '../models/exam.dart';
import '../models/answer_key_entry.dart';

class ExamProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  List<Exam> _exams = [];
  bool _loading = false;

  List<Exam> get exams => _exams;
  bool get loading => _loading;

  Future<void> loadExams() async {
    _loading = true;
    notifyListeners();

    _exams = await _db.getExams();

    _loading = false;
    notifyListeners();
  }

  Future<Exam> createExam(String name, int questionCount) async {
    final exam = Exam(name: name, questionCount: questionCount);
    final id = await _db.insertExam(exam);
    final created = exam.copyWith(id: id);
    _exams.insert(0, created);
    notifyListeners();
    return created;
  }

  Future<void> saveAnswerKey(int examId, List<String> answers) async {
    final entries = <AnswerKeyEntry>[];
    for (int i = 0; i < answers.length; i++) {
      entries.add(AnswerKeyEntry(
        examId: examId,
        questionNumber: i + 1,
        correctOption: answers[i],
      ));
    }
    await _db.saveAnswerKey(examId, entries);
    notifyListeners();
  }

  Future<List<AnswerKeyEntry>> getAnswerKey(int examId) async {
    return await _db.getAnswerKey(examId);
  }

  Future<void> deleteExam(int id) async {
    await _db.deleteExam(id);
    _exams.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  /// Get exams that have answer keys defined
  Future<List<Exam>> getExamsWithAnswerKeys() async {
    final result = <Exam>[];
    for (final exam in _exams) {
      final keys = await _db.getAnswerKey(exam.id!);
      if (keys.isNotEmpty) {
        result.add(exam);
      }
    }
    return result;
  }
}
