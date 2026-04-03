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
        build: (context) => _buildSheet(context, questionCount),
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildSheet(pw.Context context, int questionCount) {
    return pw.Stack(
      children: [
        // White background
        pw.Positioned.fill(
          child: pw.Container(color: PdfColors.white),
        ),

        // 4 Corner alignment markers
        ..._buildCornerMarkers(),

        // Name field
        _buildNameField(),

        // Student ID section
        ..._buildStudentIdSection(),

        // Answers section
        ..._buildAnswersSection(questionCount),
      ],
    );
  }

  /// Name field — simple bordered box at the top
  pw.Widget _buildNameField() {
    return pw.Positioned(
      left: 30 * PdfPageFormat.mm,
      right: 30 * PdfPageFormat.mm,
      top: AppConstants.nameFieldY * PdfPageFormat.mm,
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(width: 1.0, color: PdfColors.black),
        ),
        child: pw.Row(
          children: [
            pw.Text('Name:  ',
                style: pw.TextStyle(
                    fontSize: 10, fontWeight: pw.FontWeight.bold)),
            pw.Expanded(
              child: pw.Container(
                height: 14,
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                      bottom: pw.BorderSide(
                          width: 0.5, color: PdfColors.grey400)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 4 corner markers
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
          left: (pos.$1 - 2) * PdfPageFormat.mm,
          top: (pos.$2 - 2) * PdfPageFormat.mm,
          child: pw.Container(
            width: (AppConstants.markerSizeMm + 4) * PdfPageFormat.mm,
            height: (AppConstants.markerSizeMm + 4) * PdfPageFormat.mm,
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

  /// Student ID section: label + 9-column x 10-row bubble grid
  List<pw.Widget> _buildStudentIdSection() {
    final widgets = <pw.Widget>[];
    final bubbleDia = AppConstants.studentNoBubbleDiameterMm * PdfPageFormat.mm;
    final bubbleR = bubbleDia / 2;

    // Section label
    widgets.add(
      pw.Positioned(
        left: 30 * PdfPageFormat.mm,
        top: AppConstants.studentNoLabelY * PdfPageFormat.mm,
        child: pw.Text(
          'Student ID:',
          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
        ),
      ),
    );

    // Grid border
    final gridLeft = AppConstants.studentNoGridStartXMm - 6;
    final gridTop = AppConstants.studentNoGridStartYMm - 7;
    final gridWidth =
        (AppConstants.studentNoDigits - 1) * AppConstants.studentNoColSpacingMm + 12;
    final gridHeight =
        (AppConstants.studentNoRowCount - 1) * AppConstants.studentNoRowSpacingMm + 10;

    widgets.add(
      pw.Positioned(
        left: gridLeft * PdfPageFormat.mm,
        top: gridTop * PdfPageFormat.mm,
        child: pw.Container(
          width: gridWidth * PdfPageFormat.mm,
          height: gridHeight * PdfPageFormat.mm,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(width: 0.6, color: PdfColors.grey500),
          ),
        ),
      ),
    );

    // Column headers (1-9)
    for (int col = 0; col < AppConstants.studentNoDigits; col++) {
      final x = (AppConstants.studentNoGridStartXMm +
              col * AppConstants.studentNoColSpacingMm) *
          PdfPageFormat.mm;

      widgets.add(
        pw.Positioned(
          left: x - 3,
          top: (AppConstants.studentNoGridStartYMm - 5.5) * PdfPageFormat.mm,
          child: pw.SizedBox(
            width: 8,
            child: pw.Center(
              child: pw.Text(
                '${col + 1}',
                style: pw.TextStyle(
                  fontSize: 6,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey600,
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Row labels (0-9)
    for (int row = 0; row < AppConstants.studentNoRowCount; row++) {
      final y = (AppConstants.studentNoGridStartYMm +
              row * AppConstants.studentNoRowSpacingMm) *
          PdfPageFormat.mm;

      widgets.add(
        pw.Positioned(
          left: (AppConstants.studentNoGridStartXMm - 5.5) * PdfPageFormat.mm,
          top: y - 3.5,
          child: pw.SizedBox(
            width: 8,
            child: pw.Center(
              child: pw.Text(
                '$row',
                style: pw.TextStyle(
                  fontSize: 6,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey600,
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Bubbles: 9 columns × 10 rows
    for (int col = 0; col < AppConstants.studentNoDigits; col++) {
      final x = (AppConstants.studentNoGridStartXMm +
              col * AppConstants.studentNoColSpacingMm) *
          PdfPageFormat.mm;

      for (int row = 0; row < AppConstants.studentNoRowCount; row++) {
        final y = (AppConstants.studentNoGridStartYMm +
                row * AppConstants.studentNoRowSpacingMm) *
            PdfPageFormat.mm;

        widgets.add(
          pw.Positioned(
            left: x - bubbleR,
            top: y - bubbleR,
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

    return widgets;
  }

  /// Answers section: label + bubble grid
  List<pw.Widget> _buildAnswersSection(int questionCount) {
    final widgets = <pw.Widget>[];
    final bubbleDia = AppConstants.bubbleDiameterMm * PdfPageFormat.mm;
    final bubbleR = bubbleDia / 2;

    // Section label
    widgets.add(
      pw.Positioned(
        left: 30 * PdfPageFormat.mm,
        top: (AppConstants.gridStartYMm - 10) * PdfPageFormat.mm,
        child: pw.Text(
          'Answers',
          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
        ),
      ),
    );

    // Grid border
    final gridLeft = AppConstants.questionNumberXMm - 4;
    final gridTop = AppConstants.gridStartYMm - 6;
    final gridWidth = (AppConstants.optionCount - 1) * AppConstants.bubbleHSpacingMm +
        AppConstants.gridStartXMm - AppConstants.questionNumberXMm + 10;
    final gridHeight = (questionCount - 1) * AppConstants.bubbleVSpacingMm + 10;

    widgets.add(
      pw.Positioned(
        left: gridLeft * PdfPageFormat.mm,
        top: gridTop * PdfPageFormat.mm,
        child: pw.Container(
          width: gridWidth * PdfPageFormat.mm,
          height: gridHeight * PdfPageFormat.mm,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(width: 0.6, color: PdfColors.grey500),
          ),
        ),
      ),
    );

    // Option labels (A, B, C, D, E)
    for (int opt = 0; opt < AppConstants.optionCount; opt++) {
      final x =
          (AppConstants.gridStartXMm + opt * AppConstants.bubbleHSpacingMm) *
              PdfPageFormat.mm;

      widgets.add(
        pw.Positioned(
          left: x - 3.5,
          top: (AppConstants.gridStartYMm - 5) * PdfPageFormat.mm,
          child: pw.SizedBox(
            width: 9,
            child: pw.Center(
              child: pw.Text(
                AppConstants.options[opt],
                style: pw.TextStyle(
                  fontSize: 7.5,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey700,
                ),
              ),
            ),
          ),
        ),
      );
    }

    for (int q = 0; q < questionCount; q++) {
      final y =
          (AppConstants.gridStartYMm + q * AppConstants.bubbleVSpacingMm) *
              PdfPageFormat.mm;

      // Alternating row shading
      if (q % 2 == 0) {
        widgets.add(
          pw.Positioned(
            left: (gridLeft + 0.3) * PdfPageFormat.mm,
            top: y - bubbleR - 1,
            child: pw.Container(
              width: (gridWidth - 0.6) * PdfPageFormat.mm,
              height: bubbleDia + 2,
              color: const PdfColor(0.96, 0.96, 0.96), // very light grey
            ),
          ),
        );
      }

      // Question number
      widgets.add(
        pw.Positioned(
          left: AppConstants.questionNumberXMm * PdfPageFormat.mm,
          top: y - 4.5,
          child: pw.Text(
            '${q + 1}',
            style: pw.TextStyle(
              fontSize: 8.5,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
      );

      // Bubbles (A-E)
      for (int opt = 0; opt < AppConstants.optionCount; opt++) {
        final x =
            (AppConstants.gridStartXMm + opt * AppConstants.bubbleHSpacingMm) *
                PdfPageFormat.mm;

        widgets.add(
          pw.Positioned(
            left: x - bubbleR,
            top: y - bubbleR,
            child: pw.Container(
              width: bubbleDia,
              height: bubbleDia,
              decoration: pw.BoxDecoration(
                shape: pw.BoxShape.circle,
                border: pw.Border.all(width: 1.1, color: PdfColors.grey800),
              ),
            ),
          ),
        );
      }
    }

    return widgets;
  }
}
