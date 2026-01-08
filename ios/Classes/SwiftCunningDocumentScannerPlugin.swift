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
        
        // Process the scan in the background to return quickly
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let tempDirPath = self.getDocumentsDirectory()
            let currentDateTime = Date()
            let df = DateFormatter()
            df.dateFormat = "yyyyMMdd-HHmmss"
            let formattedDate = df.string(from: currentDateTime)
            var filenames: [String] = []
            
            // If singleDocumentMode is enabled, process ONLY the first page and return immediately
            let maxPages = self.scannerOptions.singleDocumentMode ? min(1, scan.pageCount) : scan.pageCount
            
            // Process only the first page when singleDocumentMode is enabled
            if self.scannerOptions.singleDocumentMode && scan.pageCount > 0 {
                let page = scan.imageOfPage(at: 0)
                let url = tempDirPath.appendingPathComponent(formattedDate + "-0.\(self.scannerOptions.imageFormat.rawValue)")
                
                switch self.scannerOptions.imageFormat {
                case CunningScannerImageFormat.jpg:
                    try? page.jpegData(compressionQuality: self.scannerOptions.jpgCompressionQuality)?.write(to: url)
                    break
                case CunningScannerImageFormat.png:
                    try? page.pngData()?.write(to: url)
                    break
                }
                
                filenames.append(url.path)
            } else {
                // Process all pages if singleDocumentMode is disabled
                for i in 0 ..< maxPages {
                    let page = scan.imageOfPage(at: i)
                    let url = tempDirPath.appendingPathComponent(formattedDate + "-\(i).\(self.scannerOptions.imageFormat.rawValue)")
                    switch self.scannerOptions.imageFormat {
                    case CunningScannerImageFormat.jpg:
                        try? page.jpegData(compressionQuality: self.scannerOptions.jpgCompressionQuality)?.write(to: url)
                        break
                    case CunningScannerImageFormat.png:
                        try? page.pngData()?.write(to: url)
                        break
                    }
                    
                    filenames.append(url.path)
                }
            }
            
            // Return result on main thread
            DispatchQueue.main.async {
                self.resultChannel?(filenames)
                self.resultChannel = nil
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
