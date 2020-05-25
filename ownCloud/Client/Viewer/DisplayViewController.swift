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
}

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

class DisplayViewController: UIViewController {

	var item: OCItem?
	var itemIndex: Int?

	private let iconImageSize: CGSize = CGSize(width: 200.0, height: 200.0)
	private let bottomMargin: CGFloat = 60.0
	private let verticalSpacing: CGFloat = 10.0
	private let horizontalSpacing: CGFloat = 10
	private let progressViewVerticalSpacing: CGFloat = 20.0

	private var connectionStatus: OCCoreConnectionStatus? {
		didSet {
			if let status = connectionStatus {
				switch status {
				case .connecting:
					self.state = .connecting
				case .offline:
					self.state = .offline
					stopQuery()
				case .online:
					self.state = .online
					self.updateSource()
					self.startQuery()

				default:
					break
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
			if let core = core {
				coreConnectionStatusObservation = core.observe(\OCCore.connectionStatus, options: [.initial, .new]) { [weak self] (_, _) in
					OnMainThread {
						self?.connectionStatus = core.connectionStatus
					}
				}
			}
		}
	}

	private var lastSourceItemVersion : OCItemVersionIdentifier?
	private var lastSourceItemModificationDate : Date?

	var progressSummarizer : ProgressSummarizer?

	private var query : OCQuery?

	var source: URL? {
		didSet {
			guard self.source != nil else { return }

			guard self.canPreviewCurrentItem() else { return }

			lastSourceItemVersion = item?.localCopyVersionIdentifier ?? item?.itemVersionIdentifier

			OnMainThread(inline: true) {
				self.renderSpecificView(completion: { (success) in
					if !success {
						self.state = .previewFailed
					}
				})
			}
		}
	}

	var httpAuthHeaders: [String : String]?

	var shallDisplayMoreButtonInToolbar = true

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

	// MARK: - Initialization and de-initialization

	required init() {
		super.init(nibName: nil, bundle: nil)
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	deinit {
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
			infoLabel.widthAnchor.constraint(equalTo: iconImageView.widthAnchor),

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

		updateSource()
		startQuery()

		updateNavigationBarItems()

		self.updateUI()
	}

	// MARK: - Public API

	func present(item: OCItem) {
		guard item.removed == false else {
			return
		}

		self.item = item
		metadataInfoLabel.text = item.sizeLocalized + " - " + item.lastModifiedLocalized

		if let core = self.core {
			if core.localCopy(of: item) == nil {
				iconImageView.setThumbnailImage(using: core, from: item, with: iconImageSize, avoidSystemThumbnails: true)
			}

			if iconImageView.image == nil {
				iconImageView.image = item.icon(fitInSize:iconImageSize)
			}
		}
	}

	// MARK: - Actions which can be triggered by the user

	@objc func cancelDownload(sender: Any?) {
		if downloadProgress != nil {
			downloadProgress?.cancel()
		}
		self.state = .downloadCanceled
	}

	@objc func downloadItem(sender: Any?) {
		guard let core = core, let item = item, self.state == .online else {
			return
		}

		let downloadOptions : [OCCoreOption : Any] = [
			.returnImmediatelyIfOfflineOrUnavailable : true,
			.addTemporaryClaimForPurpose : OCCoreClaimPurpose.view.rawValue
		]

		self.state = .downloadInProgress

		self.downloadProgress = core.downloadItem(item, options: downloadOptions, resultHandler: { [weak self] (error, _, latestItem, file) in
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
			self?.source = file?.url

			if let claim = file?.claim, let item = latestItem, let self = self {
				self.core?.remove(claim, on: item, afterDeallocationOf: [self])
			}
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

		let actionsLocation = OCExtensionLocation(ofType: .action, identifier: .moreItem)
		let actionContext = ActionContext(viewController: self, core: core, items: [item], location: actionsLocation, sender: sender)

		if let moreViewController = Action.cardViewController(for: item, with: actionContext, completionHandler: nil) {
			self.present(asCard: moreViewController, animated: true)
		}
	}

	// MARK: - Methods to be overriden in subclasses

	func renderSpecificView(completion: @escaping  (_ success:Bool) -> Void) {
		// This function is intended to be overwritten by the subclases to implement a custom view based on the source property.s
		fatalError("*** Subclass must implement renderSpecificView() method ***")
	}

	// Override in subclasses and implement specific checks if required
	func canPreviewCurrentItem() -> Bool {
		// Only subclasses can render a preview, superclass can't
		if type(of: self) === DisplayViewController.self {
			return false
		}

		return true
	}

	// Can be overriden in subclasses e.g. if item can be previewed without downloadint it (e.g. streamable video
	func requiresLocalCopyForPreview() -> Bool {
		if type(of: self) === DisplayViewController.self {
			return false
		}
		return true
	}

	// MARK: - UI management

	func updateNavigationBarItems() {
		if let parent = parent, let itemName = item?.name {
			parent.navigationItem.title = itemName

			if shallDisplayMoreButtonInToolbar, let queryState = query?.state {
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

			if let item = self.item, self.canPreviewCurrentItem() == false {
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

			if self.canPreviewCurrentItem() {
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

	private func updateSource() {
		guard let item = self.item else { return }

		// If we don't need to download item, just get direct URL (e.g. for video which can be streamed)
		if source == nil && requiresLocalCopyForPreview() == false {
			core?.provideDirectURL(for: item, allowFileURL: true, completionHandler: { (error, url, authHeaders) in
				if error == nil {
					self.httpAuthHeaders = authHeaders
					self.source = url
				}
			})
			return
		}

		// Don't download automatically if the file can't be previewed
		guard requiresLocalCopyForPreview() == true else { return }

		// Bail out if the download is already in progress
		guard item.syncActivity.contains(.downloading) == false else { return }

		var shallUpdateItem = false

		// Item version mismatch?
		if (lastSourceItemVersion != nil) && (item.itemVersionIdentifier != lastSourceItemVersion) {
			shallUpdateItem = true
		}

		// Item locally modified or source URL is missing?
		if item.locallyModified || source == nil {
			shallUpdateItem = true
		}

		if shallUpdateItem == true {
			if core?.localCopy(of: item) == nil {
				self.downloadItem(sender: nil)
			} else {
				// We already have a local copy, just modify item's last used timestamp
				core?.registerUsage(of: item, completionHandler: nil)
				if let core = core, let file = item.file(with: core) {
					self.source = file.url
				}
			}
		}
	}
}

extension DisplayViewController : OCQueryDelegate {

	func query(_ query: OCQuery, failedWithError error: Error) {
		// At the moment running query can inform the preview that item has changed or has been removed
		// Or we can get query error callback e.g. in case connection is lost etc. but if we still have an item,
		// user should be able to see it. Probably we won't provide much benefit by presenting such errors here.
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
}

// MARK: - Configuration

extension DisplayViewController {
	func configure(_ configuration: DisplayViewConfiguration) {
		self.item = configuration.item
		self.core = configuration.core
	}
}

// MARK: - Themeable implementation

extension DisplayViewController : Themeable {
	func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		progressView.applyThemeCollection(collection)
		cancelButton.applyThemeCollection(collection)
		metadataInfoLabel.applyThemeCollection(collection)
		showPreviewButton.applyThemeCollection(collection)
		infoLabel.applyThemeCollection(collection)
		self.view.backgroundColor = collection.tableBackgroundColor
	}
}
