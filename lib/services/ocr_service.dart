import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

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

  /// Extract student name and number from the top portion of an image.
  /// Returns a map with 'name' and 'number' keys.
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
          // Get text after the label
          final parts = block.text.split(RegExp(r'[:\-]'));
          if (parts.length > 1) {
            name = parts.sublist(1).join(' ').trim();
          }
        }

        // Look for student number field
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
