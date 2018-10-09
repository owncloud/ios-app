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
		super.init(nibName: nil, bundle: nil)
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	var item: OCItem!
	var core: OCCore!
	weak var editingDelegate: DisplayViewEditingDelegate?

	private var iconImageView: UIImageView!
	private var progressView : UIProgressView?
	private var cancelButton : UIButton?

	public var downloadProgress : Progress? {
		didSet {
			progressView?.observedProgress = downloadProgress
			if downloadProgress != nil {
				progressView?.isHidden = false
				cancelButton?.isHidden = false
			} else {
				progressView?.isHidden = true
				cancelButton?.isHidden = true
			}
		}
	}

	// MARK: - Load view
	override func loadView() {
		super.loadView()

		iconImageView = UIImageView()
		iconImageView.translatesAutoresizingMaskIntoConstraints = false
		iconImageView.contentMode = .scaleAspectFit

		view.addSubview(iconImageView)

		progressView = UIProgressView(progressViewStyle: .bar)
		progressView?.translatesAutoresizingMaskIntoConstraints = false
		progressView?.progress = 0
		progressView?.observedProgress = downloadProgress
		progressView?.isHidden = (downloadProgress != nil)

		view.addSubview(progressView!)

		cancelButton = UIButton(type: .system)
		cancelButton?.translatesAutoresizingMaskIntoConstraints = false
		cancelButton?.setTitle("Cancel".localized, for: .normal)
		cancelButton?.isHidden = (downloadProgress != nil)
		cancelButton?.addTarget(self, action: #selector(cancelDownload(sender:)), for: UIControlEvents.touchUpInside)

		view.addSubview(cancelButton!)

		NSLayoutConstraint.activate([
			iconImageView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
			iconImageView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
			iconImageView.heightAnchor.constraint(equalToConstant: IconImageViewSize.height),
			iconImageView.widthAnchor.constraint(equalTo: iconImageView.heightAnchor),

			progressView!.centerXAnchor.constraint(equalTo: iconImageView.centerXAnchor),
			progressView!.widthAnchor.constraint(equalTo: iconImageView.widthAnchor),
			progressView!.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 20),

			cancelButton!.centerXAnchor.constraint(equalTo: iconImageView.centerXAnchor),
			cancelButton!.topAnchor.constraint(equalTo: progressView!.bottomAnchor, constant: 10)
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
	}

	@objc func cancelDownload(sender: Any?) {
		downloadProgress?.cancel()
	}

	func renderSpecificView() {
		// This function is intended to be overwritten by the subclases to implement a custom view based on the source property.s
	}

}

extension DisplayViewController : Themeable {
	func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		progressView?.applyThemeCollection(collection)
		cancelButton?.applyThemeCollection(collection)
	}
}
