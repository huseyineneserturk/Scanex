import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_constants.dart';
import '../core/constants/app_theme.dart';
import '../providers/exam_provider.dart';
import '../services/pdf_generator_service.dart';

class GenerateSheetScreen extends StatefulWidget {
  const GenerateSheetScreen({super.key});

  @override
  State<GenerateSheetScreen> createState() => _GenerateSheetScreenState();
}

class _GenerateSheetScreenState extends State<GenerateSheetScreen> {
  final _nameController = TextEditingController();
  double _questionCount = 20;
  bool _generating = false;
  final _pdfService = PdfGeneratorService();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate Answer Sheet'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.accent.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: AppTheme.accent,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Create an exam and generate its printable optical answer sheet. '
                      'The compact form uses a ZipGrade-style layout with auto-scaling columns.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Exam Name
            Text(
              'Exam Name',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                hintText: 'e.g., Math Quiz 3, Biology Midterm',
                prefixIcon: Icon(Icons.edit_note_rounded),
              ),
              textCapitalization: TextCapitalization.words,
            ),

            const SizedBox(height: 28),

            // Question count selector
            Text(
              'Number of Questions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),

            // Big number display
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 20,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.cardGradientStart, AppTheme.cardGradientEnd],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Text(
                      '${_questionCount.round()}',
                      style: const TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accent,
                      ),
                    ),
                    Text(
                      '${AppConstants.getColumnCount(_questionCount.round())} column${AppConstants.getColumnCount(_questionCount.round()) > 1 ? 's' : ''}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Slider
            Slider(
              value: _questionCount,
              min: AppConstants.minQuestions.toDouble(),
              max: AppConstants.maxQuestions.toDouble(),
              divisions: (AppConstants.maxQuestions - AppConstants.minQuestions) ~/
                  AppConstants.questionStep,
              label: '${_questionCount.round()} questions',
              onChanged: (value) {
                setState(() {
                  _questionCount = value;
                });
              },
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${AppConstants.minQuestions}',
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
                Text(
                  '${AppConstants.maxQuestions}',
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Quick select chips
            Wrap(
              spacing: 8,
              children: [10, 20, 30, 50, 100].map((count) {
                final selected = _questionCount.round() == count;
                return ChoiceChip(
                  label: Text('$count'),
                  selected: selected,
                  selectedColor: AppTheme.accent,
                  backgroundColor: AppTheme.surfaceLight,
                  labelStyle: TextStyle(
                    color: selected ? AppTheme.primaryDark : AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  onSelected: (_) {
                    setState(() {
                      _questionCount = count.toDouble();
                    });
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 32),

            // Sheet preview info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _infoRow(Icons.grid_view_rounded, 'Options per question', 'A, B, C, D, E'),
                  const Divider(height: 20, color: AppTheme.surface),
                  _infoRow(Icons.crop_square_rounded, 'Alignment markers', '4 corners'),
                  const Divider(height: 20, color: AppTheme.surface),
                  _infoRow(Icons.straighten_rounded, 'Layout', 'Compact (centered on A4)'),
                  const Divider(height: 20, color: AppTheme.surface),
                  _infoRow(Icons.person_outline, 'Fields', 'Name + Number (handwritten)'),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Generate button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _generating ? null : _generatePdf,
                icon: _generating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.picture_as_pdf_rounded),
                label: Text(_generating ? 'Generating...' : 'Create Exam & Generate PDF'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.accent),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: const TextStyle(color: AppTheme.textSecondary)),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Future<void> _generatePdf() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an exam name')),
      );
      return;
    }

    final examProvider = context.read<ExamProvider>();

    setState(() => _generating = true);

    try {
      // Create the exam in the database
      final exam = await examProvider.createExam(name, _questionCount.round());

      // Generate PDF with exam name on it
      final bytes = await _pdfService.generateSheet(
        _questionCount.round(),
        examName: name,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Exam "$name" created! Now define the answer key.'),
          backgroundColor: AppTheme.success,
          duration: const Duration(seconds: 3),
        ),
      );

      // Show print/share dialog
      await Printing.layoutPdf(
        onLayout: (_) => bytes,
        name: 'Scanex_${name.replaceAll(' ', '_')}_${exam.questionCount}Q.pdf',
      );

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }
}
