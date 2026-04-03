/// Sheet layout constants shared between PDF generator and image scanner.
/// All measurements in millimeters (mm) for PDF, converted to pixels at scan time.
///
/// The sheet uses 4 corner markers for perspective correction.
/// Markers are positioned at exact corners with known offsets.
/// All bubble positions are relative to the marker coordinate system.
class AppConstants {
  // --- Sheet Dimensions (A4 in mm) ---
  static const double sheetWidthMm = 210.0;
  static const double sheetHeightMm = 297.0;

  // --- Corner Marker Specification ---
  static const double markerSizeMm = 10.0;
  static const double markerMarginMm = 10.0;

  // Marker positions (top-left corner of each marker square)
  static const double markerTLX = markerMarginMm;
  static const double markerTLY = markerMarginMm;
  static const double markerTRX = sheetWidthMm - markerMarginMm - markerSizeMm;
  static const double markerTRY = markerMarginMm;
  static const double markerBLX = markerMarginMm;
  static const double markerBLY = sheetHeightMm - markerMarginMm - markerSizeMm;
  static const double markerBRX = sheetWidthMm - markerMarginMm - markerSizeMm;
  static const double markerBRY = sheetHeightMm - markerMarginMm - markerSizeMm;

  // Marker centers (used for perspective correction reference)
  static const double markerTLCenterX = markerTLX + markerSizeMm / 2;
  static const double markerTLCenterY = markerTLY + markerSizeMm / 2;
  static const double markerTRCenterX = markerTRX + markerSizeMm / 2;
  static const double markerTRCenterY = markerTRY + markerSizeMm / 2;
  static const double markerBLCenterX = markerBLX + markerSizeMm / 2;
  static const double markerBLCenterY = markerBLY + markerSizeMm / 2;
  static const double markerBRCenterX = markerBRX + markerSizeMm / 2;
  static const double markerBRCenterY = markerBRY + markerSizeMm / 2;

  // --- Name Field ---
  static const double nameFieldY = 28.0; // top of name field

  // --- Student Number OMR Grid ---
  // Grid: 9 columns x 10 rows, centered horizontally
  // Total grid width = 8 * 10mm = 80mm → centered at 105mm → startX = 65mm
  static const int studentNoDigits = 9;
  static const int studentNoRowCount = 10; // digits 0-9
  static const double studentNoGridStartXMm = 65.0; // first column center X
  static const double studentNoColSpacingMm = 10.0;
  static const double studentNoGridStartYMm = 52.0; // first row center Y
  static const double studentNoRowSpacingMm = 5.6;
  static const double studentNoBubbleDiameterMm = 4.2;
  static const double studentNoBubbleRadiusMm = studentNoBubbleDiameterMm / 2;
  static const double studentNoLabelY = 43.0; // "Student ID:" label Y
  static const double studentNoGridEndY = studentNoGridStartYMm +
      (studentNoRowCount - 1) * studentNoRowSpacingMm +
      studentNoBubbleDiameterMm;

  // --- Answer Bubble Grid ---
  // Grid: 5 columns (A-E), 12mm spacing → width = 48mm
  // With question number column (~12mm) → total ~60mm, centered at 105mm
  // Question number X = 105 - 30 = 75mm, first bubble X = 88mm
  static const double bubbleDiameterMm = 5.5;
  static const double bubbleRadiusMm = bubbleDiameterMm / 2;
  static const double bubbleHSpacingMm = 12.0;
  static const double bubbleVSpacingMm = 7.0;
  static const double gridStartXMm = 88.0; // first bubble column (A) center X
  static const double gridStartYMm = 115.0; // first bubble row center Y
  static const double questionNumberXMm = 75.0; // question label X

  // --- Options ---
  static const List<String> options = ['A', 'B', 'C', 'D', 'E'];
  static const int optionCount = 5;

  // --- Question Limits ---
  static const int minQuestions = 10;
  static const int maxQuestions = 20;
  static const int questionStep = 5;

  // --- App Info ---
  static const String appName = 'Scanex';
  static const String appTagline = 'Optik Form Okuyucu';
}
