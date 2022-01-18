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
import ownCloudAppShared

enum DisplayViewState {
	case initial
	case connecting
	case offline
	case online
	case downloadInProgress
	case downloadFailed
	case downloadFinished
	case downloadCanceled
	case previewFailed
}

protocol DisplayViewEditingDelegate: class {
	func save(item: OCItem, fileURL newVersion: URL)
}

class DisplayViewController: UIViewController, Themeable, OCQueryDelegate {

	private let moreButtonTag = 777

	private let iconImageSize: CGSize = CGSize(width: 200.0, height: 200.0)
	private let bottomMargin: CGFloat = 60.0
	private let verticalSpacing: CGFloat = 10.0
	private let horizontalSpacing: CGFloat = 10
	private let progressViewVerticalSpacing: CGFloat = 20.0

	private var stateByConnectionStatus : DisplayViewState? {
		if let status = connectionStatus {
			switch status {
				case .connecting:
					return .connecting

				case .offline:
					return .offline

				case .online:
					return .online

				default: break
			}
		}

		return nil
	}

	private var connectionStatus: OCCoreConnectionStatus? {
		didSet {
			if let status = connectionStatus {
				if let newState = stateByConnectionStatus {
					state = newState
				}

				switch status {
					case .offline:
						stopQuery()

					case .online:
						startQuery()

					default: break
				}
			}
		}
	}

	private var coreConnectionStatusObservation : NSKeyValueObservation?

	weak var core: OCCore? {
		willSet {
			coreConnectionStatusObservation?.invalidate()
			coreConnectionStatusObservation = nil
		}
		didSet {
			if let core = core, core != oldValue {
				coreConnectionStatusObservation = core.observe(\OCCore.connectionStatus, options: .initial) { [weak self, weak core] (_, _) in
					OnMainThread { [weak self, weak core] in
						if let connectionStatus = core?.connectionStatus {
							self?.connectionStatus = connectionStatus
						}
					}
				}
			}
		}
	}

	var progressSummarizer : ProgressSummarizer?

	private var query : OCQuery?
	private var itemClaimIdentifier : UUID?

	func generateClaim(for item: OCItem) -> OCClaim? {
		if let core = core {
			return core.generateTemporaryClaim(for: .view)
		}

		return nil
	}

	var item: OCItem? {
		didSet {
			if itemClaimIdentifier == nil, // No claim registered by the DisplayViewController for the item yet
			let item = item, let core = core,
			core.localCopy(of: item) != nil, // The item has a local copy
			let viewClaim = generateClaim(for: item) { // Generate a claim for the item

			   	itemClaimIdentifier = viewClaim.identifier

				// Add claim to keep file around for viewing
				core.add(viewClaim, on: item, refreshItem: true, completionHandler: nil)

				// Remove claim after deallocation of viewer
				core.remove(viewClaim, on: item, afterDeallocationOf: [ self ])

				Log.debug(tagged: ["VersionUpdates"], "Adding viewing claim \(viewClaim.identifier.uuidString)")
			}

			OnMainThread { [weak self] in
				self?.considerUpdate()
			}
		}
	}
	var itemIndex: Int?

	var itemDirectURL: URL? {
		didSet {
			// Keep record of last item used for direct URL
			Log.debug(tagged: ["VersionUpdates"], "Updated directURL with \(itemDirectURL?.path ?? ""), lastUsedItemVersion=\(String(describing: lastUsedItemVersion))")

			if let item = item {
				lastUsedItem = item
				lastUsedItemVersion = item.localCopyVersionIdentifier ?? item.itemVersionIdentifier
			}
		}
	}

	var httpAuthHeaders: [String : String]?

	private var state: DisplayViewState = .initial {
		didSet {
			if oldValue != self.state {
				OnMainThread(inline: true) {
					self.updateUI()
				}
			}
		}
	}

	public var downloadProgress : Progress? {
		didSet {
			OnMainThread(inline: true) {
				self.progressView.observedProgress = self.downloadProgress
			}
		}
	}

	// MARK: - Subviews / UI elements

	private var iconImageView = UIImageView()
	private var progressView = UIProgressView(progressViewStyle: .bar)
	private var cancelButton = ThemeButton(type: .custom)
	private var metadataInfoLabel = UILabel()
	private var showPreviewButton = ThemeButton(type: .custom)
	private var infoLabel = UILabel()
	private var connectionActivityView = UIActivityIndicatorView(style: .white)

	// MARK: - Editing delegate

	weak var editingDelegate: DisplayViewEditingDelegate?

	// MARK: - Fullscreen Mode Support

	var supportsFullScreenMode = false
	var isFullScreenModeEnabled = false

	// MARK: - Initialization and de-initialization

	required init() {
		super.init(nibName: nil, bundle: nil)
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	deinit {
		Log.debug("Deinit DisplayViewController: \(self.item?.name ?? "-")")

		coreConnectionStatusObservation?.invalidate()
		coreConnectionStatusObservation = nil

		Theme.shared.unregister(client: self)
		self.stopQuery()
	}

	// MARK: - View Controller lifecycle

	override func loadView() {
		super.loadView()

		if #available(iOS 13.4, *) {
			PointerEffect.install(on: cancelButton, effectStyle: .highlight)
			PointerEffect.install(on: showPreviewButton, effectStyle: .highlight)
		}

		iconImageView.translatesAutoresizingMaskIntoConstraints = false
		iconImageView.contentMode = .scaleAspectFit

		view.addSubview(iconImageView)

		metadataInfoLabel.translatesAutoresizingMaskIntoConstraints = false
		metadataInfoLabel.textAlignment = .center
		metadataInfoLabel.adjustsFontForContentSizeCategory = true
		metadataInfoLabel.font = UIFont.preferredFont(forTextStyle: .headline)

		view.addSubview(metadataInfoLabel)

		progressView.translatesAutoresizingMaskIntoConstraints = false
		progressView.progress = 0

		view.addSubview(progressView)

		cancelButton.translatesAutoresizingMaskIntoConstraints = false
		cancelButton.setTitle("Cancel".localized, for: .normal)
		cancelButton.addTarget(self, action: #selector(cancelDownload(sender:)), for: UIControl.Event.touchUpInside)

		view.addSubview(cancelButton)

		showPreviewButton.translatesAutoresizingMaskIntoConstraints = false
		showPreviewButton.setTitle("Open file".localized, for: .normal)
		showPreviewButton.addTarget(self, action: #selector(downloadItem), for: UIControl.Event.touchUpInside)
		view.addSubview(showPreviewButton)

		infoLabel.translatesAutoresizingMaskIntoConstraints = false
		infoLabel.adjustsFontForContentSizeCategory = true
		infoLabel.textAlignment = .center
		infoLabel.font = UIFont.preferredFont(forTextStyle: .headline)
		view.addSubview(infoLabel)

		connectionActivityView.translatesAutoresizingMaskIntoConstraints = false
		connectionActivityView.hidesWhenStopped = true
		view.addSubview(connectionActivityView)

		NSLayoutConstraint.activate([
			iconImageView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
			iconImageView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor, constant: -bottomMargin),
			iconImageView.heightAnchor.constraint(equalToConstant: iconImageSize.height),
			iconImageView.widthAnchor.constraint(equalToConstant: iconImageSize.width),

			metadataInfoLabel.centerXAnchor.constraint(equalTo: iconImageView.centerXAnchor),
			metadataInfoLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: verticalSpacing),
			metadataInfoLabel.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: horizontalSpacing),
			metadataInfoLabel.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -horizontalSpacing),

			progressView.centerXAnchor.constraint(equalTo: iconImageView.centerXAnchor),
			progressView.widthAnchor.constraint(equalTo: iconImageView.widthAnchor),
			progressView.topAnchor.constraint(equalTo: metadataInfoLabel.bottomAnchor, constant: progressViewVerticalSpacing),

			cancelButton.centerXAnchor.constraint(equalTo: iconImageView.centerXAnchor),
			cancelButton.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: verticalSpacing),

			showPreviewButton.centerXAnchor.constraint(equalTo: iconImageView.centerXAnchor),
			showPreviewButton.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: verticalSpacing),

			infoLabel.centerXAnchor.constraint(equalTo: metadataInfoLabel.centerXAnchor),
			infoLabel.topAnchor.constraint(equalTo: metadataInfoLabel.bottomAnchor, constant: verticalSpacing),
			infoLabel.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: horizontalSpacing),
			infoLabel.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -horizontalSpacing),

			connectionActivityView.centerXAnchor.constraint(equalTo: iconImageView.centerXAnchor),
			connectionActivityView.topAnchor.constraint(equalTo: infoLabel.bottomAnchor, constant: verticalSpacing)
		])
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		Theme.shared.register(client: self)
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		startQuery()

		updateDisplayTitleAndButtons()
		updateUI()
	}

	// MARK: - Actions which can be triggered by the user

	@objc func cancelDownload(sender: Any? = nil) {
		if downloadProgress != nil {
			downloadProgress?.cancel()
		}
		self.state = .downloadCanceled
	}

	@objc func downloadItem(sender: Any? = nil) {
		guard let core = core, let item = item, self.state == .online else {
			return
		}

		let downloadOptions : [OCCoreOption : Any] = [
			.returnImmediatelyIfOfflineOrUnavailable : true
		]

		self.state = .downloadInProgress

		Log.debug(tagged: ["VersionUpdates"], "Downloading file at \(item.path ?? "")..")

		self.downloadProgress = core.downloadItem(item, options: downloadOptions, resultHandler: { [weak self] (error, _, latestItem, _) in
			guard error == nil else {
				OnMainThread {
					if (error as NSError?)?.isOCError(withCode: .itemNotAvailableOffline) == true {
						self?.state = .offline
					} else {
						self?.state = .downloadFailed
					}
				}
				return
			}

			self?.state = .downloadFinished
			self?.item = latestItem
		})

		if let progress = self.downloadProgress {
			self.progressView.observedProgress = self.downloadProgress
			self.progressSummarizer?.startTracking(progress: progress)
		}
	}

	@objc func optionsBarButtonPressed(_ sender: UIBarButtonItem) {
		guard let core = core, let item = item else {
			return
		}

		let actionsLocation = OCExtensionLocation(ofType: .action, identifier: .moreDetailItem)
		let actionContext = ActionContext(viewController: self, core: core, items: [item], location: actionsLocation, sender: sender)

		if let moreViewController = Action.cardViewController(for: item, with: actionContext, completionHandler: nil) {
			self.present(asCard: moreViewController, animated: true)
		}
	}

	// MARK: - Update control
	enum UpdateStrategy {
		case ask
		case alwaysUpdate
		case neverUpdate
	}
	var updateStrategy : UpdateStrategy = .ask
	var allowUpdatesUntilLocalModificationPersists : Bool = false

	func shouldRenderItem(item: OCItem, isUpdate: Bool, shouldRender: @escaping (Bool) -> Void) {
		if isUpdate {
			if allowUpdatesUntilLocalModificationPersists {
				if !item.locallyModified {
					// once the modified file has been uploaded, item.locallyModified will no longer be true,
					// so any changes after that will again be subject to the regular .updateStrategy procedure
					allowUpdatesUntilLocalModificationPersists = false
				}
				shouldRender(true)
			} else {
				switch updateStrategy {
					case .ask:
						OnMainThread {
							let alert = UIAlertController(title: NSString(format: "%@ was updated".localized as NSString, item.name ?? "File".localized) as String, message: "Would you like to view the updated version?".localized, preferredStyle: .alert)

							alert.addAction(UIAlertAction(title: "Show new version".localized, style: .default, handler: { [weak self] (_) in
								self?.updateStrategy = .ask
								shouldRender(true)
							}))
							alert.addAction(UIAlertAction(title: "Refresh without asking".localized, style: .default, handler: { [weak self] (_) in
								self?.updateStrategy = .alwaysUpdate
								shouldRender(true)
							}))
							alert.addAction(UIAlertAction(title: "Ignore updates".localized, style: .cancel, handler: { [weak self] (_) in
								self?.updateStrategy = .neverUpdate
								shouldRender(false)
							}))

							self.present(alert, animated: true)
						}

					case .alwaysUpdate:
						shouldRender(true)

					case .neverUpdate:
						shouldRender(false)
				}
			}
		} else {
			shouldRender(true)
		}
	}

	// MARK: - Methods to be overriden in subclasses

	func renderItem(completion: @escaping  (_ success:Bool) -> Void) {
		// This function is intended to be overwritten by the subclases to implement a custom view based on the itemDirectURL property.s
		completion(true)
	}

	// Override in subclasses and implement specific checks if required
	var canPreviewCurrentItem : Bool {
		// Only subclasses can render a preview, superclass can't
		if type(of: self) === DisplayViewController.self {
			return false
		}

		return true
	}

	// Can be overriden in subclasses e.g. if item can be previewed without downloadint it (e.g. streamable video
	var requiresLocalCopyForPreview : Bool {
		if type(of: self) === DisplayViewController.self {
			return false
		}
		return true
	}

	// MARK: - UI management
	@objc var displayTitle : String?
	@objc var displayBarButtonItems : [UIBarButtonItem]?

	private func updateDisplayTitleAndButtons() {
		if let itemName = item?.name {
			displayTitle = itemName

			if let queryState = query?.state {
				displayBarButtonItems = composedDisplayBarButtonItems(previous: displayBarButtonItems, itemName: itemName, itemRemoved: queryState == .targetRemoved)
			}
		}
	}

	var actionBarButtonItem : UIBarButtonItem {
		let itemName = item?.name ?? ""
		let actionsBarButtonItem = UIBarButtonItem(image: UIImage(named: "more-dots"), style: .plain, target: self, action: #selector(optionsBarButtonPressed))
		actionsBarButtonItem.tag = moreButtonTag
		actionsBarButtonItem.accessibilityLabel = itemName + " " + "Actions".localized

		return actionsBarButtonItem
	}

	func composedDisplayBarButtonItems(previous: [UIBarButtonItem]? = nil, itemName: String, itemRemoved: Bool = false) -> [UIBarButtonItem]? {
		if !itemRemoved {
			if previous?.filter({ (buttonItemTag) -> Bool in
				return buttonItemTag.tag == moreButtonTag
			}).count == 0 || previous == nil {
				return [ actionBarButtonItem ]
			} else {
				return previous
			}
		}

		return [ ]
	}

	private func updateUI() {

		func hideProgressIndicators() {
			self.downloadProgress = nil
			self.progressView.progress = 0.0
			self.progressView.isHidden = true
			self.cancelButton.isHidden = true
			self.infoLabel.isHidden = true
		}

		switch self.state {
		case .initial:
			hideProgressIndicators()
			showPreviewButton.isHidden = true

		case .online:
			connectionActivityView.stopAnimating()
			hideProgressIndicators()
			showPreviewButton.isHidden = true

			if let item = self.item, !canPreviewCurrentItem {
				if self.core?.localCopy(of:item) == nil {
					showPreviewButton.isHidden = false
					showPreviewButton.setTitle("Download".localized, for: .normal)
				}
			}

		case .connecting:
			infoLabel.isHidden = false
			infoLabel.text = "Connecting...".localized
			connectionActivityView.startAnimating()

		case .offline:
			connectionActivityView.stopAnimating()
			progressView.isHidden = true
			cancelButton.isHidden = true
			showPreviewButton.isHidden = true
			infoLabel.isHidden = false
			infoLabel.text = "Network unavailable".localized

		case .downloadFailed, .downloadCanceled:
			if self.connectionStatus == .online {
				hideProgressIndicators()
			}

		case .downloadInProgress:
			progressView.isHidden = false
			cancelButton.isHidden = false
			infoLabel.isHidden = true
			showPreviewButton.isHidden = true

		case .downloadFinished:
			cancelButton.isHidden = true
			progressView.isHidden = true
			showPreviewButton.isHidden = true

			if canPreviewCurrentItem {
				iconImageView.isHidden = true
				progressView.isHidden = true
				metadataInfoLabel.isHidden = true
				infoLabel.isHidden = true
				cancelButton.isHidden = true
			}

		case .previewFailed:
			iconImageView.isHidden = false
			infoLabel.text = "File couldn't be opened".localized
			infoLabel.isHidden = false
		}
	}

	// MARK: - Query management

	private func startQuery() {
		if query == nil, let item = item, let core = core {
			query = OCQuery(item: item)

			if let query = query {
				query.delegate = self
				core.start(query)
			}
		}
	}

	private func stopQuery() {
		if let core = core, let query = query {
			self.query = nil
			query.delegate = nil
			core.stop(query)
		}
	}

	private var lastUsedItem : OCItem?
	private var lastUsedItemVersion : OCItemVersionIdentifier?
	private var lastUsedItemModificationDate : Date?

	private var lastRenderSuccessful : Bool?

	private func considerUpdate() {
		var localURLLastModified : Date?
		let oldItem = lastUsedItem

		if let newItem = item {
			if let localURL = core?.localCopy(of: newItem) {
				do {
					localURLLastModified  = (try localURL.resourceValues(forKeys: [ .contentModificationDateKey ])).contentModificationDate
				} catch {
					Log.error("Error fetching last modification date of \(localURL): \(error)")
				}
			}

			let localCopyVanished = (newItem.localRelativePath == nil) && (oldItem?.localRelativePath != nil) && !newItem.syncActivity.contains(.downloading)

			if !newItem.syncActivity.contains(.updating) &&
			    (// Item version changed
			     (newItem.itemVersionIdentifier != oldItem?.itemVersionIdentifier) ||

			     // Item name changed
			     (newItem.name != oldItem?.name) ||

			     // Local copy vanished
			     localCopyVanished ||

			     // Item already shown, this version is different from what was shown last
			     ((lastUsedItemVersion != nil) && (newItem.itemVersionIdentifier != lastUsedItemVersion)) ||

			     // Item changed locally, exists locally, local file modification date changed
			     (newItem.locallyModified && (localURLLastModified != nil) && (localURLLastModified != lastUsedItemModificationDate))
			) {
				if let lastModified = localURLLastModified {
					lastUsedItemModificationDate = lastModified
				}

				if localCopyVanished, state == .downloadFinished, let currentStateByConnectionStatus = stateByConnectionStatus {
					state = currentStateByConnectionStatus
					itemDirectURL = nil
				}

				guard newItem.removed == false else {
					return
				}

				metadataInfoLabel.text = newItem.sizeLocalized + " - " + newItem.lastModifiedLocalized
				updateDisplayTitleAndButtons()

				if let core = self.core {
					let localCopy = core.localCopy(of: newItem)
					var didUpdate : Bool = false

					if localCopy == nil {
						iconImageView.setThumbnailImage(using: core, from: newItem, with: iconImageSize, avoidSystemThumbnails: true)
					}

					if iconImageView.image == nil {
						iconImageView.image = newItem.icon(fitInSize:iconImageSize)
					}

					// If we don't need to download item, just get direct URL (e.g. for video which can be streamed)
					if itemDirectURL == nil && !requiresLocalCopyForPreview {
						core.provideDirectURL(for: newItem, allowFileURL: true, completionHandler: { (error, url, authHeaders) in
							if error == nil {
								self.httpAuthHeaders = authHeaders
								self.itemDirectURL = url
								didUpdate = true
							}
						})
					} else {
						if requiresLocalCopyForPreview, 		  // Don't download automatically if the file can't be previewed +
						   !newItem.syncActivity.contains(.downloading),  // Avoid download if the file is already being downloaded	 +
						   ( // + either of:
							// - item version mismatch
							((lastUsedItemVersion != nil) && (newItem.itemVersionIdentifier != lastUsedItemVersion)) ||
							// - item locally modified or no itemDirectURL yet
							(newItem.locallyModified || itemDirectURL == nil)
						   ) {
							if let file = newItem.file(with: core),
							   let filePath = file.url?.path,
							   FileManager.default.fileExists(atPath: filePath) { // If file does not exist, force download, which will take care of this

								// Use existing local copy
								itemDirectURL = file.url
								didUpdate = true

								// Modify item's last used timestamp
								core.registerUsage(of: newItem, completionHandler: nil)
							} else {
								// Download item
								self.downloadItem()
								return
							}
						}
					}

					// Item rendering
					if itemDirectURL != nil, canPreviewCurrentItem, didUpdate, let item = item {
						// Determine if the item should be rendered
						shouldRenderItem(item: item, isUpdate: (lastRenderSuccessful == true)) { [weak self] (shouldRender) in
							if shouldRender {
								// Render item
								OnMainThread {
									self?.renderItem(completion: { (success) in
										self?.lastRenderSuccessful = success

										if !success {
											self?.state = .previewFailed
										}
									})
								}
							}
						}
					}
				}
			}
		}
	}

	// MARK: - Themeable implementation
	func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		progressView.applyThemeCollection(collection)
		cancelButton.applyThemeCollection(collection)
		metadataInfoLabel.applyThemeCollection(collection)
		showPreviewButton.applyThemeCollection(collection)
		infoLabel.applyThemeCollection(collection)
	}

	// MARK: - Query delegate
	func query(_ query: OCQuery, failedWithError error: Error) {
		// At the moment running query can inform the preview that item has changed or has been removed
		// Or we can get query error callback e.g. in case connection is lost etc. but if we still have an item,
		// user should be able to see it. Probably we won't provide much benefit by presenting such errors here.
	}

	func queryHasChangesAvailable(_ query: OCQuery) {
		query.requestChangeSet(withFlags: .onlyResults) { [weak self] (query, changeSet) in
			OnMainThread {
				Log.log("DisplayViewController.queryHasChangesAvailable: \(changeSet?.queryResult.description ?? "nil") - state: \(String(describing: query.state.rawValue))")

				switch query.state {
					case .idle, .contentsFromCache, .waitingForServerReply:
						if let firstItem = changeSet?.queryResult.first {
							self?.item = firstItem
						} else {
							// No item available
							Log.debug("Item \(String(describing: self?.item)) no longer available")
							self?.item = nil
						}

					case .targetRemoved: break

					default: break
				}

				self?.updateDisplayTitleAndButtons()
			}
		}
	}
}
