import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';

/// On-device OCR service using Google ML Kit.
class OcrService {
  final TextRecognizer _textRecognizer = TextRecognizer();

  /// Extract text from an image file.
  /// Returns the recognized text or empty string on failure.
  Future<String> recognizeText(String imagePath) async {
    try {
      final inputImage = InputImage.fromFile(File(imagePath));
      final recognized = await _textRecognizer.processImage(inputImage);
      return recognized.text;
    } catch (e) {
      return '';
    }
  }

  /// Extract text from cropped image bytes (PNG).
  /// Saves bytes to a temp file, runs OCR, then deletes the temp file.
  Future<String> extractTextFromBytes(Uint8List imageBytes) async {
    try {
      final dir = await getTemporaryDirectory();
      final tempFile = File('${dir.path}/scanex_ocr_${DateTime.now().millisecondsSinceEpoch}.png');
      await tempFile.writeAsBytes(imageBytes);

      final inputImage = InputImage.fromFile(tempFile);
      final recognized = await _textRecognizer.processImage(inputImage);

      // Clean up temp file
      try { await tempFile.delete(); } catch (_) {}

      final text = recognized.text.trim();
      debugPrint('Scanex OCR result: "$text"');
      return text;
    } catch (e) {
      debugPrint('Scanex OCR error: $e');
      return '';
    }
  }

  /// Extract student name from cropped name region image bytes.
  /// Cleans up OCR artifacts like "Name:" labels.
  Future<String> extractName(Uint8List? imageBytes) async {
    if (imageBytes == null) return '';

    final rawText = await extractTextFromBytes(imageBytes);

    // Clean up: remove "Name:" or "Name" prefix if OCR picks up the label
    String cleaned = rawText;
    final labelPatterns = [
      RegExp(r'^name\s*[:\-]\s*', caseSensitive: false),
      RegExp(r'^ad\s*[:\-]\s*', caseSensitive: false),
      RegExp(r'^isim\s*[:\-]\s*', caseSensitive: false),
    ];
    for (final pattern in labelPatterns) {
      cleaned = cleaned.replaceFirst(pattern, '');
    }

    return cleaned.trim();
  }

  /// Extract student number from cropped number region image bytes.
  /// Cleans up OCR artifacts like "No:" labels.
  Future<String> extractNumber(Uint8List? imageBytes) async {
    if (imageBytes == null) return '';

    final rawText = await extractTextFromBytes(imageBytes);

    // Clean up: remove "No:" or "Number:" prefix if OCR picks up the label
    String cleaned = rawText;
    final labelPatterns = [
      RegExp(r'^no\s*[:\-]\s*', caseSensitive: false),
      RegExp(r'^number\s*[:\-]\s*', caseSensitive: false),
      RegExp(r'^numara\s*[:\-]\s*', caseSensitive: false),
      RegExp(r'^#\s*', caseSensitive: false),
    ];
    for (final pattern in labelPatterns) {
      cleaned = cleaned.replaceFirst(pattern, '');
    }

    return cleaned.trim();
  }

  /// Legacy method: Extract student info from full image file.
  /// Now delegates to cropped region OCR when possible.
  Future<Map<String, String>> extractStudentInfo(String imagePath) async {
    try {
      final inputImage = InputImage.fromFile(File(imagePath));
      final recognized = await _textRecognizer.processImage(inputImage);

      String name = '';
      String number = '';

      for (final block in recognized.blocks) {
        final text = block.text.toLowerCase();

        // Look for name field
        if (text.contains('name') || text.contains('ad')) {
          final parts = block.text.split(RegExp(r'[:\-]'));
          if (parts.length > 1) {
            name = parts.sublist(1).join(' ').trim();
          }
        }

        // Look for number field
        if (text.contains('no') ||
            text.contains('number') ||
            text.contains('numara')) {
          final parts = block.text.split(RegExp(r'[:\-]'));
          if (parts.length > 1) {
            number = parts.sublist(1).join(' ').trim();
          }
        }
      }

      // If structured parsing failed, try line-by-line
      if (name.isEmpty && number.isEmpty) {
        final lines = recognized.text.split('\n');
        for (int i = 0; i < lines.length && i < 5; i++) {
          final line = lines[i].trim();
          if (line.isNotEmpty && name.isEmpty && !RegExp(r'^\d+$').hasMatch(line)) {
            name = line;
          } else if (line.isNotEmpty && number.isEmpty && RegExp(r'\d').hasMatch(line)) {
            number = line.replaceAll(RegExp(r'[^\d]'), '');
          }
        }
      }

      return {'name': name, 'number': number};
    } catch (e) {
      return {'name': '', 'number': ''};
    }
  }

  void dispose() {
    _textRecognizer.close();
  }
}
