/// Controls the feature set of the Android GMS document scanner.
///
/// This maps directly to `GmsDocumentScannerOptions.ScannerMode`.
///
/// **Important:** Google Play Services must be available on the device for the
/// GMS scanner to be used. On unsupported devices the fallback scanner is used
/// instead, and this option has no effect.
enum AndroidScannerMode {
  /// Basic scanning features only (auto/manual capture, crop, rotation, page
  /// management). **No filter-selection UI is shown to the user.** The GMS
  /// scanner applies its own document enhancement internally.
  ///
  /// This is the default.
  base,

  /// Same as [base] plus a filter-selection UI that lets the user pick between
  /// **Original** (photo, no processing), **Enhanced** (document-style) and
  /// **Grayscale**. Use this mode when you want the user to decide whether
  /// post-processing is applied. Choosing *Original* returns the image without
  /// any colour adjustment.
  ///
  /// Note: there is no public API to pre-select "Original" as the default —
  /// the GMS scanner always opens with "Enhanced" pre-selected. The user must
  /// tap "Original" themselves if they want unprocessed output.
  baseWithFilter,

  /// Full feature set — equivalent to [baseWithFilter] plus additional
  /// capabilities such as document image cleaning that Google may roll into
  /// future Play Services updates automatically.
  full,
}
