//
//  ScanViewController.swift
//  ownCloud
//
//  Created by Felix Schwarz on 30.08.19.
//  Copyright © 2019 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2019, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import UIKit
import VisionKit
import ImageIO
import ownCloudSDK
import ownCloudApp

class ScanPage {
	var image : UIImage

	init(with image: UIImage) {
		self.image = image
	}
}

class ScanPageCell : UICollectionViewCell, Themeable {
	private var imageView : FixedHeightImageView?

	var page : ScanPage? {
		didSet {
			self.imageView?.image = page?.image
			self.imageView?.invalidateIntrinsicContentSize()
		}
	}

	var aspectHeight : CGFloat = 0 {
		didSet {
			if aspectHeight != 0 {
				imageView?.aspectHeight = aspectHeight
			}
		}
	}

	private let cellShadowRadius : CGFloat = 6
	private let cellShadowOpacity : Float = 0.2
	private let cellShadowOffset : CGSize = CGSize(width: 0, height: 4)

	override init(frame: CGRect) {
		super.init(frame: frame)

		imageView = FixedHeightImageView()
		imageView?.translatesAutoresizingMaskIntoConstraints = false
		imageView?.contentMode = .scaleAspectFill
		imageView?.setContentCompressionResistancePriority(.required, for: .horizontal)
		imageView?.setContentHuggingPriority(.defaultHigh, for: .horizontal)

		guard let imageView = imageView else { return }

		self.contentView.addSubview(imageView)

		NSLayoutConstraint.activate([
			imageView.leftAnchor.constraint(equalTo: contentView.leftAnchor),
			imageView.rightAnchor.constraint(equalTo: contentView.rightAnchor),
			imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
			imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
		])

		self.layer.shadowColor = UIColor.black.cgColor
		self.layer.shadowRadius = cellShadowRadius
		self.layer.shadowOpacity = cellShadowOpacity
		self.layer.shadowOffset = cellShadowOffset

		Theme.shared.register(client: self, applyImmediately: true)
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	deinit {
		Theme.shared.unregister(client: self)
	}

	func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		self.backgroundColor = collection.tableRowColors.backgroundColor
	}
}

class ScanPagesCollectionViewController : UICollectionViewController, UICollectionViewDelegateFlowLayout, Themeable {
	var flowLayout : UICollectionViewFlowLayout

	var pages : [ScanPage] = [] {
		didSet {
			self.collectionView.reloadData()
		}
	}

	private var height : CGFloat
	private let verticalPadding : CGFloat = 25
	private let horizontalPadding : CGFloat = 20
	private let thumbnailAspectRatio : CGFloat = 0.6

	init (height: CGFloat) {
		self.height = height

		flowLayout = UICollectionViewFlowLayout()
		flowLayout.scrollDirection = .horizontal
		flowLayout.estimatedItemSize = CGSize(width: floor(height * thumbnailAspectRatio), height: height)
		flowLayout.sectionInset = UIEdgeInsets(top: verticalPadding, left: horizontalPadding, bottom: verticalPadding, right: horizontalPadding)
		flowLayout.minimumInteritemSpacing = 20

		super.init(collectionViewLayout: flowLayout)

		self.collectionView.alwaysBounceHorizontal = true
		self.collectionView.register(ScanPageCell.self, forCellWithReuseIdentifier: "page")

		Theme.shared.register(client: self, applyImmediately: true)

	}

	deinit {
		Theme.shared.unregister(client: self)
	}

	func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		self.collectionView.backgroundColor = collection.tableBackgroundColor
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func numberOfSections(in collectionView: UICollectionView) -> Int {
		return 1
	}

	override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return pages.count
	}

	override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "page", for: indexPath)

		if let pageCell = cell as? ScanPageCell {
			pageCell.aspectHeight = height - (verticalPadding * 2)
			pageCell.page = pages[indexPath.item]
		}

		return cell
	}
}

extension CGRect {
	func asData() -> NSData {
		return NSData(from: self)
	}
}

struct ScanExportFormat {
	var name : String
	var suffix : String
	var supportsMultiPage : Bool = false
	var exporter : ((_ baseURL: URL, _ pages: [ScanPage]) -> ([URL]?))?
}

@available(iOS 13.0, *)
class ScanViewController: StaticTableViewController {
	weak var core : OCCore?
	var targetFolderItem : OCItem?

	// Pages
	var pagesSection : StaticTableViewSection
	var pagesCollectionViewController : ScanPagesCollectionViewController?

	// Save
	var saveSection : StaticTableViewSection
	var fileNameRow : StaticTableViewRow?

	// Options
	var optionsSection : StaticTableViewSection
	var formatSegmentedControl : UISegmentedControl?
	var oneFilePerPageRow : StaticTableViewRow?

	private static func exportAsImage(format: String, baseURL: URL, pages: [ScanPage]) -> [URL]? {
		var files : [URL] = []

		for page in pages {
			let targetURL = baseURL.appendingPathComponent(UUID().uuidString)
			var imageData : Data?

			switch format {
				case "jpeg":
					imageData = page.image.jpegData(compressionQuality: 0.75)

				case "png":
					imageData = page.image.pngData()

				default: break
			}

			if let imageData = imageData {
				if (try? imageData.write(to: targetURL)) != nil {
					// Writing successful
					files.append(targetURL)
				} else {
					// Error writing
					return nil
				}
			} else {
				// Error
				return nil
			}
		}

		return files.count > 0 ? files : nil
	}

	private static func exportAsPDF(pages: [ScanPage], to url: URL) -> Bool {
		// Using Quartz here to store the exported images JPEG-compressed - something that PDFKit currently doesn't support
		// (a naive PDFKit implementation using PDFDocument and PDFPage produces ~ 11x larger files (31 MB vs. 2.7 MB for a two page scan))

		if let pdfContext = CGContext(url as CFURL, mediaBox: nil, nil) {
			defer {
				pdfContext.closePDF()
			}

			for page in pages {
				if let jpegData = page.image.jpegData(compressionQuality: 0.75),
				   let dataProvider = CGDataProvider(data: jpegData as CFData),
				   let jpegImage = CGImage(jpegDataProviderSource: dataProvider, decode: nil, shouldInterpolate: true, intent: .defaultIntent) {
					let mediaBoxRect = CGRect(x: 0, y: 0, width: page.image.size.width, height: page.image.size.height)

					pdfContext.beginPDFPage([
						kCGPDFContextMediaBox : mediaBoxRect.asData()
					] as CFDictionary)

					pdfContext.draw(jpegImage, in: mediaBoxRect)

					pdfContext.endPDFPage()
				} else {
					return false
				}
			}

			return true
		}

		return false
	}

	let availableExportFormats : [ScanExportFormat] = [
		ScanExportFormat(name: "PDF", suffix: "pdf", supportsMultiPage: true, exporter: { (baseURL, pages) in
			let targetURL = baseURL.appendingPathComponent(UUID().uuidString)

			if ScanViewController.exportAsPDF(pages: pages, to: targetURL) {
				// Writing successful
				return [targetURL]
			} else {
				// Error writing
				return nil
			}
		}),
		ScanExportFormat(name: "JPEG", suffix: "jpg", exporter: { (baseURL, pages) in
			return ScanViewController.exportAsImage(format: "jpeg", baseURL: baseURL, pages: pages)
		}),
		ScanExportFormat(name: "PNG", suffix: "png", exporter: { (baseURL, pages) in
			return ScanViewController.exportAsImage(format: "png", baseURL: baseURL, pages: pages)
		})
	]
	var exportFormat : ScanExportFormat? {
		didSet {
			if let fileName = fileNameRow?.value as? NSString {
				fileNameRow?.value = fileName.deletingPathExtension + "." + (exportFormat?.suffix ?? "")
			}

			guard let oneFilePerPageRow = oneFilePerPageRow else { return }

			if exportFormat?.supportsMultiPage == true {
				if !oneFilePerPageRow.attached {
					optionsSection.add(row: oneFilePerPageRow, animated: true)
				}
			} else {
				if oneFilePerPageRow.attached {
					optionsSection.remove(rows: [oneFilePerPageRow], animated: true)
				}
			}
		}
	}

	init(withImages images: [UIImage]? = nil, with scannedPages: [ScanPage]? = nil, core: OCCore?, fileName: String? = nil, targetFolder item: OCItem ) {
		// Sections
		pagesSection = StaticTableViewSection(headerTitle: "Scans".localized, identifier: "pages")
		saveSection = StaticTableViewSection(headerTitle: "Save as".localized, identifier: "save")
		optionsSection = StaticTableViewSection(headerTitle: "Options".localized, identifier: "options")

		// Init
		super.init(style: .grouped)

		self.isModalInPresentation = true
		self.navigationItem.title = "Scan".localized
		self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(ScanViewController.cancel))
		self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(ScanViewController.save))

		self.core = core
		self.targetFolderItem = item

		// Pages section
		let pagesHeight : CGFloat = 200
		var pages : [ScanPage] = scannedPages ?? []

		if let images = images {
			for image in images {
				pages.append(ScanPage(with: image))
			}
		}

		pagesCollectionViewController = ScanPagesCollectionViewController(height: pagesHeight)
		pagesCollectionViewController?.pages = pages
		if let pagesCollectionView = pagesCollectionViewController?.view {
			pagesSection.add(row: StaticTableViewRow(customView: pagesCollectionView, fixedHeight: pagesHeight))
		}
		pagesSection.add(row: StaticTableViewRow(rowWithAction: { [weak self] (_, _) in
			guard let self = self else { return }

			Scanner.scan(on: self) { (_, _, scan) in
				var pages = self.pagesCollectionViewController?.pages

				if let scan = scan, pages != nil {
					pages!.append(contentsOf: scan.scannedPages)

					self.pagesCollectionViewController?.pages = pages!
				}
			}
		}, title: "Scan additional".localized))
		self.addSection(pagesSection)

		// Save section

		// - Name
		fileNameRow = StaticTableViewRow(textFieldWithAction: nil, placeholder: "Name".localized, value: fileName ?? "", keyboardType: .default, autocorrectionType: .no, enablesReturnKeyAutomatically: true, returnKeyType: .default, identifier: "name", accessibilityLabel: "Name".localized)
		saveSection.add(row: fileNameRow!)
		self.addSection(saveSection)

		// Options section
		// - Format
		formatSegmentedControl = UISegmentedControl(items: availableExportFormats.map({ (format) in return format.name }))
		formatSegmentedControl?.selectedSegmentIndex = 0
		formatSegmentedControl?.isUserInteractionEnabled = true
		formatSegmentedControl?.addTarget(self, action: #selector(updateExportFormat), for: .valueChanged)
		optionsSection.add(row: StaticTableViewRow(label: "File format".localized, alignment: .left, accessoryView: formatSegmentedControl, identifier: "format"))

		// - One file per page
		oneFilePerPageRow = StaticTableViewRow(switchWithAction: nil, title: "Create one file per page".localized, value: false, identifier: "one-file-per-page")
		optionsSection.add(row: oneFilePerPageRow!)
		self.addSection(optionsSection)

		updateExportFormat()
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	@objc func updateExportFormat() {
		if let selectedFormatIndx = formatSegmentedControl?.selectedSegmentIndex {
			self.exportFormat = availableExportFormats[selectedFormatIndx]
		}
	}

	@objc func cancel() {
		self.dismiss(animated: true, completion: nil)
	}

	@objc func save() {
		if let fileName = fileNameRow?.value as? String, let pages = pagesCollectionViewController?.pages, let exporter = self.exportFormat?.exporter, let core = core {
			let progressHUDViewController = ProgressHUDViewController(on: self, label: "Saving".localized)

			DispatchQueue.global(qos: .userInitiated).async {
				let tmpURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)

				try? FileManager.default.createDirectory(at: tmpURL, withIntermediateDirectories: true, attributes: nil)

				var exportedURLs : [URL]?

				if self.exportFormat?.supportsMultiPage == true, (self.oneFilePerPageRow?.value as? Bool) == true {
					for page in pages {
						if let exportedPageURLs = exporter(tmpURL, [page]) {
							if exportedURLs == nil {
								exportedURLs = []
							}
							exportedURLs?.append(contentsOf: exportedPageURLs)
						} else {
							exportedURLs = nil
							break
						}
					}
				} else {
					exportedURLs = exporter(tmpURL, pages)
				}

				Log.log("ExportPDF=\(String(describing: exportedURLs))")

				if let targetItem = self.targetFolderItem, let exportedURLs = exportedURLs {
					for exportedURL in exportedURLs {
						core.importFileNamed(fileName, at: targetItem, from: exportedURL, isSecurityScoped: false, options: [ .automaticConflictResolutionNameStyle : OCCoreDuplicateNameStyle.bracketed.rawValue ], placeholderCompletionHandler: nil, resultHandler: nil)
					}
				}

				OnMainThread {
					progressHUDViewController.dismiss(animated: true, completion: {
						self.dismiss(animated: true)
						try? FileManager.default.removeItem(at: tmpURL)
					})
				}
			}
		}
	}

}

@available(iOS 13.0, *)
extension VNDocumentCameraScan {
	var scannedPages : [ScanPage] {
		var pages : [ScanPage] = []

		for pageIdx in 0 ..< self.pageCount {
			let image = self.imageOfPage(at: pageIdx)

			pages.append(ScanPage(with: image))
		}

		return pages
	}
}

@available(iOS 13.0, *)
class Scanner : NSObject, VNDocumentCameraViewControllerDelegate {
	typealias ScannerCompletionHandler = (_ scanner: Scanner, _ error: Error?, _ scan: VNDocumentCameraScan?) -> Void

	var completionHandler : ScannerCompletionHandler?

	static func scan(on viewController: UIViewController, completion: @escaping ScannerCompletionHandler) {
		let scanner = Scanner()

		scanner.scan(on: viewController, completion: { (_, error, scan) in
			completion(scanner, error, scan)
		})
	}

	func scan(on viewController: UIViewController, completion: @escaping ScannerCompletionHandler) {
		completionHandler = completion

		let documentCameraViewController = VNDocumentCameraViewController()
		documentCameraViewController.delegate = self
		viewController.present(documentCameraViewController, animated: true)
	}

	func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
		controller.presentingViewController?.dismiss(animated: true, completion: {
			self.completionHandler?(self, nil, nil)
			self.completionHandler = nil
		})
	}

	func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
		Log.log("Failed with error=\(error)")
		completionHandler?(self, error, nil)
		completionHandler = nil
	}

	func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
		Log.log("Finished with scan=\(scan)")
		controller.presentingViewController?.dismiss(animated: true, completion: {
			self.completionHandler?(self, nil, scan)
			self.completionHandler = nil
		})
	}
}
