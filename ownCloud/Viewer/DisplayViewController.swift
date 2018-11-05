//
//  DisplayViewController.swift
//  ownCloud
//
//  Created by Pablo Carrascal on 12/09/2018.
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

struct DisplayViewConfiguration {
	weak var item: OCItem!
	weak var core: OCCore!
	let state: DisplayViewState
}

enum DisplayViewState {
	case hasNetworkConnection
	case noNetworkConnection
	case downloading(progess: Progress)
	case errorDownloading(error: Error?)
	case canceledDownload
	case notSupportedMimeType
}

protocol DisplayViewEditingDelegate: class {
	func save(item: OCItem, fileURL newVersion: URL)
}

class DisplayViewController: UIViewController {

	private let iconImageSize: CGSize = CGSize(width: 200.0, height: 200.0)

	private var interactionController: UIDocumentInteractionController?

	// MARK: - Configuration
	weak var item: OCItem!
	weak var core: OCCore! {
		didSet {
			core.addObserver(self, forKeyPath: "reachabilityMonitor.available", options: [.initial, .new], context: observerContext)
		}
	}

	var source: URL! {
		didSet {
			OnMainThread {
				self.iconImageView.isHidden = true
			}
			renderSpecificView()
		}
	}

	private var state: DisplayViewState = .hasNetworkConnection {
		didSet {
			OnMainThread {
				self.render()
			}
		}
	}

	public var downloadProgress : Progress? {
		didSet {
			progressView?.observedProgress = downloadProgress
		}
	}

	private var observerContextValue = 1
	private var observerContext : UnsafeMutableRawPointer

	// MARK: - Views
	private var iconImageView: UIImageView!
	private var progressView : UIProgressView?
	private var cancelButton : UIButton?
	private var metadataInfoLabel: UILabel?
	private var showPreviewButton: UIButton?
	private var noNetworkLabel : UILabel?

	// MARK: - Delegate
	weak var editingDelegate: DisplayViewEditingDelegate?

	// MARK: - Init & Deinit
	required init() {
		observerContext = UnsafeMutableRawPointer(&observerContextValue)
		super.init(nibName: nil, bundle: nil)
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	deinit {
		Theme.shared.unregister(client: self)
		self.downloadProgress?.cancel()
		core.removeObserver(self, forKeyPath: "reachabilityMonitor.available", context: observerContext)
	}

	// MARK: - Controller lifecycle
	override func loadView() {
		super.loadView()

		iconImageView = UIImageView()
		iconImageView.translatesAutoresizingMaskIntoConstraints = false
		iconImageView.contentMode = .scaleAspectFit

		view.addSubview(iconImageView)

		metadataInfoLabel = UILabel()
		metadataInfoLabel?.translatesAutoresizingMaskIntoConstraints = false
		metadataInfoLabel?.isHidden = false
		metadataInfoLabel?.text = item.sizeInReadableFormat + " - " + item.lastModifiedInReadableFormat
		metadataInfoLabel?.textAlignment = .center

		view.addSubview(metadataInfoLabel!)

		progressView = UIProgressView(progressViewStyle: .bar)
		progressView?.translatesAutoresizingMaskIntoConstraints = false
		progressView?.progress = 0
		progressView?.observedProgress = downloadProgress
		progressView?.isHidden = (downloadProgress != nil)

		view.addSubview(progressView!)

		cancelButton = ThemeButton(type: .system)
		cancelButton?.translatesAutoresizingMaskIntoConstraints = false
		cancelButton?.setTitle("Cancel".localized, for: .normal)
		cancelButton?.isHidden = (downloadProgress != nil)
		cancelButton?.addTarget(self, action: #selector(cancelDownload(sender:)), for: UIControl.Event.touchUpInside)

		view.addSubview(cancelButton!)

		showPreviewButton = ThemeButton(type: .system)
		showPreviewButton?.translatesAutoresizingMaskIntoConstraints = false
		showPreviewButton?.setTitle("Open file".localized, for: .normal)
		showPreviewButton?.isHidden = true
		showPreviewButton?.addTarget(self, action: #selector(downloadItem), for: UIControl.Event.touchUpInside)
		view.addSubview(showPreviewButton!)

		noNetworkLabel = UILabel()
		noNetworkLabel?.translatesAutoresizingMaskIntoConstraints = false
		noNetworkLabel?.isHidden = true
		noNetworkLabel?.text = "There is no network".localized
		noNetworkLabel?.textAlignment = .center
		view.addSubview(noNetworkLabel!)

		NSLayoutConstraint.activate([
			iconImageView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
			iconImageView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor, constant: -60),
			iconImageView.heightAnchor.constraint(equalToConstant: iconImageSize.height),
			iconImageView.widthAnchor.constraint(equalTo: iconImageView.heightAnchor),

			metadataInfoLabel!.centerXAnchor.constraint(equalTo: iconImageView.centerXAnchor),
			metadataInfoLabel!.topAnchor.constraint(equalTo: iconImageView!.bottomAnchor, constant: 10),
			metadataInfoLabel!.widthAnchor.constraint(equalTo: iconImageView.widthAnchor),

			progressView!.centerXAnchor.constraint(equalTo: iconImageView.centerXAnchor),
			progressView!.widthAnchor.constraint(equalTo: iconImageView.widthAnchor),
			progressView!.topAnchor.constraint(equalTo: metadataInfoLabel!.bottomAnchor, constant: 20),

			cancelButton!.centerXAnchor.constraint(equalTo: iconImageView.centerXAnchor),
			cancelButton!.topAnchor.constraint(equalTo: progressView!.bottomAnchor, constant: 10),

			showPreviewButton!.centerXAnchor.constraint(equalTo: iconImageView.centerXAnchor),
			showPreviewButton!.topAnchor.constraint(equalTo: progressView!.bottomAnchor, constant: 10),

			noNetworkLabel!.centerXAnchor.constraint(equalTo: metadataInfoLabel!.centerXAnchor),
			noNetworkLabel!.topAnchor.constraint(equalTo: metadataInfoLabel!.bottomAnchor, constant: 10),
			noNetworkLabel!.widthAnchor.constraint(equalTo: iconImageView.widthAnchor)
		])
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		iconImageView.image = item.icon(fitInSize:iconImageSize)

		if item.thumbnailAvailability != .none {
			let displayThumbnail = { (thumbnail: OCItemThumbnail?) in
				_ = thumbnail?.requestImage(for: self.iconImageSize, scale: 0, withCompletionHandler: { (thumbnail, error, _, image) in
					if error == nil,
						image != nil,
						self.item.itemVersionIdentifier == thumbnail?.itemVersionIdentifier {
						OnMainThread {
							if !self.iconImageView.isHidden {
								self.iconImageView.image = image
							}
						}
					}
				})
			}

			if let thumbnail = item.thumbnail {
				displayThumbnail(thumbnail)
			} else {
				_ = core?.retrieveThumbnail(for: item, maximumSize: iconImageSize, scale: 0, retrieveHandler: { (_, _, _, thumbnail, _, _) in
					displayThumbnail(thumbnail)
				})
			}
		}

		Theme.shared.register(client: self)

		guard let parent = parent else {
			return
		}

		parent.navigationItem.title = item.name
		parent.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "•••", style: .plain, target: self, action: #selector(optionsBarButtonPressed))
	}

	// MARK: - Download actions
	@objc func cancelDownload(sender: Any?) {
		self.state = .canceledDownload
	}

	@objc func downloadItem(sender: Any?) {
//		self.showPreviewButton?.isHidden = true
		if core.reachabilityMonitor.available {
			if let downloadProgress = self.core.downloadItem(item, options: nil, resultHandler: { [weak self] (error, _, _, file) in
				guard error == nil else {
					OnMainThread {
						self?.state = .errorDownloading(error: error!)
					}
					return
				}
				OnMainThread {
					self?.source = file!.url
				}
			}) {
				self.state = .downloading(progess: downloadProgress)
			}
		} else {
			self.state = .noNetworkConnection
		}
	}

	func renderSpecificView() {
		// This function is intended to be overwritten by the subclases to implement a custom view based on the source property.s
	}

	// MARK: - KVO observing
	// swiftlint:disable block_based_kvo
	override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
		if let newValue = change?[NSKeyValueChangeKey.newKey] as? Bool {
			if case DisplayViewState.notSupportedMimeType = self.state {

			} else {
				if newValue {
					self.state = .hasNetworkConnection
				} else {
					self.state = .noNetworkConnection
				}
			}
		}
	}
	// swiftlint:enable block_based_kvo

	private func render() {
		print("LOG --> State changed to \(state)")
		switch state {
		case .hasNetworkConnection:
			if self.downloadProgress == nil {
				hideProgressIndicators()
			}

		case .noNetworkConnection:
			self.downloadProgress?.cancel()
			self.progressView?.progress = 0.0
			self.progressView?.isHidden = true
			self.cancelButton?.isHidden = true
			self.noNetworkLabel?.isHidden = false
			self.showPreviewButton?.isHidden = true

		case .errorDownloading, .canceledDownload:
			self.downloadProgress?.cancel()
			self.downloadProgress = nil
			if core.reachabilityMonitor.available {
				hideProgressIndicators()
			}

		case .downloading(let progress):
			self.downloadProgress = progress
			self.progressView?.isHidden = false
			self.cancelButton?.isHidden = false
			self.noNetworkLabel?.isHidden = true
			self.showPreviewButton?.isHidden = true

		case .notSupportedMimeType:
			self.progressView?.isHidden = true
			self.cancelButton?.isHidden = true
			self.noNetworkLabel?.isHidden = true
			self.showPreviewButton?.isHidden = true
		}
	}

	private func hideProgressIndicators() {
		self.progressView?.progress = 0.0
		self.progressView?.isHidden = true
		self.cancelButton?.isHidden = true
		self.noNetworkLabel?.isHidden = true
		self.showPreviewButton?.isHidden = false
	}

	@objc func optionsBarButtonPressed() {
//		let tableViewController = MoreStaticTableViewController(style: .grouped)
//		let header = MoreViewHeader(for: item, with: core!)
//		let moreViewController = MoreViewController(item: item, core: core!, header: header, viewController: tableViewController)
//
//		let title = NSAttributedString(string: "Actions", attributes: [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 20, weight: .heavy)])
//
//		let openInRow: StaticTableViewRow = StaticTableViewRow(buttonWithAction: { [weak self] (_, _) in
//			if UIDevice.current.isIpad() {
//				self?.openInRow(self!.item, button: self!.parent!.navigationItem.rightBarButtonItem!)
//			} else {
//				self?.openInRow(self!.item)
//			}
//			moreViewController.dismiss(animated: true)
//			}, title: "Open in".localized, style: .plainNonOpaque)
//
//		tableViewController.addSection(MoreStaticTableViewSection(headerAttributedTitle: title, identifier: "actions-section", rows: [openInRow]))
//
		//		self.present(asCard: moreViewController, animated: true)let actionsObject: ActionsMoreViewController = ActionsMoreViewController(item: item, core: core!, into: self)
		let actionsObject: ActionsMoreViewController = ActionsMoreViewController(item: item, core: core!, into: self)
		actionsObject.presentActionsCard(with: [actionsObject.openIn(), actionsObject.delete(completion: {
			self.parent?.dismiss(animated: true)
		})]) {
			print("LOG ---> presented")
		}
	}

	// MARK: - Actions
	func openInRow(_ item: OCItem, button: UIBarButtonItem? = nil) {

		if source == nil {
			if !core.reachabilityMonitor.available {
				OnMainThread {
					let alert = UIAlertController(with: "No Network connection", message: "No network connection")
					self.present(alert, animated: true)
				}
			} else {
				let controller = DownloadFileProgressHUDViewController()

				if let progress = core.downloadItem(item, options: nil, resultHandler: { (error, _, _, file) in
					if error == nil {
						self.source = file!.url
						controller.dismiss(animated: true, completion: {
							self.openDocumentInteractionController(with: file!.url, button: button)
						})
					} else {
						controller.dismiss(animated: true)
					}
				}) {
					OnMainThread {
						controller.present(on: self)
						controller.attach(progress: progress)
					}
				}
			}
		} else {
			openDocumentInteractionController(with: source, button: button)
		}
	}

	private func openDocumentInteractionController(with source: URL, button: UIBarButtonItem?) {
		OnMainThread {
			self.interactionController = UIDocumentInteractionController(url: source)
			self.interactionController?.delegate = self
			if button != nil {
				self.interactionController?.presentOptionsMenu(from: button!, animated: true)
			} else {
				self.interactionController?.presentOptionsMenu(from: .zero, in: self.view, animated: true)
			}
		}
	}
}

// MARK: - UIDocumentInteractionControllerDelegate
extension DisplayViewController: UIDocumentInteractionControllerDelegate {
	func documentInteractionControllerDidDismissOpenInMenu(_ controller: UIDocumentInteractionController) {
		self.interactionController = nil
	}
}

// MARK: - Public API
extension DisplayViewController {
	func configure(_ configuration: DisplayViewConfiguration) {
		self.core = configuration.core
		self.item = configuration.item
		self.state = configuration.state
	}
}

// MARK: - Themeable implementation
extension DisplayViewController : Themeable {
	func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		progressView?.applyThemeCollection(collection)
		cancelButton?.applyThemeCollection(collection)
		metadataInfoLabel?.applyThemeCollection(collection)
		showPreviewButton?.applyThemeCollection(collection)
		noNetworkLabel?.applyThemeCollection(collection)
	}
}
