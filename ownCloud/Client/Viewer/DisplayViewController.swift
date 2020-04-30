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
	var item: OCItem?
	weak var core: OCCore?
	let state: DisplayViewState
}

enum DisplayViewState {
	case initial
	case hasNetworkConnection
	case noNetworkConnection
	case downloading(progress: Progress)
	case errorDownloading(error: Error?)
	case downloadFinished
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

	var progressSummarizer : ProgressSummarizer?

	// MARK: - Configuration
	var item: OCItem?
	var itemIndex: Int?

	private var coreConnectionStatusObservation : NSKeyValueObservation?
	weak var core: OCCore? {
		willSet {
			coreConnectionStatusObservation?.invalidate()
			coreConnectionStatusObservation = nil
		}
		didSet {
			if let core = core {

				func updateState() {
					if core.connectionStatus == .online {
						self.state = .hasNetworkConnection
					} else {
						self.state = .noNetworkConnection
					}
				}

				updateState()

				coreConnectionStatusObservation = core.observe(\OCCore.connectionStatus, options: [.initial, .new]) { [weak self] (_, _) in
					guard let state = self?.state, case DisplayViewState.notSupportedMimeType = state else {
						updateState()
						return
					}
				}
			}
		}
	}

	// This shall be set to false if DisplayViewController sublass is able to handle streamed data (e.g. audio, video)
	var requiresLocalItemCopy: Bool = true

	private var lastSourceItemVersion : OCItemVersionIdentifier?
	private var lastSourceItemModificationDate : Date?
	var source: URL? {
		didSet {
			if self.source != nil {
				lastSourceItemVersion = item?.localCopyVersionIdentifier ?? item?.itemVersionIdentifier

				OnMainThread(inline: true) {
					if self.shallShowPreview == true && self.canPreview(url: self.source!) {
						self.iconImageView?.isHidden = true
						self.hideItemMetadataUIElements()
						self.renderSpecificView(completion: { (success) in
							if !success {
								self.iconImageView?.isHidden = false
								self.infoLabel?.text = "File couldn't be opened".localized
								self.infoLabel?.isHidden = false
							}
						})
					}
				}
			}
		}
	}

	var httpAuthHeaders: [String : String]?

	var shallDisplayMoreButtonInToolbar = true

	var shallShowPreview = true

	private var state: DisplayViewState = .initial {
		didSet {
			switch self.state {
			case .downloading(let progress):
				self.downloadProgress = progress
			case .notSupportedMimeType:
				shallShowPreview = false
			case .hasNetworkConnection:
				updateSource()
			default:
				self.downloadProgress = nil
			}
			self.render()
		}
	}

	public var downloadProgress : Progress? {
		didSet {
			OnMainThread(inline: true) {
				self.progressView?.observedProgress = self.downloadProgress
			}
		}
	}

	// MARK: - Views
	private var iconImageView: UIImageView?
	private var progressView : UIProgressView?
	private var cancelButton : ThemeButton?
	private var metadataInfoLabel: UILabel?
	private var showPreviewButton: ThemeButton?
	private var infoLabel : UILabel?

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
		coreConnectionStatusObservation?.invalidate()
		Theme.shared.unregister(client: self)
		self.stopQuery()
	}

	// MARK: - Controller lifecycle
	override func loadView() {
		super.loadView()

		iconImageView = UIImageView()
		metadataInfoLabel = UILabel()
		cancelButton = ThemeButton(type: .custom)
		showPreviewButton = ThemeButton(type: .custom)

		if #available(iOS 13.4, *) {
			PointerEffect.install(on: cancelButton!, effectStyle: .highlight)
			PointerEffect.install(on: showPreviewButton!, effectStyle: .highlight)
		}
		infoLabel = UILabel()
		progressView = UIProgressView(progressViewStyle: .bar)

		guard let iconImageView = iconImageView, let metadataInfoLabel = metadataInfoLabel, let progressView = progressView, let cancelButton = cancelButton, let showPreviewButton = showPreviewButton, let noNetworkLabel = infoLabel else {
			return
		}

		iconImageView.translatesAutoresizingMaskIntoConstraints = false
		iconImageView.contentMode = .scaleAspectFit

		view.addSubview(iconImageView)

		metadataInfoLabel.translatesAutoresizingMaskIntoConstraints = false
		metadataInfoLabel.isHidden = false
		metadataInfoLabel.textAlignment = .center
		metadataInfoLabel.adjustsFontForContentSizeCategory = true
		metadataInfoLabel.font = UIFont.preferredFont(forTextStyle: .headline)

		view.addSubview(metadataInfoLabel)

		progressView.translatesAutoresizingMaskIntoConstraints = false
		progressView.progress = 0
		progressView.observedProgress = downloadProgress
		progressView.isHidden = (downloadProgress != nil)

		view.addSubview(progressView)

		cancelButton.translatesAutoresizingMaskIntoConstraints = false
		cancelButton.setTitle("Cancel".localized, for: .normal)
		cancelButton.isHidden = (downloadProgress != nil)
		cancelButton.addTarget(self, action: #selector(cancelDownload(sender:)), for: UIControl.Event.touchUpInside)

		view.addSubview(cancelButton)

		showPreviewButton.translatesAutoresizingMaskIntoConstraints = false
		showPreviewButton.setTitle("Open file".localized, for: .normal)
		showPreviewButton.isHidden = true
		showPreviewButton.addTarget(self, action: #selector(downloadItem), for: UIControl.Event.touchUpInside)
		view.addSubview(showPreviewButton)

		noNetworkLabel.translatesAutoresizingMaskIntoConstraints = false
		noNetworkLabel.isHidden = true
		noNetworkLabel.adjustsFontForContentSizeCategory = true
		noNetworkLabel.text = "Network unavailable".localized
		noNetworkLabel.textAlignment = .center
		noNetworkLabel.font = UIFont.preferredFont(forTextStyle: .headline)
		view.addSubview(noNetworkLabel)

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

		if let item = item, let core = self.core {
			if core.localCopy(of: item) == nil {
				iconImageView?.setThumbnailImage(using: core, from: item, with: iconImageSize, avoidSystemThumbnails: true)
			}

			if iconImageView?.image == nil {
				iconImageView?.image = item.icon(fitInSize:iconImageSize)
			}
		}

		self.render()
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		updateNavigationBarItems()
	}

	func updateNavigationBarItems() {
		if let parent = parent, let itemName = item?.name, let queryState = query?.state {
			parent.navigationItem.title = itemName

			if shallDisplayMoreButtonInToolbar {
				if queryState != .targetRemoved {
					let actionsBarButtonItem = UIBarButtonItem(image: UIImage(named: "more-dots"), style: .plain, target: self, action: #selector(optionsBarButtonPressed))
					actionsBarButtonItem.accessibilityLabel = itemName + " " + "Actions".localized
					parent.navigationItem.rightBarButtonItem = actionsBarButtonItem
				} else {
					parent.navigationItem.rightBarButtonItem = nil
				}
			}
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

		switch self.state {
		case .hasNetworkConnection:
			if let downloadProgress = core.downloadItem(item, options: [
				.returnImmediatelyIfOfflineOrUnavailable : true,
				.addTemporaryClaimForPurpose 		 : OCCoreClaimPurpose.view.rawValue
			], resultHandler: { [weak self] (error, _, latestItem, file) in
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
				self?.state = .downloadFinished

				self?.item = latestItem
				self?.source = file?.url

				if let claim = file?.claim, let item = latestItem, let self = self {
					self.core?.remove(claim, on: item, afterDeallocationOf: [self])
				}
			}) {
				self.state = .downloading(progress: downloadProgress)

				self.progressSummarizer?.startTracking(progress: downloadProgress)
			}

		default:
			break
		}
	}

	func renderSpecificView(completion: @escaping  (_ success:Bool) -> Void) {
		// This function is intended to be overwritten by the subclases to implement a custom view based on the source property.s
	}

	func hideItemMetadataUIElements() {
		iconImageView?.isHidden = true
		progressView?.isHidden = true
		cancelButton?.isHidden = true
		metadataInfoLabel?.isHidden = true
		showPreviewButton?.isHidden = true
		infoLabel?.isHidden = true
	}

	private func render() {
		OnMainThread(inline: true) {
			switch self.state {
			case .hasNetworkConnection:
				self.hideProgressIndicators()

			case .noNetworkConnection:
				self.progressView?.isHidden = true
				self.cancelButton?.isHidden = true
				self.infoLabel?.isHidden = false
				self.showPreviewButton?.isHidden = true

			case .errorDownloading, .canceledDownload:
				if self.core?.connectionStatus == .online {
					self.hideProgressIndicators()
				}

			case .downloading(_):
				self.progressView?.isHidden = false
				self.cancelButton?.isHidden = false
				self.infoLabel?.isHidden = true
				self.showPreviewButton?.isHidden = true

			case .notSupportedMimeType:
				self.progressView?.isHidden = true
				self.cancelButton?.isHidden = true
				self.infoLabel?.isHidden = true

				if let item = self.item {
					if self.core?.localCopy(of:item) == nil {
						self.showPreviewButton?.isHidden = false
						self.showPreviewButton?.setTitle("Download".localized, for: .normal)
					}
				}

			case .downloadFinished:
				self.cancelButton?.isHidden = true
				self.progressView?.isHidden = true
			default:
				break
			}
		}
	}

	private func hideProgressIndicators() {
		self.progressView?.progress = 0.0
		self.progressView?.isHidden = true
		self.cancelButton?.isHidden = true
		self.infoLabel?.isHidden = true
		//self.showPreviewButton?.isHidden = false
	}

	@objc func optionsBarButtonPressed(_ sender: UIBarButtonItem) {
		guard let core = core, let item = item else {
			return
		}

		let actionsLocation = OCExtensionLocation(ofType: .action, identifier: .moreItem)
		let actionContext = ActionContext(viewController: self, core: core, items: [item], location: actionsLocation, sender: sender)

		if let moreViewController = Action.cardViewController(for: item, with: actionContext, completionHandler: nil) {
			self.present(asCard: moreViewController, animated: true)
		}
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
		query.requestChangeSet(withFlags: .onlyResults) { [weak self] (query, changeSet) in
			OnMainThread {
				Log.log("Presenting item (DisplayViewController.queryHasChangesAvailable): \(changeSet?.queryResult.description ?? "nil") - state: \(String(describing: query.state.rawValue))")

				switch query.state {
					case .idle, .contentsFromCache, .waitingForServerReply:
						if let firstItem = changeSet?.queryResult.first {
							var localURLLastModified : Date?

							if let localURL = self?.core?.localCopy(of: firstItem) {
								do {
									localURLLastModified  = (try localURL.resourceValues(forKeys: [ .contentModificationDateKey ])).contentModificationDate
								} catch {
									Log.error("Error fetching last modification date of \(localURL): \(error)")
								}
							}

							let currentItem = self?.item

							if (firstItem.syncActivity != .updating) &&
							    (// Item version changed
							     (firstItem.itemVersionIdentifier != currentItem?.itemVersionIdentifier) ||

							     // Item name changed
							     (firstItem.name != currentItem?.name) ||

							     // Item already shown, this version is different from what was shown last
							     ((self?.lastSourceItemVersion != nil) && (firstItem.itemVersionIdentifier != self?.lastSourceItemVersion)) ||

							     // Item changed locally, exists locally, local file modification date changed
							     (firstItem.locallyModified && (localURLLastModified != nil) && (localURLLastModified != self?.lastSourceItemModificationDate))
							) {
								if let lastModified = localURLLastModified {
									self?.lastSourceItemModificationDate = lastModified
								}

								self?.present(item: firstItem)
							} else {
								self?.item = firstItem
							}
						} else {
							// No item available
							Log.debug("Item \(String(describing: self?.item)) no longer available")
							self?.item = nil
						}

						self?.updateNavigationBarItems()

					case .targetRemoved:
						self?.updateNavigationBarItems()

					default: break
				}
			}
		}
	}

	private func updateSource() {
		guard let item = self.item else { return }

		if source == nil || ((lastSourceItemVersion != nil) && (item.itemVersionIdentifier != lastSourceItemVersion) && !item.syncActivity.contains(.downloading)) || item.locallyModified /* || item.localCopyVersionIdentifier != item.itemVersionIdentifier */ {
			if requiresLocalItemCopy {
				if core?.localCopy(of: item) == nil { /* || item.localCopyVersionIdentifier != item.itemVersionIdentifier { */
					self.downloadItem(sender: nil)
				} else {
					core?.registerUsage(of: item, completionHandler: nil)
					if let core = core, let file = item.file(with: core) {
						self.source = file.url
					}
				}
			} else {
				core?.provideDirectURL(for: item, allowFileURL: true, completionHandler: { (error, url, authHeaders) in
					if error == nil {
						self.httpAuthHeaders = authHeaders
						self.source = url
					}
				})
			}
		}
	}

	func present(item: OCItem) {
		guard self.view != nil, item.removed == false else {
			return
		}

		self.item = item
		metadataInfoLabel?.text = item.sizeLocalized + " - " + item.lastModifiedLocalized

		switch state {
			case .notSupportedMimeType: break

			default:

				Log.log("Presenting item (DisplayViewController.present): \(item.description)")

				self.startQuery()

				updateSource()
		}
	}

	// Override in subclasses and implement specific checks if required
	func canPreview(url:URL) -> Bool {
		return true
	}
}

// MARK: - Public API
extension DisplayViewController {
	func configure(_ configuration: DisplayViewConfiguration) {
		self.item = configuration.item
		self.core = configuration.core
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
		infoLabel?.applyThemeCollection(collection)
		self.view.backgroundColor = collection.tableBackgroundColor
	}
}
