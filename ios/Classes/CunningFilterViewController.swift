import UIKit
import CoreImage

/// A full-screen view controller shown after a scan completes, letting the user
/// preview the scanned image(s) and choose one of three filter modes before
/// confirming the result.
///
/// Filter options:
/// - **Original** — the image exactly as returned by `VNDocumentCameraScan`
///   (reflects whatever the user selected in the system scanner UI).
/// - **Grayscale** — colour removed via CIColorControls (saturation = 0).
/// - **B&W Doc** — high-contrast black & white optimised for text documents
///   (saturation = 0, contrast = 1.5, slight brightness lift).
///
/// The selected filter is applied to *all* pages. The first page is shown as
/// the interactive preview.
@available(iOS 13.0, *)
class CunningFilterViewController: UIViewController {

    // MARK: - Types

    private enum ScanFilter: Int {
        case original  = 0
        case grayscale = 1
        case document  = 2
    }

    // MARK: - Dependencies

    private let pages: [UIImage]
    private let options: CunningScannerOptions
    private let tempDirPath: URL
    private let formattedDate: String
    private let onComplete: ([String]) -> Void
    private let onCancel: () -> Void

    // MARK: - State

    private let ciContext = CIContext(options: [.useSoftwareRenderer: false])
    private var selectedFilter: ScanFilter = .original

    // MARK: - UI

    private lazy var navBar: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(white: 0.13, alpha: 1)
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private lazy var cancelBtn: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Cancel", for: .normal)
        b.setTitleColor(.white, for: .normal)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        return b
    }()

    private lazy var doneBtn: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Done", for: .normal)
        b.setTitleColor(.white, for: .normal)
        b.titleLabel?.font = UIFont.boldSystemFont(ofSize: 17)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.addTarget(self, action: #selector(doneTapped), for: .touchUpInside)
        return b
    }()

    private lazy var titleLbl: UILabel = {
        let lbl = UILabel()
        lbl.text = "Select Filter"
        lbl.textColor = .white
        lbl.font = UIFont.boldSystemFont(ofSize: 17)
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private lazy var imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.backgroundColor = UIColor(white: 0.10, alpha: 1)
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private lazy var pageLabel: UILabel = {
        let lbl = UILabel()
        lbl.textColor = UIColor(white: 0.65, alpha: 1)
        lbl.font = UIFont.systemFont(ofSize: 13)
        lbl.textAlignment = .center
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private lazy var filterSegment: UISegmentedControl = {
        let sc = UISegmentedControl(items: ["Original", "Grayscale", "B&W Doc"])
        sc.selectedSegmentIndex = 0
        sc.translatesAutoresizingMaskIntoConstraints = false
        sc.addTarget(self, action: #selector(filterChanged), for: .valueChanged)
        return sc
    }()

    // MARK: - Init

    init(
        pages: [UIImage],
        options: CunningScannerOptions,
        tempDirPath: URL,
        formattedDate: String,
        onComplete: @escaping ([String]) -> Void,
        onCancel:   @escaping () -> Void
    ) {
        self.pages         = pages
        self.options       = options
        self.tempDirPath   = tempDirPath
        self.formattedDate = formattedDate
        self.onComplete    = onComplete
        self.onCancel      = onCancel
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not supported") }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(white: 0.10, alpha: 1)
        buildLayout()
        refreshPreview()
    }

    // MARK: - Layout

    private func buildLayout() {
        view.addSubview(navBar)
        navBar.addSubview(cancelBtn)
        navBar.addSubview(doneBtn)
        navBar.addSubview(titleLbl)
        view.addSubview(imageView)
        view.addSubview(pageLabel)
        view.addSubview(filterSegment)

        NSLayoutConstraint.activate([
            // nav bar
            navBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            navBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            navBar.heightAnchor.constraint(equalToConstant: 52),

            cancelBtn.leadingAnchor.constraint(equalTo: navBar.leadingAnchor, constant: 16),
            cancelBtn.centerYAnchor.constraint(equalTo: navBar.centerYAnchor),

            doneBtn.trailingAnchor.constraint(equalTo: navBar.trailingAnchor, constant: -16),
            doneBtn.centerYAnchor.constraint(equalTo: navBar.centerYAnchor),

            titleLbl.centerXAnchor.constraint(equalTo: navBar.centerXAnchor),
            titleLbl.centerYAnchor.constraint(equalTo: navBar.centerYAnchor),

            // filter controls at bottom
            filterSegment.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            filterSegment.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            filterSegment.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            filterSegment.heightAnchor.constraint(equalToConstant: 32),

            pageLabel.bottomAnchor.constraint(equalTo: filterSegment.topAnchor, constant: -10),
            pageLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            // image preview fills remaining space
            imageView.topAnchor.constraint(equalTo: navBar.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: pageLabel.topAnchor, constant: -10),
        ])

        pageLabel.text = pages.count > 1
            ? "Previewing page 1 of \(pages.count) — filter applies to all pages"
            : ""
    }

    // MARK: - Filter

    @objc private func filterChanged() {
        selectedFilter = ScanFilter(rawValue: filterSegment.selectedSegmentIndex) ?? .original
        refreshPreview()
    }

    private func refreshPreview() {
        imageView.image = apply(selectedFilter, to: pages[0])
    }

    private func apply(_ filter: ScanFilter, to image: UIImage) -> UIImage {
        switch filter {
        case .original:  return image
        case .grayscale: return grayscale(image) ?? image
        case .document:  return document(image) ?? image
        }
    }

    /// Removes colour (saturation = 0), soft grey tones.
    private func grayscale(_ image: UIImage) -> UIImage? {
        guard let ci = CIImage(image: image),
              let f = CIFilter(name: "CIColorControls") else { return nil }
        f.setValue(ci,  forKey: kCIInputImageKey)
        f.setValue(0.0, forKey: kCIInputSaturationKey)
        guard let out = f.outputImage,
              let cg  = ciContext.createCGImage(out, from: out.extent) else { return nil }
        return UIImage(cgImage: cg)
    }

    /// Removes colour and boosts contrast — clean black & white for text documents.
    private func document(_ image: UIImage) -> UIImage? {
        guard let ci = CIImage(image: image),
              let f = CIFilter(name: "CIColorControls") else { return nil }
        f.setValue(ci,   forKey: kCIInputImageKey)
        f.setValue(0.0,  forKey: kCIInputSaturationKey)
        f.setValue(1.5,  forKey: kCIInputContrastKey)
        f.setValue(0.05, forKey: kCIInputBrightnessKey)
        guard let out = f.outputImage,
              let cg  = ciContext.createCGImage(out, from: out.extent) else { return nil }
        return UIImage(cgImage: cg)
    }

    // MARK: - Actions

    @objc private func doneTapped() {
        var paths: [String] = []
        for (i, page) in pages.enumerated() {
            let filtered = apply(selectedFilter, to: page)
            let url = tempDirPath.appendingPathComponent(
                "\(formattedDate)-\(i).\(options.imageFormat.rawValue)"
            )
            switch options.imageFormat {
            case .jpg:
                try? filtered.jpegData(compressionQuality: options.jpgCompressionQuality)?.write(to: url)
            case .png:
                try? filtered.pngData()?.write(to: url)
            }
            paths.append(url.path)
        }
        dismiss(animated: true) { [weak self] in
            self?.onComplete(paths)
        }
    }

    @objc private func cancelTapped() {
        dismiss(animated: true) { [weak self] in
            self?.onCancel()
        }
    }
}
