import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../models/exam.dart';
import '../../models/answer_key_entry.dart';
import '../../models/scan_result.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'scanex.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE exams (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        question_count INTEGER NOT NULL,
        option_count INTEGER NOT NULL DEFAULT 5,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE answer_keys (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        exam_id INTEGER NOT NULL REFERENCES exams(id) ON DELETE CASCADE,
        question_number INTEGER NOT NULL,
        correct_option TEXT NOT NULL,
        UNIQUE(exam_id, question_number)
      )
    ''');

    await db.execute('''
      CREATE TABLE scan_results (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        exam_id INTEGER NOT NULL REFERENCES exams(id),
        student_name TEXT,
        student_number TEXT,
        total_score INTEGER NOT NULL,
        total_questions INTEGER NOT NULL,
        answers_json TEXT NOT NULL,
        scanned_at TEXT NOT NULL,
        image_path TEXT
      )
    ''');

    await db.execute(
        'CREATE INDEX idx_results_exam ON scan_results(exam_id)');
  }

  // ===================== EXAM CRUD =====================

  Future<int> insertExam(Exam exam) async {
    final db = await database;
    return await db.insert('exams', exam.toMap());
  }

  Future<List<Exam>> getExams() async {
    final db = await database;
    final maps = await db.query('exams', orderBy: 'created_at DESC');
    return maps.map((m) => Exam.fromMap(m)).toList();
  }

  Future<Exam?> getExam(int id) async {
    final db = await database;
    final maps = await db.query('exams', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Exam.fromMap(maps.first);
  }

  Future<int> deleteExam(int id) async {
    final db = await database;
    // Delete cascade: answer keys and results
    await db.delete('answer_keys', where: 'exam_id = ?', whereArgs: [id]);
    await db.delete('scan_results', where: 'exam_id = ?', whereArgs: [id]);
    return await db.delete('exams', where: 'id = ?', whereArgs: [id]);
  }

  // ===================== ANSWER KEY CRUD =====================

  Future<void> saveAnswerKey(int examId, List<AnswerKeyEntry> entries) async {
    final db = await database;
    final batch = db.batch();

    // Clear existing entries for this exam
    batch.delete('answer_keys', where: 'exam_id = ?', whereArgs: [examId]);

    // Insert new entries
    for (final entry in entries) {
      batch.insert('answer_keys', entry.toMap());
    }

    await batch.commit(noResult: true);
  }

  Future<List<AnswerKeyEntry>> getAnswerKey(int examId) async {
    final db = await database;
    final maps = await db.query(
      'answer_keys',
      where: 'exam_id = ?',
      whereArgs: [examId],
      orderBy: 'question_number ASC',
    );
    return maps.map((m) => AnswerKeyEntry.fromMap(m)).toList();
  }

  // ===================== SCAN RESULT CRUD =====================

  Future<int> insertScanResult(ScanResult result) async {
    final db = await database;
    return await db.insert('scan_results', result.toMap());
  }

  Future<List<ScanResult>> getResultsForExam(int examId) async {
    final db = await database;
    final maps = await db.query(
      'scan_results',
      where: 'exam_id = ?',
      whereArgs: [examId],
      orderBy: 'scanned_at DESC',
    );
    return maps.map((m) => ScanResult.fromMap(m)).toList();
  }

  Future<List<ScanResult>> getAllResults() async {
    final db = await database;
    final maps = await db.query('scan_results', orderBy: 'scanned_at DESC');
    return maps.map((m) => ScanResult.fromMap(m)).toList();
  }

  Future<int> deleteScanResult(int id) async {
    final db = await database;
    return await db.delete('scan_results', where: 'id = ?', whereArgs: [id]);
  }

  // ===================== STATS =====================

  Future<int> getResultCountForExam(int examId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM scan_results WHERE exam_id = ?',
      [examId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
