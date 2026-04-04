/// Sheet layout constants shared between PDF generator and image scanner.
/// All measurements in millimeters (mm) for PDF, converted to pixels at scan time.
///
/// The sheet uses a COMPACT answer area centered on A4 paper.
/// 4 corner markers surround the compact area for perspective correction.
/// All bubble positions are relative to the compact area coordinate system.
class AppConstants {
  // --- Full Page Dimensions (A4 in mm) ---
  static const double pageWidthMm = 210.0;
  static const double pageHeightMm = 297.0;

  // --- Compact Answer Area ---
  // The compact area is centered on the A4 page.
  // Width: 140mm, Height: depends on question count but max ~200mm
  static const double compactWidthMm = 150.0;
  static const double compactHeightMm = 210.0;
  static const double compactLeftMm = (pageWidthMm - compactWidthMm) / 2; // 30mm
  static const double compactTopMm = (pageHeightMm - compactHeightMm) / 2; // 43.5mm

  // --- Corner Marker Specification (relative to compact area) ---
  static const double markerSizeMm = 7.0;
  static const double markerPaddingMm = 2.0; // padding inside compact area

  // Marker positions (top-left corner of each marker square) — absolute on A4
  static const double markerTLX = compactLeftMm + markerPaddingMm;
  static const double markerTLY = compactTopMm + markerPaddingMm;
  static const double markerTRX = compactLeftMm + compactWidthMm - markerPaddingMm - markerSizeMm;
  static const double markerTRY = compactTopMm + markerPaddingMm;
  static const double markerBLX = compactLeftMm + markerPaddingMm;
  static const double markerBLY = compactTopMm + compactHeightMm - markerPaddingMm - markerSizeMm;
  static const double markerBRX = compactLeftMm + compactWidthMm - markerPaddingMm - markerSizeMm;
  static const double markerBRY = compactTopMm + compactHeightMm - markerPaddingMm - markerSizeMm;

  // Marker centers (used for perspective correction reference)
  static const double markerTLCenterX = markerTLX + markerSizeMm / 2;
  static const double markerTLCenterY = markerTLY + markerSizeMm / 2;
  static const double markerTRCenterX = markerTRX + markerSizeMm / 2;
  static const double markerTRCenterY = markerTRY + markerSizeMm / 2;
  static const double markerBLCenterX = markerBLX + markerSizeMm / 2;
  static const double markerBLCenterY = markerBLY + markerSizeMm / 2;
  static const double markerBRCenterX = markerBRX + markerSizeMm / 2;
  static const double markerBRCenterY = markerBRY + markerSizeMm / 2;

  // --- Compact Area internal coordinates ---
  // All relative to the compact area's top-left corner
  static const double innerLeftMm = compactLeftMm + markerSizeMm + markerPaddingMm + 4; // ~43mm from page left
  static const double innerRightMm = compactLeftMm + compactWidthMm - markerSizeMm - markerPaddingMm - 4;
  static const double innerTopMm = compactTopMm + markerSizeMm + markerPaddingMm + 2; // after markers

  // --- Name Field (handwritten) ---
  static const double nameFieldY = innerTopMm; // ~54.5mm from page top
  static const double nameFieldHeight = 10.0;

  // --- Number Field (handwritten) ---
  static const double numberFieldY = nameFieldY + nameFieldHeight + 3;
  static const double numberFieldHeight = 10.0;

  // --- Answer Bubble Grid ---
  // Grid starts below the number field
  static const double gridTopMm = numberFieldY + numberFieldHeight + 6;

  // Bubble dimensions
  static const double bubbleDiameterMm = 4.5;
  static const double bubbleRadiusMm = bubbleDiameterMm / 2;
  static const double bubbleHSpacingMm = 9.0; // space between option columns
  static const double bubbleVSpacingMm = 5.5; // space between question rows

  // Question number label width
  static const double questionLabelWidthMm = 8.0;

  // Column spacing (gap between multi-column groups)
  static const double columnGapMm = 6.0;

  // --- Options ---
  static const List<String> options = ['A', 'B', 'C', 'D', 'E'];
  static const int optionCount = 5;

  // --- Question Limits ---
  static const int minQuestions = 5;
  static const int maxQuestions = 100;
  static const int questionStep = 5;

  // --- Multi-column Layout ---
  /// Calculate number of columns based on question count
  static int getColumnCount(int questionCount) {
    if (questionCount <= 25) return 1;
    if (questionCount <= 50) return 2;
    if (questionCount <= 75) return 3;
    return 4;
  }

  /// Calculate single column width in mm
  static double getColumnWidthMm(int columnCount) {
    final availableWidth = innerRightMm - innerLeftMm;
    return (availableWidth - (columnCount - 1) * columnGapMm) / columnCount;
  }

  /// Calculate the X position (absolute on A4) for a question's number label
  static double getQuestionNumberX(int questionIndex, int questionCount) {
    final columnCount = getColumnCount(questionCount);
    final questionsPerColumn = (questionCount / columnCount).ceil();
    final column = questionIndex ~/ questionsPerColumn;
    final columnWidth = getColumnWidthMm(columnCount);
    return innerLeftMm + column * (columnWidth + columnGapMm);
  }

  /// Calculate the X position (absolute on A4) for the first bubble (option A)
  static double getBubbleStartX(int questionIndex, int questionCount) {
    return getQuestionNumberX(questionIndex, questionCount) + questionLabelWidthMm;
  }

  /// Calculate the Y position (absolute on A4) for a question row
  static double getQuestionY(int questionIndex, int questionCount) {
    final columnCount = getColumnCount(questionCount);
    final questionsPerColumn = (questionCount / columnCount).ceil();
    final row = questionIndex % questionsPerColumn;
    return gridTopMm + row * bubbleVSpacingMm;
  }

  // --- Compact area dimensions for perspective correction ---
  // The perspective correction maps to the compact area only
  static const double sheetWidthMm = compactWidthMm;
  static const double sheetHeightMm = compactHeightMm;

  // --- Name/Number crop regions (relative to compact area) ---
  // These are fractional positions within the perspective-corrected image
  static const double nameCropLeftFrac = 0.08;
  static const double nameCropRightFrac = 0.92;
  static const double nameCropTopMm = nameFieldY - compactTopMm;
  static const double nameCropBottomMm = nameFieldY - compactTopMm + nameFieldHeight;

  static const double numberCropLeftFrac = 0.08;
  static const double numberCropRightFrac = 0.92;
  static const double numberCropTopMm = numberFieldY - compactTopMm;
  static const double numberCropBottomMm = numberFieldY - compactTopMm + numberFieldHeight;

  // --- App Info ---
  static const String appName = 'Scanex';
  static const String appTagline = 'Optical Form Reader';
}
