//
//  EditDocumentViewController.swift
//  ownCloud
//
//  Created by Matthias Hühne on 22.01.20.
//  Copyright © 2020 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2020, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import UIKit
import ownCloudSDK
import QuickLook

class EditDocumentViewController: QLPreviewController, Themeable {

	weak var item: OCItem?
	weak var core: OCCore?
	var completion: (EditDocumentViewController) -> Void
	var edited: Bool = false
	var modifiedContentsURL: URL?

	var source: URL? {
		didSet {
			if self.source != oldValue && self.source != nil {
				OnMainThread {
					self.reloadData()
				}
			}
		}
	}

	init(with item: OCItem? = nil, core: OCCore? = nil, completion: @escaping (EditDocumentViewController) -> Void) {
		self.item = item
		self.core = core
		self.completion = completion

		super.init(nibName: nil, bundle: nil)

		self.dataSource = self
		self.delegate = self
		self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissAnimated))

		Theme.shared.register(client: self, applyImmediately: true)
	}

	@objc func dismissAnimated() {
		print("--> modifiedContentsURL \(modifiedContentsURL)")
		if edited {
			var presentationStyle: UIAlertController.Style = .actionSheet
			if UIDevice.current.isIpad() {
				presentationStyle = .alert
			}

			let alertController = ThemedAlertController(title: "How should this file be saved?".localized,
								message: nil,
								preferredStyle: presentationStyle)
			alertController.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel, handler: nil))

			alertController.addAction(UIAlertAction(title: "Replace file".localized, style: .default, handler: { (_) in

				self.dismiss(animated: true, completion: nil)
			}))

			alertController.addAction(UIAlertAction(title: "Save as copy".localized, style: .default, handler: { (_) in

				self.dismiss(animated: true, completion: nil)

			}))

			alertController.addAction(UIAlertAction(title: "Discard changes".localized, style: .destructive, handler: { (_) in

				self.dismiss(animated: true, completion: nil)

			}))

			self.present(alertController, animated: true, completion: nil)
		} else {
			self.dismiss(animated: true, completion: nil)
		}
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	deinit {
		Theme.shared.unregister(client: self)
	}

    override func viewDidLoad() {
        super.viewDidLoad()

		if let item = item {
			self.present(item: item)
		}
    }

	func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		self.navigationController?.navigationBar.backgroundColor = collection.navigationBarColors.backgroundColor
		self.view.backgroundColor = collection.tableBackgroundColor
	}

	func present(item: OCItem) {
		guard self.view != nil, item.removed == false else {
			return
		}
		self.item = item

		if source == nil {
			if core?.localCopy(of: item) == nil {
				self.downloadItem(sender: nil)
			} else {
				core?.registerUsage(of: item, completionHandler: nil)
				if let core = core, let file = item.file(with: core) {
					self.source = file.url
				}
			}
		}
	}

	@objc func downloadItem(sender: Any?) {
		guard let core = core, let item = item else {
			return
		}

		if let downloadProgress = core.downloadItem(item, options: [
			.returnImmediatelyIfOfflineOrUnavailable : true,
			.addTemporaryClaimForPurpose 		 : OCCoreClaimPurpose.view.rawValue
		], resultHandler: { [weak self] (error, _, latestItem, file) in
			guard error == nil else {
				/*
				OnMainThread {
					if (error as NSError?)?.isOCError(withCode: .itemNotAvailableOffline) == true {
						self?.state = .noNetworkConnection
					} else {
						self?.state = .errorDownloading(error: error!)
					}
				}*/
				return
			}
			//self?.state = .downloadFinished

			self?.item = latestItem
			self?.source = file?.url

			if let claim = file?.claim, let item = latestItem, let self = self {
				self.core?.remove(claim, on: item, afterDeallocationOf: [self])
			}
		}) {
			//self.state = .downloading(progress: downloadProgress)

			//self.progressSummarizer?.startTracking(progress: downloadProgress)
		}
	}
}

extension EditDocumentViewController: QLPreviewControllerDataSource, QLPreviewControllerDelegate {
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
		return source != nil ? 1 : 0
    }

    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
		return source! as QLPreviewItem
    }

	@available(iOS 13.0, *)
	func previewController(_ controller: QLPreviewController, editingModeFor previewItem: QLPreviewItem) -> QLPreviewItemEditingMode {
        //return .updateContents
		return .createCopy
    }

    func previewController(_ controller: QLPreviewController, didUpdateContentsOf previewItem: QLPreviewItem) {
		edited = true
    }

    func previewController(_ controller: QLPreviewController, didSaveEditedCopyOf previewItem: QLPreviewItem, at modifiedContentsURL: URL) {
		self.modifiedContentsURL = modifiedContentsURL
		edited = true
    }
}
