import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_theme.dart';
import '../models/exam.dart';
import '../providers/exam_provider.dart';
import '../providers/results_provider.dart';
import '../services/export_service.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  final _exportService = ExportService();
  Exam? _selectedExam;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final examProvider = context.read<ExamProvider>();
    final resultsProvider = context.read<ResultsProvider>();
    await examProvider.loadExams();
    if (examProvider.exams.isNotEmpty) {
      _selectedExam = examProvider.exams.first;
      await resultsProvider.loadResultsForExam(_selectedExam!.id!);
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final examProvider = context.watch<ExamProvider>();
    final resultsProvider = context.watch<ResultsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Results'),
        actions: [
          if (_selectedExam != null && resultsProvider.results.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.file_download_outlined),
              onSelected: _export,
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'pdf',
                  child: ListTile(
                    leading: Icon(Icons.picture_as_pdf_rounded,
                        color: Colors.red),
                    title: Text('Export as PDF'),
                  ),
                ),
                const PopupMenuItem(
                  value: 'xlsx',
                  child: ListTile(
                    leading: Icon(Icons.table_chart_rounded,
                        color: Colors.green),
                    title: Text('Export as Excel'),
                  ),
                ),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          // Exam selector
          if (examProvider.exams.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              color: AppTheme.primaryMid,
              child: DropdownButtonFormField<Exam>(
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
                onChanged: (exam) async {
                  if (exam == null) return;
                  setState(() => _selectedExam = exam);
                  await context
                      .read<ResultsProvider>()
                      .loadResultsForExam(exam.id!);
                },
              ),
            ),

          // Export loading
          if (_exporting)
            const LinearProgressIndicator(color: AppTheme.accent),

          // Results list
          Expanded(
            child: resultsProvider.loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.accent),
                  )
                : resultsProvider.results.isEmpty
                    ? _buildEmptyState()
                    : _buildResultsList(resultsProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inbox_rounded,
            size: 64,
            color: AppTheme.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'No results yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Scan answer sheets to see results here',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList(ResultsProvider provider) {
    final results = provider.results;

    // Summary at top
    final avg = results.isNotEmpty
        ? results.map((r) => r.percentage).reduce((a, b) => a + b) /
            results.length
        : 0.0;

    return Column(
      children: [
        // Summary card
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.cardGradientStart, AppTheme.cardGradientEnd],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statItem('Students', '${results.length}'),
              _statItem('Average', '${avg.toStringAsFixed(1)}%'),
              _statItem(
                'Highest',
                '${results.map((r) => r.percentage).reduce((a, b) => a > b ? a : b).toStringAsFixed(1)}%',
              ),
            ],
          ),
        ),

        // List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: results.length,
            itemBuilder: (context, index) {
              final r = results[index];
              final pct = r.percentage;
              final Color color;
              if (pct >= 80) {
                color = AppTheme.success;
              } else if (pct >= 50) {
                color = AppTheme.warning;
              } else {
                color = AppTheme.error;
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: color.withValues(alpha: 0.15),
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    r.studentName.isEmpty ? 'Unknown Student' : r.studentName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    r.studentNumber.isEmpty
                        ? r.scannedAt.toString().substring(0, 16)
                        : 'No: ${r.studentNumber}',
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${r.totalScore}/${r.totalQuestions}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      Text(
                        '${pct.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 12,
                          color: color.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                  onLongPress: () => _confirmDelete(r.id!),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppTheme.accent,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Future<void> _export(String format) async {
    if (_selectedExam == null) return;

    setState(() => _exporting = true);
    try {
      final results = context.read<ResultsProvider>().results;
      if (format == 'pdf') {
        await _exportService.exportAsPdf(_selectedExam!, results);
      } else {
        await _exportService.exportAsExcel(_selectedExam!, results);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export error: $e')),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _confirmDelete(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Result?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await context.read<ResultsProvider>().deleteResult(id);
    }
  }
}
