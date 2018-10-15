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

enum DisplayViewState {
	case hasNetworkConnection
	case noNetworkConnection
	case downloading(progess: Progress)
	case errorDownloading(error: Error?)
	case canceledDownload
}

protocol DisplayViewEditingDelegate: class {
	func save(item: OCItem, fileURL newVersion: URL)
}

class DisplayViewController: UIViewController {

	private let IconImageViewSize: CGSize = CGSize(width: 200.0, height: 200.0)

	// MARK: - Instance variables
	var source: URL! {
		didSet {
			OnMainThread {
				self.iconImageView.isHidden = true
			}
			renderSpecificView()
		}
	}

	required init() {
		observerContext = UnsafeMutableRawPointer(&observerContextValue)
		super.init(nibName: nil, bundle: nil)
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	private var state: DisplayViewState = DisplayViewState.hasNetworkConnection {
		didSet {
			OnMainThread {
				self.render()
			}
		}
	}
	weak var item: OCItem!
	weak var core: OCCore! {
		didSet {
			core.addObserver(self, forKeyPath: "reachabilityMonitor.available", options: [.initial, .new], context: observerContext)
		}
	}
	weak var editingDelegate: DisplayViewEditingDelegate?

	private var iconImageView: UIImageView!
	private var progressView : UIProgressView?
	private var cancelButton : UIButton?
	private var metadataInfoLabel: UILabel?
	private var showPreviewButton: UIButton?
	private var noNetworkLabel : UILabel?

	public var downloadProgress : Progress? {
		didSet {
			progressView?.observedProgress = downloadProgress
		}
	}

	// MARK: - Load view
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
		cancelButton?.addTarget(self, action: #selector(cancelDownload(sender:)), for: UIControlEvents.touchUpInside)

		view.addSubview(cancelButton!)

		showPreviewButton = ThemeButton(type: .system)
		showPreviewButton?.translatesAutoresizingMaskIntoConstraints = false
		showPreviewButton?.setTitle("Open file".localized, for: .normal)
		showPreviewButton?.isHidden = true
		showPreviewButton?.addTarget(self, action: #selector(downloadItem), for: UIControlEvents.touchUpInside)
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
			iconImageView.heightAnchor.constraint(equalToConstant: IconImageViewSize.height),
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

		iconImageView.image = item.icon(fitInSize:IconImageViewSize)

		if item.thumbnailAvailability != .none {
			let displayThumbnail = { (thumbnail: OCItemThumbnail?) in
				_ = thumbnail?.requestImage(for: self.IconImageViewSize, scale: 0, withCompletionHandler: { (thumbnail, error, _, image) in
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
				_ = core?.retrieveThumbnail(for: item, maximumSize: IconImageViewSize, scale: 0, retrieveHandler: { (_, _, _, thumbnail, _, _) in
					displayThumbnail(thumbnail)
				})
			}
		}

		Theme.shared.register(client: self)

		guard let parent = parent else {
			return
		}

		parent.navigationItem.title = item.name
	}

	deinit {
		Theme.shared.unregister(client: self)
		self.downloadProgress?.cancel()
		core.removeObserver(self, forKeyPath: "reachabilityMonitor.available", context: observerContext)
	}

	@objc func cancelDownload(sender: Any?) {
		self.state = .canceledDownload
	}

	@objc func downloadItem(sender: Any?) {
		self.showPreviewButton?.isHidden = true
		if core.reachabilityMonitor.available {
			if let downloadProgress = self.core.downloadItem(item, options: nil, resultHandler: { [weak self] (error, _, _, file) in
				guard error == nil else {
					OnMainThread {
						self?.state = .errorDownloading(error: error!)
						print("LOG ---> error distinto de nil \(error!)")
					}
					return
				}
				OnMainThread {
					self?.source = file!.url
				}
			}) {
				self.state = .downloading(progess: downloadProgress)
			}
		}
	}

	func renderSpecificView() {
		// This function is intended to be overwritten by the subclases to implement a custom view based on the source property.s
	}

	private var observerContextValue = 1
	private var observerContext : UnsafeMutableRawPointer
	private var token: NSKeyValueObservation?

	// swiftlint:disable block_based_kvo
	// Would love to use the block-based KVO, but it doesn't seem to work when used on the .state property of the query :-(
	override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
		if let newValue = change?[NSKeyValueChangeKey.newKey] as? Bool {
			if newValue {
				self.state = .hasNetworkConnection
			} else {
				self.state = .noNetworkConnection
			}
		}
	}
	// swiftlint:enable block_based_kvo

	private func render() {
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
		}
	}

	private func hideProgressIndicators() {
		self.progressView?.progress = 0.0
		self.progressView?.isHidden = true
		self.cancelButton?.isHidden = true
		self.noNetworkLabel?.isHidden = true
		self.showPreviewButton?.isHidden = false
	}
}

extension DisplayViewController : Themeable {
	func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		progressView?.applyThemeCollection(collection)
		cancelButton?.applyThemeCollection(collection)
		metadataInfoLabel?.applyThemeCollection(collection)
		showPreviewButton?.applyThemeCollection(collection)
		noNetworkLabel?.applyThemeCollection(collection)
	}
}
