import 'ios_image_format.dart';

/// Different options that modify the behavior of the document scanner on iOS.
///
/// The [imageFormat] specifies the format of the output image file. Available
/// options are [IosImageFormat.jpeg] or [IosImageFormat.png]. Default value is
/// [IosImageFormat.png].
///
/// If [imageFormat] is set to [IosImageFormat.jpeg] the [jpgCompressionQuality]
/// can be used to control the quality of the resulting JPEG image. The value
/// 0.0 represents the maximum compression (or lowest quality) while the value
/// 1.0 represents the least compression (or best quality). Default value is 1.0.
///
/// The [singleDocumentMode] when set to true, ensures only the first document/page
/// is processed and returned, even if the user scans multiple pages.
///
/// The [frameColor] allows customization of the document detection frame color.
/// Note: This feature is not available on iOS as VNDocumentCameraViewController
/// uses system UI that cannot be customized. This parameter is included for API
/// consistency but will be ignored on iOS.
///
/// The [showFilterUI] when set to true, presents a post-scan filter selection
/// screen before returning the result. The user can choose between:
/// - **Original** — the image as returned by the system scanner (reflects
///   whatever the user selected in the VNDocumentCameraViewController filter bar).
/// - **Grayscale** — colour removed, soft grey tones.
/// - **B&W Doc** — high-contrast black & white optimised for text documents.
///
/// This is the recommended way to give users control over the output image look
/// on iOS, since there is no public API to pre-select the system scanner filter.
final class IosScannerOptions {
  /// Creates a [IosScannerOptions].
  const IosScannerOptions({
    this.imageFormat = IosImageFormat.png,
    this.jpgCompressionQuality = 1.0,
    this.singleDocumentMode = false,
    this.frameColor,
    this.showFilterUI = false,
  });

  final IosImageFormat imageFormat;

  /// The quality of the resulting JPEG image, expressed as a value from 0.0 to
  /// 1.0.
  ///
  /// The value 0.0 represents the maximum compression (or lowest quality) while
  /// the value 1.0 represents the least compression (or best quality). The
  /// [jpgCompressionQuality] only has an effect if the [imageFormat] is set to
  /// [IosImageFormat.jpeg] and is ignored otherwise.
  final double jpgCompressionQuality;

  /// When true, only the first scanned document/page will be processed and returned.
  /// Default value is false.
  final bool singleDocumentMode;

  /// The color of the document detection frame/overlay.
  /// Supports hex colors (e.g., "#FF0000" or "FF0000") or named colors (e.g., "red", "blue").
  /// Note: This feature is not available on iOS and will be ignored.
  final String? frameColor;

  /// When true, a filter selection screen is shown after the scan completes,
  /// letting the user preview the scanned image and choose:
  /// - **Original** — image as returned by the system scanner.
  /// - **Grayscale** — desaturated grey tones.
  /// - **B&W Doc** — high-contrast black & white for documents/text.
  ///
  /// The selected filter is applied to all scanned pages before the result is
  /// returned to Flutter. Default is false.
  final bool showFilterUI;
}
