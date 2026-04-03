import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import '../core/constants/app_constants.dart';

/// Core optical mark recognition engine.
/// Processes a captured image to detect 4 corner alignment markers,
/// perform perspective correction, and read filled bubbles.
class ImageProcessingService {
  /// Process a captured image and return detected answers + student number.
  ProcessingResult processImage(img.Image image, int questionCount) {
    // Step 1: Resize for performance (work at ~1500px width for better accuracy)
    final workImage = _resizeForProcessing(image);

    // Step 2: Convert to grayscale
    final gray = img.grayscale(workImage);

    // Step 3: Find 4 corner alignment markers
    final markers = _findCornerMarkers(gray);

    img.Image aligned;
    if (markers != null) {
      // Step 4: Perspective correction using 4 corner markers
      aligned = _perspectiveCorrect(gray, markers);
    } else {
      // Fallback: use the grayscale image as-is
      debugPrint('Scanex: Markers not found, using raw image');
      aligned = gray;
    }

    // Step 5: Read student number from OMR grid
    final studentNumber = _readStudentNumber(aligned);

    // Step 6: Read answer bubbles
    final answers = _readBubbles(aligned, questionCount);

    return ProcessingResult(
      answers: answers,
      studentNumber: studentNumber,
      markersFound: markers != null,
    );
  }

  /// Resize image to a manageable width while maintaining aspect ratio.
  img.Image _resizeForProcessing(img.Image image) {
    const targetWidth = 1500;
    if (image.width <= targetWidth) return image;
    return img.copyResize(image, width: targetWidth);
  }

  /// Find 4 corner markers (black squares) in the image.
  /// Returns [topLeft, topRight, bottomLeft, bottomRight] centers.
  List<Point<int>>? _findCornerMarkers(img.Image gray) {
    // Use global Otsu threshold for more reliable binarization
    final threshold = _otsuThreshold(gray);
    final binary = _binarize(gray, threshold);

    // Find black square candidates
    final candidates = <_MarkerCandidate>[];
    final visited = List.generate(
      binary.height,
      (_) => List.filled(binary.width, false),
    );

    for (int y = 0; y < binary.height; y++) {
      for (int x = 0; x < binary.width; x++) {
        if (visited[y][x]) continue;
        final pixel = binary.getPixel(x, y);
        final lum = pixel.luminance.toInt();

        if (lum < 50) {
          final blob = _floodFill(binary, x, y, visited);
          if (blob.isNotEmpty) {
            final candidate = _analyzeBlob(blob, binary.width, binary.height);
            if (candidate != null) {
              candidates.add(candidate);
            }
          }
        }
      }
    }

    if (candidates.length < 4) {
      debugPrint('Scanex: Found only ${candidates.length} marker candidates');
      return null;
    }

    return _matchCornerMarkers(candidates, binary.width, binary.height);
  }

  /// Otsu's method for automatic threshold calculation
  int _otsuThreshold(img.Image gray) {
    // Build histogram
    final histogram = List.filled(256, 0);
    final totalPixels = gray.width * gray.height;

    for (int y = 0; y < gray.height; y++) {
      for (int x = 0; x < gray.width; x++) {
        final lum = gray.getPixel(x, y).luminance.toInt();
        histogram[lum]++;
      }
    }

    double sumTotal = 0;
    for (int i = 0; i < 256; i++) {
      sumTotal += i * histogram[i];
    }

    double sumBg = 0;
    int weightBg = 0;
    double maxVariance = 0;
    int bestThreshold = 0;

    for (int t = 0; t < 256; t++) {
      weightBg += histogram[t];
      if (weightBg == 0) continue;
      final weightFg = totalPixels - weightBg;
      if (weightFg == 0) break;

      sumBg += t * histogram[t];
      final meanBg = sumBg / weightBg;
      final meanFg = (sumTotal - sumBg) / weightFg;

      final variance =
          weightBg * weightFg * (meanBg - meanFg) * (meanBg - meanFg);
      if (variance > maxVariance) {
        maxVariance = variance;
        bestThreshold = t;
      }
    }

    return bestThreshold;
  }

  /// Simple global binarization
  img.Image _binarize(img.Image gray, int threshold) {
    final result = img.Image(width: gray.width, height: gray.height);
    for (int y = 0; y < gray.height; y++) {
      for (int x = 0; x < gray.width; x++) {
        final val = gray.getPixel(x, y).luminance.toInt();
        if (val < threshold) {
          result.setPixelRgb(x, y, 0, 0, 0);
        } else {
          result.setPixelRgb(x, y, 255, 255, 255);
        }
      }
    }
    return result;
  }

  /// Flood fill to extract connected component (blob)
  List<Point<int>> _floodFill(
    img.Image binary,
    int startX,
    int startY,
    List<List<bool>> visited,
  ) {
    final blob = <Point<int>>[];
    final queue = <Point<int>>[Point(startX, startY)];
    visited[startY][startX] = true;

    while (queue.isNotEmpty) {
      final p = queue.removeAt(0);

      // Limit blob size to prevent runaway fills
      if (blob.length > 8000) return blob;

      final pixel = binary.getPixel(p.x, p.y);
      if (pixel.luminance.toInt() < 50) {
        blob.add(p);

        // 4-connected neighbors
        for (final d in [
          Point(1, 0),
          Point(-1, 0),
          Point(0, 1),
          Point(0, -1),
        ]) {
          final nx = p.x + d.x;
          final ny = p.y + d.y;
          if (nx >= 0 &&
              nx < binary.width &&
              ny >= 0 &&
              ny < binary.height &&
              !visited[ny][nx]) {
            visited[ny][nx] = true;
            queue.add(Point(nx, ny));
          }
        }
      }
    }
    return blob;
  }

  /// Analyze a blob to determine if it looks like a square marker
  _MarkerCandidate? _analyzeBlob(
    List<Point<int>> blob,
    int imageWidth,
    int imageHeight,
  ) {
    if (blob.length < 100) return null; // too small

    int minX = imageWidth, maxX = 0, minY = imageHeight, maxY = 0;
    for (final p in blob) {
      if (p.x < minX) minX = p.x;
      if (p.x > maxX) maxX = p.x;
      if (p.y < minY) minY = p.y;
      if (p.y > maxY) maxY = p.y;
    }

    final w = maxX - minX + 1;
    final h = maxY - minY + 1;
    final area = blob.length;
    final boundingArea = w * h;

    // Check squareness: aspect ratio close to 1
    final aspect = w / h;
    if (aspect < 0.65 || aspect > 1.55) return null;

    // Check fill ratio: marker should be >70% filled
    final fillRatio = area / boundingArea;
    if (fillRatio < 0.70) return null;

    // Check size: should be reasonable for a marker
    // Markers are 10mm on 210mm wide sheet, roughly 4.8% of width
    final expectedMinSize = imageWidth * 0.02;
    final expectedMaxSize = imageWidth * 0.10;
    if (w < expectedMinSize || w > expectedMaxSize) return null;

    final centerX = (minX + maxX) ~/ 2;
    final centerY = (minY + maxY) ~/ 2;

    return _MarkerCandidate(
      center: Point(centerX, centerY),
      width: w,
      height: h,
      area: area,
    );
  }

  /// Match detected candidates to the 4 corner marker positions
  List<Point<int>>? _matchCornerMarkers(
    List<_MarkerCandidate> candidates,
    int imageWidth,
    int imageHeight,
  ) {
    // Sort by area descending — corner markers should be the largest squares
    candidates.sort((a, b) => b.area.compareTo(a.area));

    // Take top candidates
    final top = candidates.take(12).toList();

    final midX = imageWidth / 2;
    final midY = imageHeight / 2;

    // Find the best candidate for each corner
    _MarkerCandidate? topLeft, topRight, bottomLeft, bottomRight;
    double tlScore = double.infinity;
    double trScore = double.infinity;
    double blScore = double.infinity;
    double brScore = double.infinity;

    for (final c in top) {
      // Top-left: small x, small y
      final tlDist = sqrt(
          pow(c.center.x.toDouble(), 2) + pow(c.center.y.toDouble(), 2));
      if (c.center.x < midX && c.center.y < midY && tlDist < tlScore) {
        tlScore = tlDist;
        topLeft = c;
      }

      // Top-right: large x, small y
      final trDist = sqrt(pow((imageWidth - c.center.x).toDouble(), 2) +
          pow(c.center.y.toDouble(), 2));
      if (c.center.x >= midX && c.center.y < midY && trDist < trScore) {
        trScore = trDist;
        topRight = c;
      }

      // Bottom-left: small x, large y
      final blDist = sqrt(pow(c.center.x.toDouble(), 2) +
          pow((imageHeight - c.center.y).toDouble(), 2));
      if (c.center.x < midX && c.center.y >= midY && blDist < blScore) {
        blScore = blDist;
        bottomLeft = c;
      }

      // Bottom-right: large x, large y
      final brDist = sqrt(
          pow((imageWidth - c.center.x).toDouble(), 2) +
              pow((imageHeight - c.center.y).toDouble(), 2));
      if (c.center.x >= midX && c.center.y >= midY && brDist < brScore) {
        brScore = brDist;
        bottomRight = c;
      }
    }

    if (topLeft == null ||
        topRight == null ||
        bottomLeft == null ||
        bottomRight == null) {
      debugPrint('Scanex: Could not identify all 4 corners');
      return null;
    }

    debugPrint(
        'Scanex: Markers found - TL:${topLeft.center}, TR:${topRight.center}, BL:${bottomLeft.center}, BR:${bottomRight.center}');

    return [
      topLeft.center,
      topRight.center,
      bottomLeft.center,
      bottomRight.center,
    ];
  }

  /// Perspective correction using 4 corner markers.
  /// Maps from marker positions to known sheet coordinates.
  img.Image _perspectiveCorrect(
    img.Image gray,
    List<Point<int>> markers,
  ) {
    // markers: [TL, TR, BL, BR]
    final srcTL = markers[0];
    final srcTR = markers[1];
    final srcBL = markers[2];
    final srcBR = markers[3];

    // Target dimensions — use high resolution for better accuracy
    // The target image represents the full A4 sheet
    // We map marker centers to their known mm positions
    const targetW = 1050; // ~5 px/mm
    final targetH =
        (targetW * AppConstants.sheetHeightMm / AppConstants.sheetWidthMm)
            .round();

    // Scale factor for pixel coordinates
    final pxPerMm = targetW / AppConstants.sheetWidthMm;

    // The markers' known center positions in the target image
    final dstTLX = AppConstants.markerTLCenterX * pxPerMm;
    final dstTLY = AppConstants.markerTLCenterY * pxPerMm;
    final dstTRX = AppConstants.markerTRCenterX * pxPerMm;
    final dstTRY = AppConstants.markerTRCenterY * pxPerMm;
    final dstBLX = AppConstants.markerBLCenterX * pxPerMm;
    final dstBLY = AppConstants.markerBLCenterY * pxPerMm;
    final dstBRX = AppConstants.markerBRCenterX * pxPerMm;
    final dstBRY = AppConstants.markerBRCenterY * pxPerMm;

    final result = img.Image(width: targetW, height: targetH);

    // For each pixel on the target, find the corresponding source pixel
    // using bilinear interpolation of the 4 corner correspondences
    for (int y = 0; y < targetH; y++) {
      for (int x = 0; x < targetW; x++) {
        // Compute normalized coordinates based on marker positions
        // Use inverse bilinear mapping
        final u = _inverseBilinearU(
          x.toDouble(),
          y.toDouble(),
          dstTLX, dstTLY,
          dstTRX, dstTRY,
          dstBLX, dstBLY,
          dstBRX, dstBRY,
        );
        final v = _inverseBilinearV(
          x.toDouble(),
          y.toDouble(),
          dstTLX, dstTLY,
          dstTRX, dstTRY,
          dstBLX, dstBLY,
          dstBRX, dstBRY,
        );

        // Map to source coordinates
        final srcX = ((1 - u) * (1 - v) * srcTL.x +
                u * (1 - v) * srcTR.x +
                (1 - u) * v * srcBL.x +
                u * v * srcBR.x)
            .round();
        final srcY = ((1 - u) * (1 - v) * srcTL.y +
                u * (1 - v) * srcTR.y +
                (1 - u) * v * srcBL.y +
                u * v * srcBR.y)
            .round();

        if (srcX >= 0 &&
            srcX < gray.width &&
            srcY >= 0 &&
            srcY < gray.height) {
          result.setPixel(x, y, gray.getPixel(srcX, srcY));
        }
      }
    }

    return result;
  }

  /// Compute u coordinate for inverse bilinear mapping
  double _inverseBilinearU(
    double px, double py,
    double tlx, double tly,
    double trx, double try_,
    double blx, double bly,
    double brx, double bry,
  ) {
    // Compute u using left and right edge interpolation
    final leftEdgeX = tlx + (blx - tlx) * ((py - tly) / (bly - tly)).clamp(0, 1);
    final rightEdgeX = trx + (brx - trx) * ((py - try_) / (bry - try_)).clamp(0, 1);
    return ((px - leftEdgeX) / (rightEdgeX - leftEdgeX)).clamp(0.0, 1.0);
  }

  /// Compute v coordinate for inverse bilinear mapping
  double _inverseBilinearV(
    double px, double py,
    double tlx, double tly,
    double trx, double try_,
    double blx, double bly,
    double brx, double bry,
  ) {
    final topEdgeY = tly + (try_ - tly) * ((px - tlx) / (trx - tlx)).clamp(0, 1);
    final bottomEdgeY = bly + (bry - bly) * ((px - blx) / (brx - blx)).clamp(0, 1);
    return ((py - topEdgeY) / (bottomEdgeY - topEdgeY)).clamp(0.0, 1.0);
  }

  /// Read bubble marks from the aligned image.
  /// Uses both relative (vs row mean) and absolute thresholds.
  List<String?> _readBubbles(img.Image aligned, int questionCount) {
    final answers = <String?>[];
    final w = aligned.width;
    final h = aligned.height;

    // Convert sheet coordinates (mm) to pixel coordinates
    final scaleX = w / AppConstants.sheetWidthMm;
    final scaleY = h / AppConstants.sheetHeightMm;

    // Sample size for each bubble (in pixels)
    final sampleRadius = max(3, (AppConstants.bubbleRadiusMm * scaleX * 0.55).round());

    // First, measure the global background intensity (empty area)
    final bgIntensity = _measureBackgroundIntensity(aligned, scaleX, scaleY);
    debugPrint('Scanex: Background intensity: $bgIntensity');

    for (int q = 0; q < questionCount; q++) {
      final bubbleY =
          ((AppConstants.gridStartYMm + q * AppConstants.bubbleVSpacingMm) *
                  scaleY)
              .round();

      final intensities = <double>[];

      for (int opt = 0; opt < AppConstants.optionCount; opt++) {
        final bubbleX =
            ((AppConstants.gridStartXMm + opt * AppConstants.bubbleHSpacingMm) *
                    scaleX)
                .round();

        final intensity =
            _sampleRegionIntensity(aligned, bubbleX, bubbleY, sampleRadius);
        intensities.add(intensity);
      }

      // Find the darkest bubble
      double minIntensity = 255;
      int darkestOption = -1;
      for (int i = 0; i < intensities.length; i++) {
        if (intensities[i] < minIntensity) {
          minIntensity = intensities[i];
          darkestOption = i;
        }
      }

      // Decision logic with multiple checks:
      final meanIntensity =
          intensities.reduce((a, b) => a + b) / intensities.length;

      // 1. The filled bubble must be significantly darker than the row mean
      final relativelyDark = minIntensity < meanIntensity * 0.70;

      // 2. The filled bubble must be significantly darker than the background
      final absolutelyDark = minIntensity < bgIntensity * 0.55;

      // 3. There must be a clear gap between the darkest and second darkest
      final sorted = List<double>.from(intensities)..sort();
      final gap = sorted.length > 1 ? sorted[1] - sorted[0] : 999;
      final clearGap = gap > 15; // at least 15 intensity units gap

      // Accept if at least 2 of 3 conditions are met AND absolute dark
      final conditions = [relativelyDark, absolutelyDark, clearGap];
      final conditionsMet = conditions.where((c) => c).length;

      if (darkestOption >= 0 && conditionsMet >= 2 && (absolutelyDark || minIntensity < 120)) {
        answers.add(AppConstants.options[darkestOption]);
        debugPrint(
            'Scanex: Q${q + 1} → ${AppConstants.options[darkestOption]} (intensity: ${minIntensity.toStringAsFixed(1)}, mean: ${meanIntensity.toStringAsFixed(1)}, bg: $bgIntensity, gap: ${gap.toStringAsFixed(1)})');
      } else {
        answers.add(null);
        debugPrint(
            'Scanex: Q${q + 1} → EMPTY (min: ${minIntensity.toStringAsFixed(1)}, mean: ${meanIntensity.toStringAsFixed(1)}, bg: $bgIntensity, gap: ${gap.toStringAsFixed(1)})');
      }
    }

    return answers;
  }

  /// Read the 9-digit student number from the OMR bubble grid.
  String _readStudentNumber(img.Image aligned) {
    final w = aligned.width;
    final h = aligned.height;
    final scaleX = w / AppConstants.sheetWidthMm;
    final scaleY = h / AppConstants.sheetHeightMm;
    final sampleRadius =
        max(2, (AppConstants.studentNoBubbleRadiusMm * scaleX * 0.5).round());

    final bgIntensity = _measureBackgroundIntensity(aligned, scaleX, scaleY);
    final digits = <String>[];

    for (int col = 0; col < AppConstants.studentNoDigits; col++) {
      final bubbleX = ((AppConstants.studentNoGridStartXMm +
                  col * AppConstants.studentNoColSpacingMm) *
              scaleX)
          .round();

      double minIntensity = 255;
      int darkestRow = -1;
      final intensities = <double>[];

      for (int row = 0; row < AppConstants.studentNoRowCount; row++) {
        final bubbleY = ((AppConstants.studentNoGridStartYMm +
                    row * AppConstants.studentNoRowSpacingMm) *
                scaleY)
            .round();

        final intensity =
            _sampleRegionIntensity(aligned, bubbleX, bubbleY, sampleRadius);
        intensities.add(intensity);

        if (intensity < minIntensity) {
          minIntensity = intensity;
          darkestRow = row;
        }
      }

      final meanIntensity =
          intensities.reduce((a, b) => a + b) / intensities.length;
      final relativelyDark = minIntensity < meanIntensity * 0.70;
      final absolutelyDark = minIntensity < bgIntensity * 0.55;

      final sorted = List<double>.from(intensities)..sort();
      final gap = sorted.length > 1 ? sorted[1] - sorted[0] : 999;
      final clearGap = gap > 12;

      final conditions = [relativelyDark, absolutelyDark, clearGap];
      final conditionsMet = conditions.where((c) => c).length;

      if (darkestRow >= 0 && conditionsMet >= 2 && (absolutelyDark || minIntensity < 120)) {
        digits.add('$darkestRow');
      } else {
        digits.add('_');
      }
    }

    return digits.join();
  }

  /// Measure background intensity by sampling known-empty areas of the sheet
  double _measureBackgroundIntensity(
      img.Image aligned, double scaleX, double scaleY) {
    // Sample from areas that should definitely be white/empty
    // Use the area between markers and the grid
    final samples = <double>[];

    // Sample a few points in the header area (should be white paper)
    final samplePoints = [
      (100.0, 30.0), // middle of sheet, header area
      (150.0, 30.0),
      (60.0, 80.0), // between name and number grid
      (160.0, 80.0),
    ];

    for (final pt in samplePoints) {
      final px = (pt.$1 * scaleX).round().clamp(0, aligned.width - 1);
      final py = (pt.$2 * scaleY).round().clamp(0, aligned.height - 1);
      final intensity = _sampleRegionIntensity(aligned, px, py, 5);
      samples.add(intensity);
    }

    if (samples.isEmpty) return 220;

    // Return the median for robustness
    samples.sort();
    return samples[samples.length ~/ 2];
  }

  /// Sample the average pixel intensity in a circular-ish region.
  /// Lower = darker (filled bubble).
  double _sampleRegionIntensity(
    img.Image image,
    int cx,
    int cy,
    int radius,
  ) {
    double sum = 0;
    int count = 0;
    final r2 = radius * radius;

    for (int y = max(0, cy - radius);
        y < min(image.height, cy + radius + 1);
        y++) {
      for (int x = max(0, cx - radius);
          x < min(image.width, cx + radius + 1);
          x++) {
        // Use circular sampling for more accurate results
        final dx = x - cx;
        final dy = y - cy;
        if (dx * dx + dy * dy <= r2) {
          sum += image.getPixel(x, y).luminance.toInt();
          count++;
        }
      }
    }

    return count > 0 ? sum / count : 255;
  }
}

/// Result of image processing: detected answers + student number.
class ProcessingResult {
  final List<String?> answers;
  final String studentNumber;
  final bool markersFound;

  ProcessingResult({
    required this.answers,
    required this.studentNumber,
    this.markersFound = false,
  });
}

class _MarkerCandidate {
  final Point<int> center;
  final int width;
  final int height;
  final int area;

  _MarkerCandidate({
    required this.center,
    required this.width,
    required this.height,
    required this.area,
  });
}
