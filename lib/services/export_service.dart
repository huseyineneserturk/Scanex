import 'dart:io';
import 'package:excel/excel.dart' as xl;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/exam.dart';
import '../models/scan_result.dart';

class ExportService {
  /// Export results as XLSX and share.
  Future<void> exportAsExcel(Exam exam, List<ScanResult> results) async {
    final excel = xl.Excel.createExcel();
    final sheet = excel['Results'];

    // Header row
    sheet.appendRow([
      xl.TextCellValue('Student Name'),
      xl.TextCellValue('Student Number'),
      xl.TextCellValue('Score'),
      xl.TextCellValue('Total Questions'),
      xl.TextCellValue('Percentage'),
      xl.TextCellValue('Date'),
    ]);

    // Data rows
    for (final result in results) {
      sheet.appendRow([
        xl.TextCellValue(result.studentName.isEmpty ? 'Unknown' : result.studentName),
        xl.TextCellValue(result.studentNumber.isEmpty ? '-' : result.studentNumber),
        xl.IntCellValue(result.totalScore),
        xl.IntCellValue(result.totalQuestions),
        xl.TextCellValue('${result.percentage.toStringAsFixed(1)}%'),
        xl.TextCellValue(result.scannedAt.toString().substring(0, 16)),
      ]);
    }

    // Remove default sheet if exists
    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    final bytes = excel.save();
    if (bytes == null) return;

    final dir = await getTemporaryDirectory();
    final fileName = '${exam.name.replaceAll(' ', '_')}_results.xlsx';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: '${exam.name} - Scan Results',
      ),
    );
  }

  /// Export results as PDF and share.
  Future<void> exportAsPdf(Exam exam, List<ScanResult> results) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'SCANEX — Results Report',
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Exam: ${exam.name}  |  Questions: ${exam.questionCount}  |  Students: ${results.length}',
              style: const pw.TextStyle(fontSize: 11),
            ),
            pw.Divider(),
          ],
        ),
        build: (context) => [
          pw.TableHelper.fromTextArray(
            headers: ['#', 'Name', 'Student No', 'Score', '%', 'Date'],
            data: results.asMap().entries.map((entry) {
              final i = entry.key;
              final r = entry.value;
              return [
                '${i + 1}',
                r.studentName.isEmpty ? 'Unknown' : r.studentName,
                r.studentNumber.isEmpty ? '-' : r.studentNumber,
                '${r.totalScore}/${r.totalQuestions}',
                '${r.percentage.toStringAsFixed(1)}%',
                r.scannedAt.toString().substring(0, 10),
              ];
            }).toList(),
            cellStyle: const pw.TextStyle(fontSize: 10),
            headerStyle: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColors.blueGrey800,
            ),
            cellAlignment: pw.Alignment.centerLeft,
            headerAlignment: pw.Alignment.centerLeft,
          ),
          pw.SizedBox(height: 20),
          _buildSummary(results),
        ],
      ),
    );

    final bytes = await pdf.save();
    final dir = await getTemporaryDirectory();
    final fileName = '${exam.name.replaceAll(' ', '_')}_report.pdf';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: '${exam.name} - Results Report',
      ),
    );
  }

  pw.Widget _buildSummary(List<ScanResult> results) {
    if (results.isEmpty) return pw.SizedBox();

    final avg = results.map((r) => r.percentage).reduce((a, b) => a + b) /
        results.length;
    final highest = results
        .map((r) => r.percentage)
        .reduce((a, b) => a > b ? a : b);
    final lowest = results
        .map((r) => r.percentage)
        .reduce((a, b) => a < b ? a : b);

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Summary',
              style:
                  pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Text('Average Score: ${avg.toStringAsFixed(1)}%'),
          pw.Text('Highest Score: ${highest.toStringAsFixed(1)}%'),
          pw.Text('Lowest Score: ${lowest.toStringAsFixed(1)}%'),
          pw.Text('Total Students: ${results.length}'),
        ],
      ),
    );
  }
}
