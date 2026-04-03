import 'package:flutter/foundation.dart';
import '../core/database/database_helper.dart';
import '../models/scan_result.dart';

class ResultsProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  List<ScanResult> _results = [];
  bool _loading = false;

  List<ScanResult> get results => _results;
  bool get loading => _loading;

  Future<void> loadResultsForExam(int examId) async {
    _loading = true;
    notifyListeners();

    _results = await _db.getResultsForExam(examId);

    _loading = false;
    notifyListeners();
  }

  Future<void> loadAllResults() async {
    _loading = true;
    notifyListeners();

    _results = await _db.getAllResults();

    _loading = false;
    notifyListeners();
  }

  Future<int> saveResult(ScanResult result) async {
    final id = await _db.insertScanResult(result);
    _results.insert(0, result.copyWith(id: id));
    notifyListeners();
    return id;
  }

  Future<void> deleteResult(int id) async {
    await _db.deleteScanResult(id);
    _results.removeWhere((r) => r.id == id);
    notifyListeners();
  }

  Future<int> getResultCount(int examId) async {
    return await _db.getResultCountForExam(examId);
  }
}
