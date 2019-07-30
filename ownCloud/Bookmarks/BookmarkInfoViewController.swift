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
	var storageSection : StaticTableViewSection?
	var offlineStorageInfoRow: StaticTableViewRow?
	var deviceAvailableStorageInfoRow: StaticTableViewRow?
	var deleteLocalFilesRow : StaticTableViewRow?

	var bookmark : OCBookmark?

	lazy var byteCounterFormatter: ByteCountFormatter = {
		let formatter = ByteCountFormatter()
		formatter.allowsNonnumericFormatting = false
		return formatter
	}()

	// MARK: - Init & Deinit
	init(_ bookmark: OCBookmark?) {
		// Super init
		super.init(style: .grouped)
		self.bookmark = bookmark

		offlineStorageInfoRow = StaticTableViewRow(valueRowWithAction: nil, title: "Offline files use".localized, value: "unknown".localized)
		let deviceFreeTitle = String(format: "Free on %@".localized, UIDevice.current.name)
		deviceAvailableStorageInfoRow = StaticTableViewRow(valueRowWithAction: nil, title: deviceFreeTitle, value: "unknown".localized)

		deleteLocalFilesRow = StaticTableViewRow(buttonWithAction: { [weak self] (_, _) in
			if let bookmark  = self?.bookmark {

				OCCoreManager.shared.scheduleOfflineOperation({ (bookmark, completionHandler) in
					let vault : OCVault = OCVault(bookmark: bookmark)

					vault.compact(completionHandler: { (_, error) in
						OnMainThread {
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

		storageSection = StaticTableViewSection(headerTitle: "Storage".localized, footerTitle: nil, identifier: "section-credentials", rows: [ offlineStorageInfoRow!, deviceAvailableStorageInfoRow!, deleteLocalFilesRow! ])

		self.insertSection(storageSection!, at: 0, animated: false)
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
