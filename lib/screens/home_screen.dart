import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_theme.dart';
import '../models/exam.dart';
import '../providers/exam_provider.dart';

import '../services/pdf_generator_service.dart';
import 'generate_sheet_screen.dart';
import 'answer_key_screen.dart';
import 'scan_screen.dart';
import 'results_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Reload exams when returning to home
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExamProvider>().loadExams();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 28),
              _buildFreeBanner(context),
              const SizedBox(height: 28),
              _buildSectionTitle('Quick Actions'),
              const SizedBox(height: 16),
              _buildActionGrid(context),
              const SizedBox(height: 28),
              _buildSectionTitle('Your Exams'),
              const SizedBox(height: 12),
              _buildExamsList(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.accent, AppTheme.accentLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.document_scanner_rounded,
            size: 32,
            color: AppTheme.primaryDark,
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Scanex',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
            ),
            Text(
              'Optical Form Reader & Auto Grader',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFreeBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.cardGradientStart,
            AppTheme.cardGradientEnd,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.accent.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.all_inclusive_rounded,
              color: AppTheme.accent,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Free & Unlimited',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Unlimited scanning for everyone!',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: AppTheme.success.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              '∞',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.success,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimary,
      ),
    );
  }

  Widget _buildActionGrid(BuildContext context) {
    final actions = [
      _ActionItem(
        icon: Icons.description_outlined,
        title: 'Create Exam',
        subtitle: 'New exam + answer sheet',
        gradient: [const Color(0xFF1A6B4A), const Color(0xFF0D3B28)],
        onTap: () async {
          final provider = context.read<ExamProvider>();
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const GenerateSheetScreen()),
          );
          if (mounted) provider.loadExams();
        },
      ),
      _ActionItem(
        icon: Icons.key_rounded,
        title: 'Answer Key',
        subtitle: 'Define correct answers',
        gradient: [const Color(0xFF4A1A6B), const Color(0xFF280D3B)],
        onTap: () async {
          final provider = context.read<ExamProvider>();
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AnswerKeyScreen()),
          );
          if (mounted) provider.loadExams();
        },
      ),
      _ActionItem(
        icon: Icons.camera_alt_rounded,
        title: 'Scan Paper',
        subtitle: 'Grade an answer sheet',
        gradient: [const Color(0xFF1A4A6B), const Color(0xFF0D283B)],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ScanScreen()),
        ),
      ),
      _ActionItem(
        icon: Icons.analytics_rounded,
        title: 'Results',
        subtitle: 'View & export scores',
        gradient: [const Color(0xFF6B4A1A), const Color(0xFF3B280D)],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ResultsScreen()),
        ),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.0,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) => _buildActionCard(context, actions[index]),
    );
  }

  Widget _buildActionCard(BuildContext context, _ActionItem item) {
    return GestureDetector(
      onTap: item.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: item.gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: item.gradient[0].withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(item.icon, size: 28, color: Colors.white),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExamsList(BuildContext context) {
    return Consumer<ExamProvider>(
      builder: (context, provider, _) {
        if (provider.exams.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Column(
                children: [
                  Icon(
                    Icons.folder_open_rounded,
                    size: 40,
                    color: AppTheme.textSecondary,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'No exams yet',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Tap "Create Exam" to get started',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: provider.exams.map((exam) {
            return _buildExamCard(context, exam, provider);
          }).toList(),
        );
      },
    );
  }

  Widget _buildExamCard(BuildContext context, Exam exam, ExamProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.accent.withValues(alpha: 0.1),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.assignment_rounded,
            color: AppTheme.accent,
          ),
        ),
        title: Text(
          exam.name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        subtitle: Text(
          '${exam.questionCount} questions  •  ${_formatDate(exam.createdAt)}',
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded, color: AppTheme.textSecondary),
          itemBuilder: (ctx) => [
            const PopupMenuItem(
              value: 'pdf',
              child: ListTile(
                leading: Icon(Icons.picture_as_pdf_rounded),
                title: Text('Download / View PDF'),
                dense: true,
              ),
            ),
            const PopupMenuItem(
              value: 'key',
              child: ListTile(
                leading: Icon(Icons.key_rounded),
                title: Text('Edit Answer Key'),
                dense: true,
              ),
            ),
            const PopupMenuItem(
              value: 'results',
              child: ListTile(
                leading: Icon(Icons.analytics_rounded),
                title: Text('View Results'),
                dense: true,
              ),
            ),
            const PopupMenuItem(
              value: 'scan',
              child: ListTile(
                leading: Icon(Icons.camera_alt_rounded),
                title: Text('Scan Paper'),
                dense: true,
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete_rounded, color: AppTheme.error),
                title: Text('Delete', style: TextStyle(color: AppTheme.error)),
                dense: true,
              ),
            ),
          ],
          onSelected: (value) => _handleExamAction(context, value, exam, provider),
        ),
      ),
    );
  }

  void _handleExamAction(
    BuildContext context,
    String action,
    Exam exam,
    ExamProvider provider,
  ) async {
    switch (action) {
      case 'pdf':
        _downloadPdf(context, exam);
        break;
      case 'key':
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AnswerKeyScreen()),
        );
        if (mounted) provider.loadExams();
        break;
      case 'results':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ResultsScreen()),
        );
        break;
      case 'scan':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ScanScreen()),
        );
        break;
      case 'delete':
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Exam?'),
            content: Text(
              'Delete "${exam.name}" and all its results? This cannot be undone.',
            ),
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
        if (confirm == true) {
          await provider.deleteExam(exam.id!);
        }
        break;
    }
  }

  Future<void> _downloadPdf(BuildContext context, Exam exam) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppTheme.accent),
                SizedBox(height: 16),
                Text('Generating PDF...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final pdfService = PdfGeneratorService();
      final bytes = await pdfService.generateSheet(
        exam.questionCount,
        examName: exam.name,
      );

      if (!mounted) return;
      navigator.pop(); // Close loading dialog

      // Open print/share dialog
      await Printing.layoutPdf(
        onLayout: (_) => bytes,
        name: 'Scanex_${exam.name.replaceAll(' ', '_')}_${exam.questionCount}Q.pdf',
      );
    } catch (e) {
      if (!mounted) return;
      navigator.pop(); // Close loading dialog
      messenger.showSnackBar(
        SnackBar(content: Text('Error generating PDF: $e')),
      );
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }
}

class _ActionItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final VoidCallback onTap;

  _ActionItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });
}
