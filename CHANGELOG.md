## 2.0.7
### iOS
* Added `showFilterUI` option to `IosScannerOptions` (default `false`).
  When `true`, a post-scan **filter selection screen** is presented before returning results to Flutter.
  The user sees a full-screen preview of the scanned image and can choose:
  * **Original** — image as returned by `VNDocumentCameraViewController` (respects the Color/Photo/Grayscale the user picked in the system scanner).
  * **Grayscale** — colour stripped via `CIColorControls` (saturation 0).
  * **B&W Doc** — high-contrast black & white optimised for text documents (saturation 0, contrast 1.5).
  The chosen filter is applied to *all* scanned pages before file paths are returned.
* Refactored `documentCameraViewController(_:didFinishWith:)` — simplified dual-branch logic replaced with a clean collect-then-branch pattern.

## 2.0.6
### Android
* **Fixed `singleDocumentMode` in the fallback scanner:** the crop/corner-edit preview is now always shown before the user clicks Done. Previously the 100ms auto-return skipped the edit UI entirely. The "New Page" button is now hidden immediately when `singleDocumentMode` is true so the user can still only produce one page, but they get to review and adjust document corners first.

## 2.0.5
### Android
* Added `androidScannerMode` parameter (`AndroidScannerMode` enum: `base`, `baseWithFilter`, `full`).
  * `base` (default — backward-compatible): no filter UI, GMS scanner applies document enhancement automatically.
  * `baseWithFilter`: shows a filter-selection screen so the user can choose **Original** (photo, no processing), **Enhanced**, or **Grayscale** before confirming the scan.
  * `full`: same as `baseWithFilter` plus additional GMS features (e.g. image cleaning).
  * **Note:** There is no public GMS API to pre-select "Original" as the default — the scanner always opens with "Enhanced" pre-selected. The user must tap "Original" themselves to get unprocessed output.
* `singleDocumentMode` now correctly resets `androidScannerMode` after each scan call (prevents stale mode on repeated calls).
### iOS
* `singleDocumentMode` confirmed working — only the first scanned page is returned regardless of how many pages `VNDocumentCameraViewController` captured.
* Filter limitation documented: `VNDocumentCameraViewController` applies automatic enhancement via the only available public API `imageOfPage(at:)`. No public API exists to disable this.

## 2.0.3
### iOS
* **Platform limitation documented:** `VNDocumentCameraViewController` (Apple's built-in document scanner) automatically applies image enhancement/filters through its only public API `imageOfPage(at:)`. Apple does not expose any method to retrieve a raw, unfiltered image from this system controller. Users who need completely unfiltered output on iOS should post-process the returned image or implement a custom camera pipeline.
### Android
* GMS document scanner uses `SCANNER_MODE_BASE` which presents no filter UI to the user. The fallback scanner performs only perspective correction — no colour processing is applied. Both paths deliver images without automatic colour filtering, leaving post-processing to the developer.

## 2.0.0
### Breaking Changes
* Reorganized library structure: all implementation files moved to `lib/src/` directory.
* Renamed `ios_options.dart` to `ios_scanner_options.dart` for better clarity.
* Separated `IosImageFormat` enum into its own file (`ios_image_format.dart`).

### Improvements
* Added custom exception `CunningDocumentScannerException` with specific error codes.
* Replaced generic `Exception` with `CunningDocumentScannerException.permissionDenied()` for better error handling.
* Improved code organization with barrel exports - users only need a single import.
* Added comprehensive unit tests for custom exceptions.
* Enhanced equality operators for `CunningDocumentScannerException`.

### Migration Guide
* No changes required for users - the public API remains the same with `import 'package:cunning_document_scanner/cunning_document_scanner.dart';`
* If catching exceptions, update catch blocks to use `CunningDocumentScannerException` instead of generic `Exception`.

## 1.4.0
### General
* Bumped `permission_handler` to `12.0.1`.
* Updated the example app to use Kotlin `2.2.21`, Android Gradle Plugin `8.13.1`, and Gradle `8.13`.
* Added detailed documentation comments to the `CunningDocumentScanner` class.
### Android
* Upgraded `play-services-mlkit-document-scanner` to `16.0.0`.
* Updated `compileSdk` to `34`.

## 1.3.1
* Upgraded dependencies.

## 1.3.0
* Allow users to configure the image output type on iOS (PNG or JPEG).

## 1.2.3
* Fix iOS crash where Documentscanner is not available

## 1.2.2
* Fix bitmap exception crash on Android (thanks to rosenberg_ptr)

## 1.2.1
* Add fallback for Android devices < 1.7GB RAM

## 1.2.0
* Use ML kit on Android
* dropped nocrop support
* image quality dropped

## 1.1.5
* Nmed parameters
* crop default is false
* dependencies updated
* min ios version 12 now

## 1.1.4
* Fixed iOS permission issue in example
* upgraded permission_handler

## 1.1.3
* Fixed permanently denied permission issue
* Merged crop option for android - Thanks Edwin

## 1.1.2
* iOS return unique filenames

## 1.1.1
* Updated android documentscanner library

## 1.1.0
* Exchanged android documentscanner with https://github.com/WebsiteBeaver/android-document-scanner

## 1.0.4
* Fixed conflicting requestcodes issue

## 1.0.3
* Updated permission handler constraint to ^10
* Android fixed nullsafe access issues

## 1.0.2
* Cleanup code - added images to README.md

## 1.0.1

* Fixed Playstore issue exported activity. Added documentation.

## 1.0.0

* Android and iOs Documentscanner based on Visionkit and AndroidDocument https://github.com/mayuce/AndroidDocumentScanner
