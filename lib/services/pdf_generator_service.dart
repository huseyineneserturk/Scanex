import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../core/constants/app_constants.dart';

class PdfGeneratorService {
  Future<Uint8List> generateSheet(int questionCount, {String? examName}) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(0),
        build: (context) => _buildSheet(context, questionCount, examName),
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildSheet(pw.Context context, int questionCount, String? examName) {
    return pw.Stack(
      children: [
        // White background
        pw.Positioned.fill(
          child: pw.Container(color: PdfColors.white),
        ),

        // Compact area border (light grey)
        _buildCompactAreaBorder(),

        // 4 Corner alignment markers (around compact area)
        ..._buildCornerMarkers(),

        // Exam name at very top of compact area
        if (examName != null && examName.isNotEmpty) _buildExamTitle(examName),

        // Name field (handwritten)
        _buildNameField(),

        // Number field (handwritten)
        _buildNumberField(),

        // Answers section
        ..._buildAnswersSection(questionCount),
      ],
    );
  }

  /// Light border around the compact answer area
  pw.Widget _buildCompactAreaBorder() {
    return pw.Positioned(
      left: AppConstants.compactLeftMm * PdfPageFormat.mm,
      top: AppConstants.compactTopMm * PdfPageFormat.mm,
      child: pw.Container(
        width: AppConstants.compactWidthMm * PdfPageFormat.mm,
        height: AppConstants.compactHeightMm * PdfPageFormat.mm,
        decoration: pw.BoxDecoration(
          border: pw.Border.all(width: 0.5, color: PdfColors.grey300),
        ),
      ),
    );
  }

  /// Exam title at the top of the compact area
  pw.Widget _buildExamTitle(String examName) {
    return pw.Positioned(
      left: AppConstants.innerLeftMm * PdfPageFormat.mm,
      right: (AppConstants.pageWidthMm - AppConstants.innerRightMm) * PdfPageFormat.mm,
      top: (AppConstants.compactTopMm + AppConstants.markerSizeMm + AppConstants.markerPaddingMm - 2) * PdfPageFormat.mm,
      child: pw.Center(
        child: pw.Text(
          examName,
          style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600),
        ),
      ),
    );
  }

  /// Name field — bordered box with label
  pw.Widget _buildNameField() {
    return pw.Positioned(
      left: AppConstants.innerLeftMm * PdfPageFormat.mm,
      right: (AppConstants.pageWidthMm - AppConstants.innerRightMm) * PdfPageFormat.mm,
      top: AppConstants.nameFieldY * PdfPageFormat.mm,
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(width: 0.8, color: PdfColors.black),
        ),
        child: pw.Row(
          children: [
            pw.Text('Name:  ',
                style: pw.TextStyle(
                    fontSize: 9, fontWeight: pw.FontWeight.bold)),
            pw.Expanded(
              child: pw.Container(
                height: 12,
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                      bottom: pw.BorderSide(
                          width: 0.4, color: PdfColors.grey400)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Number field — bordered box with label
  pw.Widget _buildNumberField() {
    return pw.Positioned(
      left: AppConstants.innerLeftMm * PdfPageFormat.mm,
      right: (AppConstants.pageWidthMm - AppConstants.innerRightMm) * PdfPageFormat.mm,
      top: AppConstants.numberFieldY * PdfPageFormat.mm,
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(width: 0.8, color: PdfColors.black),
        ),
        child: pw.Row(
          children: [
            pw.Text('No:  ',
                style: pw.TextStyle(
                    fontSize: 9, fontWeight: pw.FontWeight.bold)),
            pw.Expanded(
              child: pw.Container(
                height: 12,
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                      bottom: pw.BorderSide(
                          width: 0.4, color: PdfColors.grey400)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 4 corner markers around the compact area
  List<pw.Widget> _buildCornerMarkers() {
    final size = AppConstants.markerSizeMm * PdfPageFormat.mm;

    final positions = [
      (AppConstants.markerTLX, AppConstants.markerTLY),
      (AppConstants.markerTRX, AppConstants.markerTRY),
      (AppConstants.markerBLX, AppConstants.markerBLY),
      (AppConstants.markerBRX, AppConstants.markerBRY),
    ];

    final widgets = <pw.Widget>[];

    for (final pos in positions) {
      // White halo
      widgets.add(
        pw.Positioned(
          left: (pos.$1 - 1.5) * PdfPageFormat.mm,
          top: (pos.$2 - 1.5) * PdfPageFormat.mm,
          child: pw.Container(
            width: (AppConstants.markerSizeMm + 3) * PdfPageFormat.mm,
            height: (AppConstants.markerSizeMm + 3) * PdfPageFormat.mm,
            color: PdfColors.white,
          ),
        ),
      );

      // Black marker
      widgets.add(
        pw.Positioned(
          left: pos.$1 * PdfPageFormat.mm,
          top: pos.$2 * PdfPageFormat.mm,
          child: pw.Container(
            width: size,
            height: size,
            color: PdfColors.black,
          ),
        ),
      );
    }

    return widgets;
  }

  /// Answers section: multi-column bubble grid
  List<pw.Widget> _buildAnswersSection(int questionCount) {
    final widgets = <pw.Widget>[];
    final bubbleDia = AppConstants.bubbleDiameterMm * PdfPageFormat.mm;
    final bubbleR = bubbleDia / 2;
    final columnCount = AppConstants.getColumnCount(questionCount);
    final questionsPerColumn = (questionCount / columnCount).ceil();

    // Section label
    widgets.add(
      pw.Positioned(
        left: AppConstants.innerLeftMm * PdfPageFormat.mm,
        top: (AppConstants.gridTopMm - 5) * PdfPageFormat.mm,
        child: pw.Text(
          'Answers',
          style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
        ),
      ),
    );

    // Build each column
    for (int col = 0; col < columnCount; col++) {
      final startQ = col * questionsPerColumn;
      final endQ = (startQ + questionsPerColumn).clamp(0, questionCount);
      final qCount = endQ - startQ;

      if (qCount <= 0) continue;

      // Column header (option labels A-E)
      for (int opt = 0; opt < AppConstants.optionCount; opt++) {
        final x = AppConstants.getBubbleStartX(startQ, questionCount) +
            opt * AppConstants.bubbleHSpacingMm;

        widgets.add(
          pw.Positioned(
            left: (x - 1.5) * PdfPageFormat.mm,
            top: (AppConstants.gridTopMm - 4) * PdfPageFormat.mm,
            child: pw.SizedBox(
              width: 6,
              child: pw.Center(
                child: pw.Text(
                  AppConstants.options[opt],
                  style: pw.TextStyle(
                    fontSize: 6,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey700,
                  ),
                ),
              ),
            ),
          ),
        );
      }

      // Grid border for this column
      final gridLeft = AppConstants.getQuestionNumberX(startQ, questionCount) - 2;
      final gridTop = AppConstants.gridTopMm - 3;
      final gridWidth = AppConstants.questionLabelWidthMm +
          (AppConstants.optionCount - 1) * AppConstants.bubbleHSpacingMm +
          AppConstants.bubbleDiameterMm + 4;
      final gridHeight = (qCount - 1) * AppConstants.bubbleVSpacingMm +
          AppConstants.bubbleDiameterMm + 4;

      widgets.add(
        pw.Positioned(
          left: gridLeft * PdfPageFormat.mm,
          top: gridTop * PdfPageFormat.mm,
          child: pw.Container(
            width: gridWidth * PdfPageFormat.mm,
            height: gridHeight * PdfPageFormat.mm,
            decoration: pw.BoxDecoration(
              border: pw.Border.all(width: 0.5, color: PdfColors.grey400),
            ),
          ),
        ),
      );

      // Questions in this column
      for (int i = startQ; i < endQ; i++) {
        final y = AppConstants.getQuestionY(i, questionCount);
        final qNumX = AppConstants.getQuestionNumberX(i, questionCount);
        final bubbleX = AppConstants.getBubbleStartX(i, questionCount);
        final localRow = i - startQ;

        // Alternating row shading
        if (localRow % 2 == 0) {
          widgets.add(
            pw.Positioned(
              left: (gridLeft + 0.25) * PdfPageFormat.mm,
              top: (y - AppConstants.bubbleRadiusMm - 0.5) * PdfPageFormat.mm,
              child: pw.Container(
                width: (gridWidth - 0.5) * PdfPageFormat.mm,
                height: (AppConstants.bubbleDiameterMm + 1) * PdfPageFormat.mm,
                color: const PdfColor(0.96, 0.96, 0.96),
              ),
            ),
          );
        }

        // Question number
        widgets.add(
          pw.Positioned(
            left: qNumX * PdfPageFormat.mm,
            top: (y - 3) * PdfPageFormat.mm,
            child: pw.Text(
              '${i + 1}',
              style: pw.TextStyle(
                fontSize: 7,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        );

        // Bubbles (A-E)
        for (int opt = 0; opt < AppConstants.optionCount; opt++) {
          final bx = (bubbleX + opt * AppConstants.bubbleHSpacingMm) *
              PdfPageFormat.mm;
          final by = y * PdfPageFormat.mm;

          widgets.add(
            pw.Positioned(
              left: bx - bubbleR,
              top: by - bubbleR,
              child: pw.Container(
                width: bubbleDia,
                height: bubbleDia,
                decoration: pw.BoxDecoration(
                  shape: pw.BoxShape.circle,
                  border: pw.Border.all(width: 0.9, color: PdfColors.grey800),
                ),
              ),
            ),
          );
        }
      }
    }

    return widgets;
  }
}
