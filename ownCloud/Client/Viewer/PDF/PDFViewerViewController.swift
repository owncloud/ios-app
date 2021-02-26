//
//  PDFViewerViewController.swift
//  ownCloud
//
//  Created by Pablo Carrascal on 29/08/2018.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

/*
* Copyright (C) 2018, ownCloud GmbH.
*
* This code is covered by the GNU Public License Version 3.
*
* For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
* You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
*
*/

import UIKit
import ownCloudSDK
import ownCloudAppShared
import PDFKit

extension UILabel {
	func _setupPdfInfoLabel() {
		self.layer.masksToBounds = true
		self.layer.cornerRadius = 8.0
		self.backgroundColor = UIColor.darkGray
		self.textColor = UIColor.white
		self.font = UIFont.systemFont(ofSize: 14.0, weight: UIFont.Weight.medium)
		self.translatesAutoresizingMaskIntoConstraints = false
		self.textAlignment = .center
		self.adjustsFontSizeToFitWidth = true
	}
}

class PDFViewerViewController: DisplayViewController, DisplayExtension {

	enum ThumbnailViewPosition {
		case left, right, bottom, none
		func isVertical() -> Bool {
			return self == .bottom ? false : true
		}
	}

	static let PDFGoToPageNotification = Notification(name: Notification.Name(rawValue: "PDFGoToPageNotification"))

	public let pdfView = PDFView()

	private var gotoPageNotificationObserver : Any?

	private let searchAnnotationDelay = 3.0
	private let thumbnailViewWidthMultiplier: CGFloat = 0.15
	private let thumbnailViewHeightMultiplier: CGFloat = 0.1
	private let filenameContainerTopMargin: CGFloat = 10.0
	private let thumbnailView = PDFThumbnailView()

	private let containerView = UIStackView()
	private let pageCountLabel = UILabel()
	private let pageCountContainerView = UIView()

	private var searchButtonItem: UIBarButtonItem?
	private var gotoButtonItem: UIBarButtonItem?
	private var outlineItem: UIBarButtonItem?

	private var thumbnailViewPosition : ThumbnailViewPosition = .bottom {
		didSet {
			switch thumbnailViewPosition {
				case .left, .right:
					thumbnailView.layoutMode = .vertical
				case .bottom:
					thumbnailView.layoutMode = .horizontal
				default:
					break
			}

			pageCountLabel.isHidden = thumbnailViewPosition == .none ? true : false

			setupConstraints()
		}
	}

	private var activeViewConstraints: [NSLayoutConstraint] = [] {
		willSet {
			NSLayoutConstraint.deactivate(activeViewConstraints)
		}
		didSet {
			NSLayoutConstraint.activate(activeViewConstraints)
		}
	}

	private var fullScreen: Bool = false {
		didSet {
			self.navigationController?.setNavigationBarHidden(fullScreen, animated: true)
			pageCountLabel.isHidden = fullScreen
			pageCountContainerView.isHidden = fullScreen
			setupConstraints()
		}
	}

	// MARK: - DisplayExtension

	static var customMatcher: OCExtensionCustomContextMatcher?
	static var displayExtensionIdentifier: String = "org.owncloud.pdfViewer.default"
	static var supportedMimeTypes: [String]? = ["application/pdf", "application/illustrator"]
	static var features: [String : Any]? = [FeatureKeys.canEdit : false]

	deinit {
		NotificationCenter.default.removeObserver(self)
		if gotoPageNotificationObserver != nil {
			NotificationCenter.default.removeObserver(gotoPageNotificationObserver!)
		}
	}

	private var didSetupView : Bool = false

	private let searchResultsView = PDFSearchResultsView()

	override func renderSpecificView(completion: @escaping (Bool) -> Void) {
		if let source = source, let document = PDFDocument(url: source) {
			if !didSetupView {
				didSetupView  = true

				setupToolbar()

				self.thumbnailViewPosition = .none

				// Configure thumbnail view
				thumbnailView.translatesAutoresizingMaskIntoConstraints = false
				thumbnailView.pdfView = pdfView
				thumbnailView.isExclusiveTouch = true

				self.view.addSubview(thumbnailView)

				containerView.spacing = UIStackView.spacingUseSystem
				containerView.isLayoutMarginsRelativeArrangement = true
				containerView.directionalLayoutMargins = NSDirectionalEdgeInsets(top: filenameContainerTopMargin, leading: 0, bottom: 0, trailing: 0)
				containerView.translatesAutoresizingMaskIntoConstraints = false
				containerView.axis = .vertical
				containerView.distribution = .fill

				// Configure PDFView instance
				pdfView.displayDirection = .horizontal
				pdfView.translatesAutoresizingMaskIntoConstraints = false
				pdfView.usePageViewController(true, withViewOptions: nil)
				containerView.addArrangedSubview(pdfView)

				pageCountContainerView.translatesAutoresizingMaskIntoConstraints = false
				pageCountContainerView.addSubview(pageCountLabel)

				pageCountLabel._setupPdfInfoLabel()

				pageCountLabel.centerXAnchor.constraint(equalTo: pageCountContainerView.centerXAnchor).isActive = true
				pageCountLabel.centerYAnchor.constraint(equalTo: pageCountContainerView.centerYAnchor).isActive = true
				pageCountLabel.widthAnchor.constraint(equalTo: pageCountContainerView.widthAnchor, multiplier: 0.25).isActive = true
				pageCountLabel.heightAnchor.constraint(equalTo: pageCountContainerView.heightAnchor, multiplier: 0.9).isActive = true
				containerView.addArrangedSubview(pageCountContainerView)

				self.view.addSubview(containerView)

				if #available(iOS 13, *) {
					self.view.backgroundColor = self.pdfView.backgroundColor
					thumbnailView.backgroundColor = self.pdfView.backgroundColor
					pageCountContainerView.backgroundColor = self.pdfView.backgroundColor
				} else {
					self.view.backgroundColor = .gray
					thumbnailView.backgroundColor = .gray
					pageCountContainerView.backgroundColor = .gray
				}

				setupConstraints()

				self.view.layoutIfNeeded()
			}

			pdfView.document = document

			setupSearchResultsView()

			pdfView.scaleFactor = pdfView.scaleFactorForSizeToFit
			pdfView.autoScales = true
			updatePageLabel()
			setThumbnailPosition()

			completion(true)

		} else {
			completion(false)
		}
	}

	// MARK: - View lifecycle management

	override func viewDidLoad() {
		super.viewDidLoad()

		NotificationCenter.default.addObserver(self, selector: #selector(handlePageChanged), name: .PDFViewPageChanged, object: nil)

		gotoPageNotificationObserver = NotificationCenter.default.addObserver(forName: PDFViewerViewController.PDFGoToPageNotification.name, object: nil, queue: OperationQueue.main) { [weak self] (notification) in
			if let page = notification.object as? PDFPage {
				self?.pdfView.go(to: page)
			}
		}

		if #available(iOS 13, *) {
			let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.toggleFullscreen(_:)))
			tapRecognizer.numberOfTapsRequired = 1
			pdfView.addGestureRecognizer(tapRecognizer)
			supportsFullScreenMode = true
		}
		//pdfView.isUserInteractionEnabled = true
	}

	@objc func toggleFullscreen(_ sender: UITapGestureRecognizer) {
		self.fullScreen.toggle()
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
	}

	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		pdfView.scaleFactor = pdfView.scaleFactorForSizeToFit
		pdfView.autoScales = true
		if #available(iOS 13, *) {
			self.calculateThumbnailSize()
		}
	}

	override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
		super.viewWillTransition(to: size, with: coordinator)
		// Crashes on pre-iOS 13
		if #available(iOS 13, *) {
			coordinator.animate(alongsideTransition: nil) { (_) in
				self.calculateThumbnailSize()
			}
		}
	}

	override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
		if #available(iOS 13, *) {
			coordinator.animate(alongsideTransition: nil) { (_) in
				self.setThumbnailPosition()
				self.calculateThumbnailSize()
			}
		}
	}

	func save(item: OCItem) {
		if let source = source {
			editingDelegate?.save(item: item, fileURL: source)
		}
	}

	// MARK: - Handlers for PDF View notifications

	@objc func handlePageChanged() {
		updatePageLabel()
	}

	// MARK: - Toolbar actions

	@objc func goToPage() {

		guard let pdfDocument = pdfView.document else { return }

		let alertMessage = NSString(format: "This document has %@ pages".localized as NSString, "\(pdfDocument.pageCount)") as String
		let alertController = ThemedAlertController(title: "Go to page".localized, message: alertMessage, preferredStyle: .alert)
		alertController.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel, handler: nil))

		alertController.addTextField(configurationHandler: { textField in
			textField.placeholder = "Page".localized
			textField.keyboardType = .decimalPad
		})

		alertController.addAction(UIAlertAction(title: "OK".localized, style: .default, handler: { [unowned self] _ in
			if let pageLabel = alertController.textFields?.first?.text {
				self.selectPage(with: pageLabel)
			}
		}))

		self.present(alertController, animated: true)
	}

	@objc func search() {
		guard let pdfDocument = pdfView.document else { return }

		let pdfSearchController = PDFSearchViewController()
		let searchNavigationController = ThemeNavigationController(rootViewController: pdfSearchController)
		pdfSearchController.pdfDocument = pdfDocument
		// Interpret the search text and all the matches returned by search view controller
		pdfSearchController.userSelectedMatchCallback = { (_, matches, selection) in
			DispatchQueue.main.async { [weak self] in
				if matches.count > 1 {
					self?.searchResultsView.matches = matches
					self?.searchResultsView.currentMatch = selection
					self?.showSearchResultsView()
				} else {
					self?.jumpTo(selection)
				}
			}
		}

		if UIDevice.current.userInterfaceIdiom == .pad {
			searchNavigationController.modalPresentationStyle = .popover
			searchNavigationController.popoverPresentationController?.barButtonItem = searchButtonItem
		}

		self.present(searchNavigationController, animated: true)
	}

	@objc func showOutline() {
		guard let pdfDocument = pdfView.document else { return }

		let outlineViewController = PDFOutlineViewController()
		let searchNavigationController = ThemeNavigationController(rootViewController: outlineViewController)
		outlineViewController.pdfDocument = pdfDocument

		if UIDevice.current.userInterfaceIdiom == .pad {
			searchNavigationController.modalPresentationStyle = .popover
			searchNavigationController.popoverPresentationController?.barButtonItem = outlineItem
		}

		self.present(searchNavigationController, animated: true)
	}

	// MARK: - Private helpers

	private func setThumbnailPosition() {
		if UIScreen.main.traitCollection.verticalSizeClass == .regular {
			self.thumbnailViewPosition = .bottom
		} else {
			self.thumbnailViewPosition = .right
		}
	}

	private func calculateThumbnailSize() {
		let maxHeight = floor( min(self.thumbnailView.bounds.size.height, self.thumbnailView.bounds.size.width)  * 0.6)
		self.thumbnailView.thumbnailSize = CGSize(width: maxHeight, height: maxHeight)
	}

	private func setupConstraints() {

		if thumbnailView.superview == nil || pdfView.superview == nil {
			return
		}

		let guide = view.safeAreaLayoutGuide

		var constraints = [NSLayoutConstraint]()
		constraints.append(containerView.topAnchor.constraint(equalTo: guide.topAnchor))

		thumbnailView.isHidden = false

		switch (thumbnailViewPosition, fullScreen) {
			case (_, true):
				constraints.append(containerView.leadingAnchor.constraint(equalTo: guide.leadingAnchor))
				constraints.append(containerView.trailingAnchor.constraint(equalTo: guide.trailingAnchor))
				constraints.append(containerView.bottomAnchor.constraint(equalTo: guide.bottomAnchor))
				thumbnailView.isHidden = true
			case (.left, false):
				constraints.append(thumbnailView.topAnchor.constraint(equalTo: guide.topAnchor))
				constraints.append(thumbnailView.leadingAnchor.constraint(equalTo: guide.leadingAnchor))
				constraints.append(thumbnailView.bottomAnchor.constraint(equalTo: guide.bottomAnchor))
				constraints.append(thumbnailView.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: thumbnailViewWidthMultiplier))

				constraints.append(containerView.leadingAnchor.constraint(equalTo: thumbnailView.trailingAnchor))
				constraints.append(containerView.trailingAnchor.constraint(equalTo: guide.trailingAnchor))
				constraints.append(containerView.bottomAnchor.constraint(equalTo: guide.bottomAnchor))

			case (.right, false):
				constraints.append(thumbnailView.topAnchor.constraint(equalTo: guide.topAnchor))
				constraints.append(thumbnailView.leadingAnchor.constraint(equalTo: containerView.trailingAnchor))
				constraints.append(thumbnailView.trailingAnchor.constraint(equalTo: guide.trailingAnchor))
				constraints.append(thumbnailView.bottomAnchor.constraint(equalTo: guide.bottomAnchor))
				constraints.append(thumbnailView.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: thumbnailViewWidthMultiplier))

				constraints.append(containerView.leadingAnchor.constraint(equalTo: guide.leadingAnchor))
				constraints.append(containerView.trailingAnchor.constraint(equalTo: thumbnailView.leadingAnchor))
				constraints.append(containerView.bottomAnchor.constraint(equalTo: guide.bottomAnchor))

			case (.bottom, false):
				constraints.append(thumbnailView.topAnchor.constraint(equalTo: containerView.bottomAnchor))
				constraints.append(thumbnailView.leadingAnchor.constraint(equalTo: guide.leadingAnchor))
				constraints.append(thumbnailView.trailingAnchor.constraint(equalTo: guide.trailingAnchor))
				constraints.append(thumbnailView.bottomAnchor.constraint(equalTo: guide.bottomAnchor))
				constraints.append(thumbnailView.heightAnchor.constraint(equalTo: self.view.heightAnchor, multiplier: thumbnailViewHeightMultiplier))

				constraints.append(containerView.leadingAnchor.constraint(equalTo: guide.leadingAnchor))
				constraints.append(containerView.trailingAnchor.constraint(equalTo: guide.trailingAnchor))
				constraints.append(containerView.bottomAnchor.constraint(equalTo: thumbnailView.topAnchor))

			case (.none, _):
				constraints.append(containerView.leadingAnchor.constraint(equalTo: guide.leadingAnchor))
				constraints.append(containerView.trailingAnchor.constraint(equalTo: guide.trailingAnchor))
				constraints.append(containerView.bottomAnchor.constraint(equalTo: guide.bottomAnchor))
				thumbnailView.isHidden = true
		}

		self.activeViewConstraints = constraints

	}

	private func setupToolbar() {
		searchButtonItem = UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(search))
		gotoButtonItem = UIBarButtonItem(image: UIImage(named: "ic_pdf_go_to_page"), style: .plain, target: self, action: #selector(goToPage))
		outlineItem = UIBarButtonItem(image: UIImage(named: "ic_pdf_outline"), style: .plain, target: self, action: #selector(showOutline))

		searchButtonItem?.accessibilityLabel = "Search PDF".localized
		gotoButtonItem?.accessibilityLabel = "Go to page".localized
		outlineItem?.accessibilityLabel = "Outline".localized

		self.parent?.navigationItem.rightBarButtonItems = [
			gotoButtonItem!,
			searchButtonItem!,
			outlineItem!]
	}

	// MARK: - Search results navigation

	private func setupSearchResultsView() {
		self.searchResultsView.isHidden = true

		self.pdfView.addSubview(searchResultsView)

		let viewDictionary = ["searchResulsView": searchResultsView]
		var constraints: [NSLayoutConstraint] = []

		let vertical = NSLayoutConstraint.constraints(withVisualFormat: "V:|-20-[searchResulsView(48)]-(>=1)-|", metrics: nil, views: viewDictionary)
		let horizontal = NSLayoutConstraint.constraints(withVisualFormat: "H:|-20-[searchResulsView]-20-|", metrics: nil, views: viewDictionary)
		constraints += vertical
		constraints += horizontal
		NSLayoutConstraint.activate(constraints)

		self.searchResultsView.updateHandler = { selection in
			self.jumpTo(selection)
		}

		self.searchResultsView.closeHandler = { [weak self] in
			self?.hideSearchResultsView()
		}
	}

	private func showSearchResultsView() {
		self.searchResultsView.isHidden = false
		self.searchResultsView.alpha = 0.0
		UIView.animate(withDuration: 0.25, animations: {
			self.searchResultsView.alpha = 1.0
		})
	}

	private func hideSearchResultsView() {
		UIView.animate(withDuration: 0.25, animations: {
			self.searchResultsView.alpha = 0.0
		}, completion: { (complete) in
			self.searchResultsView.isHidden = complete
		})
	}

	private func jumpTo(_ selection: PDFSelection) {
		selection.color = UIColor.yellow
		self.pdfView.go(to: selection)
		self.pdfView.setCurrentSelection(selection, animate: true)

		DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
			self.pdfView.setCurrentSelection(nil, animate: true)
		}
	}

	// MARK: - Current page selection

	private func selectPage(with label:String) {
		guard let pdf = pdfView.document else { return }

		if let pageNr = Int(label) {
			if pageNr > 0 && pageNr < pdf.pageCount {
				if let page = pdf.page(at: pageNr - 1) {
					self.pdfView.go(to: page)
				}
			} else {
				let alertController = ThemedAlertController(title: "Invalid Page".localized,
									    message: "The entered page number doesn't exist".localized,
									    preferredStyle: .alert)
				alertController.addAction(UIAlertAction(title: "OK".localized, style: .default, handler: nil))
				self.present(alertController, animated: true, completion: nil)
			}
		}
	}

	private func updatePageLabel() {
		guard let pdf = pdfView.document else { return }

		guard let page = pdfView.currentPage else { return }

		let pageNrText = "\(pdf.index(for: page) + 1)"
		let maxPageCountText = "\(pdf.pageCount)"
		pageCountLabel.text = NSString(format: "%@ of %@".localized as NSString, pageNrText, maxPageCountText) as String
	}
}
