//
//  BookmarkInfoViewController
//  ownCloud
//
//  Created by Michael Neuwert on 09.05.19.
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
import ownCloudUI

class BookmarkInfoViewController: StaticTableViewController {
	var offlineStorageInfoRow: StaticTableViewRow?
	var deviceAvailableStorageInfoRow: StaticTableViewRow?

	var bookmark : OCBookmark?

	lazy var byteCounterFormatter: ByteCountFormatter = {
		let formatter = ByteCountFormatter()
		formatter.allowsNonnumericFormatting = false
		return formatter
	}()

	// MARK: - Init & Deinit
	init(_ bookmark: OCBookmark?) {
		super.init(style: .grouped)
		self.bookmark = bookmark

		// Storage
		offlineStorageInfoRow = StaticTableViewRow(valueRowWithAction: nil, title: "Offline files use".localized, value: "unknown".localized)
		let deviceFreeTitle = String(format: "Free on %@".localized, UIDevice.current.name)
		deviceAvailableStorageInfoRow = StaticTableViewRow(valueRowWithAction: nil, title: deviceFreeTitle, value: "unknown".localized)

		addSection(StaticTableViewSection(headerTitle: "Storage".localized, footerTitle: nil, identifier: "section-storage", rows: [ offlineStorageInfoRow!, deviceAvailableStorageInfoRow! ]))

		// Compacting
		let includeAvailableOfflineCopiesRow = StaticTableViewRow(switchWithAction: { [weak self] (row, _) in
			if (row.value as? Bool) == true {
				let alertController = UIAlertController(title: "Really include available offline files?".localized,
									message: "Files and folders marked as Available Offline will become unavailable. They will be re-downloaded next time you log into your account (connectivity required).".localized,
									preferredStyle: .alert)

				alertController.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel, handler: { [weak row] (_) in
					row?.value = false
				}))
				alertController.addAction(UIAlertAction(title: "Proceed".localized, style: .default, handler: nil))

				self?.present(alertController, animated: true, completion: nil)
			}
		}, title: "Include available offline files", value: false, identifier: "row-include-available-offline")

		let deleteLocalFilesRow = StaticTableViewRow(buttonWithAction: { [weak self] (row, _) in
			if let bookmark  = self?.bookmark {

				OCCoreManager.shared.scheduleOfflineOperation({ (bookmark, completionHandler) in
					let vault : OCVault = OCVault(bookmark: bookmark)

					OnMainThread {
						let progressView = UIActivityIndicatorView(style: Theme.shared.activeCollection.activityIndicatorViewStyle)
						progressView.startAnimating()
						row.cell?.accessoryView = progressView
					}

					let includeAvailableOfflineCopies : Bool = (includeAvailableOfflineCopiesRow.value as? Bool) ?? false

					let compactingSelector : OCVaultCompactSelector? = (includeAvailableOfflineCopies == false) ? { (_, item) -> Bool in
						return item.downloadTriggerIdentifier != .availableOffline
					} : nil

					if includeAvailableOfflineCopies {
						// Skip available offline until user opens the bookmark again
						vault.keyValueStore?.storeObject(true as NSNumber, forKey: .coreSkipAvailableOfflineKey)
					}

					vault.compact(selector: compactingSelector, completionHandler: { (_, error) in
						OnMainThread {
							row.cell?.accessoryView = nil
							if error != nil {
								// Inform user if vault couldn't be comp acted
								let alertController = UIAlertController(title: NSString(format: "Compacting of '%@' failed".localized as NSString, bookmark.shortName as NSString) as String,
																		message: error?.localizedDescription,
																		preferredStyle: .alert)

								alertController.addAction(UIAlertAction(title: "OK".localized, style: .default, handler: nil))

								self?.present(alertController, animated: true, completion: nil)
							}

							self?.updateStorageInfo()

							completionHandler()
						}
					})
				}, for: bookmark)
			}
		}, title: "Delete Local Copies".localized, style: .destructive, identifier: "row-offline-copies-delete")

		addSection(StaticTableViewSection(headerTitle: "Compacting".localized, footerTitle: nil, identifier: "section-compact", rows: [ includeAvailableOfflineCopiesRow, deleteLocalFilesRow ]))
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	// MARK: - View controller events

	override func viewDidLoad() {
		super.viewDidLoad()
		self.navigationItem.title = "Manage".localized
		self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(BookmarkInfoViewController.userActionDone))
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		updateStorageInfo()
	}

	// MARK: - User actions
	@objc func userActionDone() {
		self.presentingViewController?.dismiss(animated: true, completion: nil)
	}

	// MARK: - Helper methods
	private func updateStorageInfo() {
		if bookmark != nil {
			if let vaultURL = OCVault(bookmark: bookmark!).filesRootURL {
				FileManager.default.calculateDirectorySize(at: vaultURL) { (size) in
					if size != nil {
						let occupiedSpace = self.byteCounterFormatter.string(fromByteCount: size!)
						OnMainThread {
							self.offlineStorageInfoRow?.value = occupiedSpace
						}
					}
				}
			}
		}
		let deviceFreeByteCount = FileManager.default.availableFreeStorageSpace()
		if deviceFreeByteCount >= 0 {
			deviceAvailableStorageInfoRow?.value = self.byteCounterFormatter.string(fromByteCount: deviceFreeByteCount)
		}
	}
}
