import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:provider/provider.dart';
import '../core/constants/app_theme.dart';
import '../models/exam.dart';

import '../models/student_answer.dart';
import '../models/scan_result.dart';
import '../providers/exam_provider.dart';

import '../services/image_processing_service.dart';
import '../services/ocr_service.dart';
import 'score_review_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isProcessing = false;
  bool _flashOn = false;
  Exam? _selectedExam;
  List<Exam> _examsWithKeys = [];
  final _imageService = ImageProcessingService();
  final _ocrService = OcrService();

  @override
  void initState() {
    super.initState();
    _initCamera();
    _loadExams();
  }

  Future<void> _loadExams() async {
    final provider = context.read<ExamProvider>();
    await provider.loadExams();
    final exams = await provider.getExamsWithAnswerKeys();
    if (mounted) {
      setState(() {
        _examsWithKeys = exams;
        if (exams.isNotEmpty) _selectedExam = exams.first;
      });
    }
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) return;

      _cameraController = CameraController(
        _cameras!.first,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (e) {
      debugPrint('Camera init error: $e');
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _ocrService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Scan Paper'),
        actions: [
          if (_isInitialized)
            IconButton(
              onPressed: _toggleFlash,
              icon: Icon(
                _flashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                color: _flashOn ? AppTheme.accent : Colors.white,
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Exam selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppTheme.primaryMid,
            child: Row(
              children: [
                const Icon(Icons.assignment_rounded,
                    color: AppTheme.accent, size: 20),
                const SizedBox(width: 8),
                const Text('Exam: ',
                    style: TextStyle(color: AppTheme.textSecondary)),
                Expanded(
                  child: _examsWithKeys.isEmpty
                      ? const Text(
                          'No exams with answer keys',
                          style: TextStyle(color: AppTheme.error),
                        )
                      : DropdownButton<Exam>(
                          value: _selectedExam,
                          isExpanded: true,
                          dropdownColor: AppTheme.surfaceLight,
                          style: const TextStyle(color: AppTheme.textPrimary),
                          underline: const SizedBox(),
                          items: _examsWithKeys.map((exam) {
                            return DropdownMenuItem(
                              value: exam,
                              child: Text(
                                '${exam.name} (${exam.questionCount}Q)',
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (exam) =>
                              setState(() => _selectedExam = exam),
                        ),
                ),
              ],
            ),
          ),



          // Camera preview
          Expanded(
            child: _isInitialized
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      CameraPreview(_cameraController!),
                      // Guide overlay
                      CustomPaint(
                        painter: _ScanGuidePainter(),
                      ),
                      // Processing overlay
                      if (_isProcessing)
                        Container(
                          color: Colors.black54,
                          child: const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(
                                  color: AppTheme.accent,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Processing...',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  )
                : const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.accent,
                    ),
                  ),
          ),

          // Capture button
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            color: Colors.black,
            child: Center(
              child: GestureDetector(
                onTap: (_isProcessing || _selectedExam == null)
                    ? null
                    : _captureAndProcess,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (_isProcessing || _selectedExam == null)
                        ? Colors.grey
                        : AppTheme.accent,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accent.withValues(alpha: 0.4),
                        blurRadius: 20,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.camera_alt_rounded,
                    size: 32,
                    color: (_isProcessing || _selectedExam == null)
                        ? Colors.white54
                        : AppTheme.primaryDark,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null) return;
    _flashOn = !_flashOn;
    await _cameraController!
        .setFlashMode(_flashOn ? FlashMode.torch : FlashMode.off);
    setState(() {});
  }

  Future<void> _captureAndProcess() async {
    if (_selectedExam == null || _cameraController == null) return;



    // Capture provider references before async gap
    final examProvider = context.read<ExamProvider>();

    setState(() => _isProcessing = true);

    try {
      // Capture image
      final xFile = await _cameraController!.takePicture();
      final imagePath = xFile.path;

      // Decode image
      final bytes = await File(imagePath).readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) throw Exception('Failed to decode image');

      // Get answer key
      final answerKeyEntries =
          await examProvider.getAnswerKey(_selectedExam!.id!);

      // Process image — detect bubbles + student number from OMR grid
      final processingResult =
          _imageService.processImage(image, _selectedExam!.questionCount);

      // OCR — extract student name only (number comes from OMR bubbles)
      final studentInfo = await _ocrService.extractStudentInfo(imagePath);

      // Compare with answer key
      final studentAnswers = <StudentAnswer>[];
      int correctCount = 0;

      for (int i = 0; i < _selectedExam!.questionCount; i++) {
        final detected = i < processingResult.answers.length
            ? processingResult.answers[i]
            : null;
        final correct = i < answerKeyEntries.length
            ? answerKeyEntries[i].correctOption
            : '';

        final isCorrect = detected != null &&
            correct.isNotEmpty &&
            detected == correct;

        if (isCorrect) correctCount++;

        studentAnswers.add(StudentAnswer(
          questionNumber: i + 1,
          selectedOption: detected,
          correctOption: correct,
          isCorrect: isCorrect,
        ));
      }


      // Warn if markers not found
      if (!processingResult.markersFound && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠ Hizalama işaretleri bulunamadı. Sonuçlar hatalı olabilir.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }

      // Build result — student number from OMR, name from OCR
      final decodedNumber = processingResult.studentNumber.replaceAll('_', '');
      final result = ScanResult(
        examId: _selectedExam!.id!,
        studentName: studentInfo['name'] ?? '',
        studentNumber: decodedNumber,
        totalScore: correctCount,
        totalQuestions: _selectedExam!.questionCount,
        answers: studentAnswers,
        imagePath: imagePath,
      );

      if (!mounted) return;

      // Navigate to score review
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ScoreReviewScreen(
            result: result,
            exam: _selectedExam!,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error processing: $e')),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }


}

/// Paints guide overlay on camera preview
class _ScanGuidePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.accent.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Draw corner guides
    const cornerLen = 30.0;
    final margin = size.width * 0.08;

    final rect = Rect.fromLTRB(
      margin,
      size.height * 0.05,
      size.width - margin,
      size.height * 0.95,
    );

    // Top-left
    canvas.drawLine(rect.topLeft, Offset(rect.left + cornerLen, rect.top), paint);
    canvas.drawLine(rect.topLeft, Offset(rect.left, rect.top + cornerLen), paint);

    // Top-right
    canvas.drawLine(rect.topRight, Offset(rect.right - cornerLen, rect.top), paint);
    canvas.drawLine(rect.topRight, Offset(rect.right, rect.top + cornerLen), paint);

    // Bottom-left
    canvas.drawLine(rect.bottomLeft, Offset(rect.left + cornerLen, rect.bottom), paint);
    canvas.drawLine(rect.bottomLeft, Offset(rect.left, rect.bottom - cornerLen), paint);

    // Bottom-right
    canvas.drawLine(rect.bottomRight, Offset(rect.right - cornerLen, rect.bottom), paint);
    canvas.drawLine(rect.bottomRight, Offset(rect.right, rect.bottom - cornerLen), paint);

    // Guide text
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'Align sheet within frame',
        style: TextStyle(
          color: Colors.white70,
          fontSize: 14,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size.width - textPainter.width) / 2,
        rect.top - 30,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
