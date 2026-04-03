import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_theme.dart';
import '../models/exam.dart';
import '../models/scan_result.dart';
import '../providers/results_provider.dart';

class ScoreReviewScreen extends StatefulWidget {
  final ScanResult result;
  final Exam exam;

  const ScoreReviewScreen({
    super.key,
    required this.result,
    required this.exam,
  });

  @override
  State<ScoreReviewScreen> createState() => _ScoreReviewScreenState();
}

class _ScoreReviewScreenState extends State<ScoreReviewScreen> {
  late TextEditingController _nameController;
  late TextEditingController _numberController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.result.studentName);
    _numberController =
        TextEditingController(text: widget.result.studentNumber);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _numberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final percentage = result.percentage;
    final Color scoreColor;
    if (percentage >= 80) {
      scoreColor = AppTheme.success;
    } else if (percentage >= 50) {
      scoreColor = AppTheme.warning;
    } else {
      scoreColor = AppTheme.error;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Score Review'),
        actions: [
          TextButton.icon(
            onPressed: _saving ? null : _saveResult,
            icon: const Icon(Icons.save_rounded),
            label: const Text('Save'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Score card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    scoreColor.withValues(alpha: 0.2),
                    AppTheme.cardGradientEnd,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: scoreColor.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    '${result.totalScore}/${result.totalQuestions}',
                    style: TextStyle(
                      fontSize: 52,
                      fontWeight: FontWeight.bold,
                      color: scoreColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      color: scoreColor.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.exam.name,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Student info (editable)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Student Information',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Student Name',
                      prefixIcon: Icon(Icons.person_outline),
                      helperText: 'Edit if OCR result is incorrect',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _numberController,
                    decoration: const InputDecoration(
                      labelText: 'Student Number',
                      prefixIcon: Icon(Icons.badge_outlined),
                      helperText: 'Edit if OCR result is incorrect',
                    ),
                    keyboardType: TextInputType.text,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Answer breakdown
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Answer Breakdown',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      Row(
                        children: [
                          _legendDot(AppTheme.success, 'Correct'),
                          const SizedBox(width: 12),
                          _legendDot(AppTheme.error, 'Wrong'),
                          const SizedBox(width: 12),
                          _legendDot(Colors.grey, 'Empty'),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...result.answers.map(_buildAnswerRow),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _saveResult,
                icon: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_rounded),
                label: Text(_saving ? 'Saving...' : 'Save Result'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  Widget _buildAnswerRow(answer) {
    final Color statusColor;
    final IconData statusIcon;

    if (answer.selectedOption == null) {
      statusColor = Colors.grey;
      statusIcon = Icons.remove_circle_outline;
    } else if (answer.isCorrect) {
      statusColor = AppTheme.success;
      statusIcon = Icons.check_circle_rounded;
    } else {
      statusColor = AppTheme.error;
      statusIcon = Icons.cancel_rounded;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '${answer.questionNumber}.',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Icon(statusIcon, size: 18, color: statusColor),
          const SizedBox(width: 8),
          Text(
            'Answer: ${answer.selectedOption ?? '-'}',
            style: TextStyle(
              fontSize: 13,
              color: statusColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          if (!answer.isCorrect && answer.correctOption.isNotEmpty)
            Text(
              '(Correct: ${answer.correctOption})',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _saveResult() async {
    setState(() => _saving = true);

    try {
      final updatedResult = widget.result.copyWith(
        studentName: _nameController.text.trim(),
        studentNumber: _numberController.text.trim(),
      );

      final provider = context.read<ResultsProvider>();
      await provider.saveResult(updatedResult);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Result saved successfully!'),
          backgroundColor: AppTheme.success,
        ),
      );

      // Pop back to home
      Navigator.popUntil(context, (route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
