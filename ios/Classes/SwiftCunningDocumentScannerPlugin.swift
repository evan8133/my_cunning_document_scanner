import Flutter
import UIKit
import Vision
import VisionKit

@available(iOS 13.0, *)
public class SwiftCunningDocumentScannerPlugin: NSObject, FlutterPlugin, VNDocumentCameraViewControllerDelegate {
  var resultChannel: FlutterResult?
  var presentingController: VNDocumentCameraViewController?
  var scannerOptions: CunningScannerOptions = CunningScannerOptions()

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "cunning_document_scanner", binaryMessenger: registrar.messenger())
    let instance = SwiftCunningDocumentScannerPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    if call.method == "getPictures" {
            scannerOptions = CunningScannerOptions.fromArguments(args: call.arguments)
            let presentedVC: UIViewController? = UIApplication.shared.keyWindow?.rootViewController
            self.resultChannel = result
            if VNDocumentCameraViewController.isSupported {
                self.presentingController = VNDocumentCameraViewController()
                self.presentingController!.delegate = self
                presentedVC?.present(self.presentingController!, animated: true)
            } else {
                result(FlutterError(code: "UNAVAILABLE", message: "Document camera is not available on this device", details: nil))
            }
        } else {
            result(FlutterMethodNotImplemented)
            return
        }
  }


    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }

    public func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
        // Dismiss the scanner immediately to return to app as fast as possible
        presentingController?.dismiss(animated: true, completion: nil)

        // Collect UIImages in the background (imageOfPage can be slow for large scans)
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            let tempDirPath   = self.getDocumentsDirectory()
            let df            = DateFormatter()
            df.dateFormat     = "yyyyMMdd-HHmmss"
            let formattedDate = df.string(from: Date())

            let pagesToProcess = self.scannerOptions.singleDocumentMode ? min(1, scan.pageCount) : scan.pageCount
            var pages: [UIImage] = []
            for i in 0 ..< pagesToProcess {
                pages.append(scan.imageOfPage(at: i))
            }

            DispatchQueue.main.async {
                if self.scannerOptions.showFilterUI {
                    // Present our custom filter-selection screen before returning results.
                    let filterVC = CunningFilterViewController(
                        pages: pages,
                        options: self.scannerOptions,
                        tempDirPath: tempDirPath,
                        formattedDate: formattedDate,
                        onComplete: { [weak self] paths in
                            self?.resultChannel?(paths)
                            self?.resultChannel = nil
                        },
                        onCancel: { [weak self] in
                            self?.resultChannel?(nil)
                            self?.resultChannel = nil
                        }
                    )
                    let presentedVC = UIApplication.shared.keyWindow?.rootViewController
                    presentedVC?.present(filterVC, animated: true)
                } else {
                    // Save directly without showing the filter UI.
                    var filenames: [String] = []
                    for (i, page) in pages.enumerated() {
                        let url = tempDirPath.appendingPathComponent(
                            formattedDate + "-\(i).\(self.scannerOptions.imageFormat.rawValue)"
                        )
                        switch self.scannerOptions.imageFormat {
                        case .jpg:
                            try? page.jpegData(compressionQuality: self.scannerOptions.jpgCompressionQuality)?.write(to: url)
                        case .png:
                            try? page.pngData()?.write(to: url)
                        }
                        filenames.append(url.path)
                    }
                    self.resultChannel?(filenames)
                    self.resultChannel = nil
                }
            }
        }
    }

    public func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
        resultChannel?(nil)
        presentingController?.dismiss(animated: true)
    }

    public func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
        resultChannel?(FlutterError(code: "ERROR", message: error.localizedDescription, details: nil))
        presentingController?.dismiss(animated: true)
    }
}
