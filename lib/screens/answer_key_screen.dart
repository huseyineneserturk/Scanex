import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_constants.dart';
import '../core/constants/app_theme.dart';
import '../models/exam.dart';
import '../providers/exam_provider.dart';

class AnswerKeyScreen extends StatefulWidget {
  const AnswerKeyScreen({super.key});

  @override
  State<AnswerKeyScreen> createState() => _AnswerKeyScreenState();
}

class _AnswerKeyScreenState extends State<AnswerKeyScreen> {
  late List<String?> _answers;
  bool _saving = false;
  Exam? _selectedExam;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _answers = List.filled(AppConstants.maxQuestions, null);
    _loadExams();
  }

  Future<void> _loadExams() async {
    final provider = context.read<ExamProvider>();
    await provider.loadExams();
    if (mounted) {
      setState(() {
        _loading = false;
        if (provider.exams.isNotEmpty) {
          _selectedExam = provider.exams.first;
          _loadExistingAnswerKey();
        }
      });
    }
  }

  Future<void> _loadExistingAnswerKey() async {
    if (_selectedExam == null) return;
    final provider = context.read<ExamProvider>();
    final existing = await provider.getAnswerKey(_selectedExam!.id!);

    setState(() {
      // Reset all answers
      _answers = List.filled(_selectedExam?.questionCount ?? AppConstants.maxQuestions, null);
      // Fill with existing data
      for (final entry in existing) {
        if (entry.questionNumber - 1 < _answers.length &&
            entry.correctOption.isNotEmpty) {
          _answers[entry.questionNumber - 1] = entry.correctOption;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final examProvider = context.watch<ExamProvider>();

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Answer Key')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (examProvider.exams.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Answer Key')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.assignment_outlined,
                  size: 64,
                  color: AppTheme.textSecondary.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No Exams Found',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Create an exam first by generating an answer sheet.',
                  style: TextStyle(color: AppTheme.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final count = _selectedExam?.questionCount ?? 20;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Answer Key'),
        actions: [
          TextButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_rounded),
            label: const Text('Save'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Header section
          Container(
            padding: const EdgeInsets.all(20),
            color: AppTheme.primaryMid,
            child: Column(
              children: [
                // Exam selector
                DropdownButtonFormField<Exam>(
                  value: _selectedExam,
                  decoration: const InputDecoration(
                    labelText: 'Select Exam',
                    prefixIcon: Icon(Icons.assignment_rounded),
                  ),
                  dropdownColor: AppTheme.surfaceLight,
                  items: examProvider.exams.map((exam) {
                    return DropdownMenuItem(
                      value: exam,
                      child: Text(
                        '${exam.name} (${exam.questionCount}Q)',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (exam) {
                    if (exam == null) return;
                    setState(() => _selectedExam = exam);
                    _loadExistingAnswerKey();
                  },
                ),

                // Progress
                const SizedBox(height: 12),
                _buildProgress(count),
              ],
            ),
          ),

          // Answer grid
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: count,
              itemBuilder: (context, index) =>
                  _buildQuestionRow(index),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgress(int count) {
    final answered =
        _answers.take(count).where((a) => a != null).length;
    final progress = count > 0 ? answered / count : 0.0;

    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: AppTheme.surface,
              valueColor: AlwaysStoppedAnimation<Color>(
                progress == 1.0 ? AppTheme.success : AppTheme.accent,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '$answered/$count',
          style: TextStyle(
            fontSize: 13,
            color: progress == 1.0 ? AppTheme.success : AppTheme.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionRow(int questionIndex) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          // Question number
          SizedBox(
            width: 40,
            child: Text(
              '${questionIndex + 1}.',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          // Option buttons
          ...AppConstants.options.map((option) {
            final selected = _answers[questionIndex] == option;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _answers[questionIndex] =
                        selected ? null : option;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppTheme.accent
                        : AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected
                          ? AppTheme.accent
                          : AppTheme.surface,
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      option,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: selected
                            ? AppTheme.primaryDark
                            : AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (_selectedExam == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an exam')),
      );
      return;
    }

    final count = _selectedExam!.questionCount;
    final answered =
        _answers.take(count).where((a) => a != null).length;
    final provider = context.read<ExamProvider>();

    if (answered < count) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Incomplete Answer Key'),
          content: Text(
            '$answered of $count answers defined. '
            'Questions without answers will be skipped during grading. '
            'Continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save Anyway'),
            ),
          ],
        ),
      );
      if (proceed != true) return;
    }

    setState(() => _saving = true);

    try {
      // Save answer key entries
      final definedAnswers = <String>[];
      for (int i = 0; i < count; i++) {
        definedAnswers.add(_answers[i] ?? '');
      }
      await provider.saveAnswerKey(_selectedExam!.id!, definedAnswers);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Answer key for "${_selectedExam!.name}" saved!'),
          backgroundColor: AppTheme.success,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
