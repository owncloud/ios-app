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
	case downloading(progress: Progress)
	case errorDownloading(error: Error?)
	case canceledDownload
	case notSupportedMimeType
}

protocol DisplayViewEditingDelegate: class {
	func save(item: OCItem, fileURL newVersion: URL)
}

class DisplayViewController: UIViewController, OCQueryDelegate {
	private let iconImageSize: CGSize = CGSize(width: 200.0, height: 200.0)
	private let bottomMarginToYAxis: CGFloat = -60.0
	private let verticalSpacing: CGFloat = 10.0
	private let lateralSpacing: CGFloat = 10
	private let progressViewVerticalSpacing: CGFloat = 20.0

	// MARK: - Configuration
	weak var item: OCItem? {
		didSet {
			print("LOG ---> new value of item = \(item)")
		}
	}
	weak var core: OCCore? {
		willSet {
			if let core = core {
				core.removeObserver(self, forKeyPath: "connectionStatus")
			}
		}
		didSet {
			if let core = core {
				core.addObserver(self, forKeyPath: "connectionStatus", options: [.initial, .new], context: nil)
			}
		}
	}

	var source: URL? {
		didSet {
			OnMainThread {
				self.iconImageView.isHidden = true
				self.hideItemMetadataUIElements()
				self.renderSpecificView()
			}
		}
	}

	private var state: DisplayViewState = .hasNetworkConnection {
		didSet {
			OnMainThread {
				switch self.state {
					case .downloading(let progress):
						self.downloadProgress = progress

					default:
						self.downloadProgress = nil
				}
				self.render()
			}
		}
	}

	public var downloadProgress : Progress? {
		didSet {
			progressView?.observedProgress = downloadProgress
		}
	}

	// MARK: - Views
	private var iconImageView: UIImageView!
	private var progressView : UIProgressView?
	private var cancelButton : ThemeButton?
	private var metadataInfoLabel: UILabel?
	private var showPreviewButton: ThemeButton?
	private var noNetworkLabel : UILabel?

	// MARK: - Delegate
	weak var editingDelegate: DisplayViewEditingDelegate?

	// MARK: - Init & Deinit
	required init() {
		super.init(nibName: nil, bundle: nil)
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	deinit {
		Theme.shared.unregister(client: self)
		self.downloadProgress?.cancel()
		self.stopQuery()
		if let core = core {
			core.removeObserver(self, forKeyPath: "connectionStatus")
		}
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
		metadataInfoLabel?.textAlignment = .center
		metadataInfoLabel?.adjustsFontForContentSizeCategory = true
		metadataInfoLabel?.font = UIFont.preferredFont(forTextStyle: .headline)

		view.addSubview(metadataInfoLabel!)

		progressView = UIProgressView(progressViewStyle: .bar)
		progressView?.translatesAutoresizingMaskIntoConstraints = false
		progressView?.progress = 0
		progressView?.observedProgress = downloadProgress
		progressView?.isHidden = (downloadProgress != nil)

		view.addSubview(progressView!)

		cancelButton = ThemeButton(type: .custom)
		cancelButton?.translatesAutoresizingMaskIntoConstraints = false
		cancelButton?.setTitle("Cancel".localized, for: .normal)
		cancelButton?.isHidden = (downloadProgress != nil)
		cancelButton?.addTarget(self, action: #selector(cancelDownload(sender:)), for: UIControl.Event.touchUpInside)

		view.addSubview(cancelButton!)

		showPreviewButton = ThemeButton(type: .custom)
		showPreviewButton?.translatesAutoresizingMaskIntoConstraints = false
		showPreviewButton?.setTitle("Open file".localized, for: .normal)
		showPreviewButton?.isHidden = true
		showPreviewButton?.addTarget(self, action: #selector(downloadItem), for: UIControl.Event.touchUpInside)
		view.addSubview(showPreviewButton!)

		noNetworkLabel = UILabel()
		noNetworkLabel?.translatesAutoresizingMaskIntoConstraints = false
		noNetworkLabel?.isHidden = true
		noNetworkLabel?.adjustsFontForContentSizeCategory = true
		noNetworkLabel?.text = "There is no network".localized
		noNetworkLabel?.textAlignment = .center
		noNetworkLabel?.font = UIFont.preferredFont(forTextStyle: .headline)
		view.addSubview(noNetworkLabel!)

		guard let iconImageView = iconImageView, let metadataInfoLabel = metadataInfoLabel, let progressView = progressView,
		      let cancelButton = cancelButton, let showPreviewButton = showPreviewButton, let noNetworkLabel = noNetworkLabel
		      else {
			return
		}

		NSLayoutConstraint.activate([
			iconImageView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
			iconImageView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor, constant: bottomMarginToYAxis),
			iconImageView.heightAnchor.constraint(equalToConstant: iconImageSize.height),
			iconImageView.widthAnchor.constraint(equalToConstant: iconImageSize.width),

			metadataInfoLabel.centerXAnchor.constraint(equalTo: iconImageView.centerXAnchor),
			metadataInfoLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: verticalSpacing),
			metadataInfoLabel.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: lateralSpacing),
			metadataInfoLabel.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -lateralSpacing),

			progressView.centerXAnchor.constraint(equalTo: iconImageView.centerXAnchor),
			progressView.widthAnchor.constraint(equalTo: iconImageView.widthAnchor),
			progressView.topAnchor.constraint(equalTo: metadataInfoLabel.bottomAnchor, constant: progressViewVerticalSpacing),

			cancelButton.centerXAnchor.constraint(equalTo: iconImageView.centerXAnchor),
			cancelButton.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: verticalSpacing),

			showPreviewButton.centerXAnchor.constraint(equalTo: iconImageView.centerXAnchor),
			showPreviewButton.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: verticalSpacing),

			noNetworkLabel.centerXAnchor.constraint(equalTo: metadataInfoLabel.centerXAnchor),
			noNetworkLabel.topAnchor.constraint(equalTo: metadataInfoLabel.bottomAnchor, constant: verticalSpacing),
			noNetworkLabel.widthAnchor.constraint(equalTo: iconImageView.widthAnchor)
		])
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		Theme.shared.register(client: self)

		if let item = item {
			iconImageView.image = item.icon(fitInSize:iconImageSize)

			if item.thumbnailAvailability != .none {
				let displayThumbnail = { (thumbnail: OCItemThumbnail?) in
					_ = thumbnail?.requestImage(for: self.iconImageSize, scale: 0, withCompletionHandler: { (thumbnail, error, _, image) in
						if error == nil,
							image != nil,
							item.itemVersionIdentifier == thumbnail?.itemVersionIdentifier {
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
		}
	}

	func setupStatusBar() {
		if let parent = parent, let item = item, let itemName = item.name {
			parent.navigationItem.title = itemName

			let actionsBarButtonItem = UIBarButtonItem(title: "•••", style: .plain, target: self, action: #selector(optionsBarButtonPressed))
			actionsBarButtonItem.accessibilityLabel = itemName + " " + "Actions".localized
			parent.navigationItem.rightBarButtonItem = actionsBarButtonItem
		}
	}

	// MARK: - Download actions
	@objc func cancelDownload(sender: Any?) {
		if downloadProgress != nil {
			downloadProgress?.cancel()
		}
		self.state = .canceledDownload
	}

	@objc func downloadItem(sender: Any?) {
		guard let core = core, let item = item else {
			return
		}

		if let downloadProgress = core.downloadItem(item, options: [ .returnImmediatelyIfOfflineOrUnavailable : true ], resultHandler: { [weak self] (error, _, latestItem, file) in
			guard error == nil else {
				OnMainThread {
					if (error as NSError?)?.isOCError(withCode: .itemNotAvailableOffline) == true {
						self?.state = .noNetworkConnection
					} else {
						self?.state = .errorDownloading(error: error!)
					}
				}
				return
			}
//			OnMainThread {
				self?.item = latestItem
				self?.source = file!.url
//			}
		}) {
			self.state = .downloading(progress: downloadProgress)
		}
	}

	func renderSpecificView() {
		// This function is intended to be overwritten by the subclases to implement a custom view based on the source property.s
	}

	func hideItemMetadataUIElements() {
		iconImageView.isHidden = true
		progressView?.isHidden = true
		cancelButton?.isHidden = true
		metadataInfoLabel?.isHidden = true
		showPreviewButton?.isHidden = true
		noNetworkLabel?.isHidden = true
	}

	// MARK: - KVO observing
	// swiftlint:disable block_based_kvo
	override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
		if let newValue = change?[NSKeyValueChangeKey.newKey] as? OCCoreConnectionStatus {
			if case DisplayViewState.notSupportedMimeType = self.state {

			} else {
				if newValue == .online {
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
			hideProgressIndicators()

		case .noNetworkConnection:
			self.progressView?.isHidden = true
			self.cancelButton?.isHidden = true
			self.noNetworkLabel?.isHidden = false
			self.showPreviewButton?.isHidden = true

		case .errorDownloading, .canceledDownload:
			if core?.connectionStatus == .online {
				hideProgressIndicators()
			}

		case .downloading(_):
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
		guard let core = core, let item = item else {
			return
		}

		let actionsLocation = OCExtensionLocation(ofType: .action, identifier: .moreItem)
		let actionContext = ActionContext(viewController: self, core: core, items: [item], location: actionsLocation)

		let moreViewController = Action.cardViewController(for: item, with: actionContext, completionHandler: { [weak self] _ in
			self?.navigationController?.popViewController(animated: true)
		})

		self.present(asCard: moreViewController, animated: true)
	}

	// MARK: - Query management
	private var query : OCQuery?

	func startQuery() {
		if query == nil, let item = item, let core = core {
			query = OCQuery(item: item)

			if let query = query {
				query.delegate = self
				core.start(query)
			}
		}
	}

	func stopQuery() {
		if query != nil, let core = core, let query = query {
			self.query = nil

			query.delegate = nil

			core.stop(query)
		}
	}

	// MARK: - Query handling
	// (not in an extension, so subclasses can override these as needed)
	func query(_ query: OCQuery, failedWithError error: Error) {
		// Not applicable atm
	}

	func queryHasChangesAvailable(_ query: OCQuery) {
		query.requestChangeSet(withFlags: OCQueryChangeSetRequestFlag(rawValue: 0)) { (query, changeSet) in
			OnMainThread {
				switch query.state {
					case .idle, .contentsFromCache, .waitingForServerReply:
						if let firstItem = changeSet?.queryResult.first {
							if (firstItem.itemVersionIdentifier != self.item?.itemVersionIdentifier) || (firstItem.name != self.item?.name) {
								self.present(item: firstItem)
							}
						}

					case .targetRemoved: break

					default: break
				}
			}
		}
	}

	func present(item: OCItem) {
		self.item = item

		metadataInfoLabel?.text = item.sizeLocalized + " - " + item.lastModifiedLocalized

		switch state {
			case .notSupportedMimeType: break

			default:
				self.stopQuery()
				self.startQuery()

				self.downloadItem(sender: nil)

				if let parent = parent {
					parent.navigationItem.title = item.name
					parent.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "•••", style: .plain, target: self, action: #selector(optionsBarButtonPressed))
				}
		}
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
