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
import ownCloudAppShared

class BookmarkInfoViewController: StaticTableViewController {
	var offlineStorageInfoRow: StaticTableViewRow?
	var deviceAvailableStorageInfoRow: StaticTableViewRow?

	var bookmark : OCBookmark?
	var completionHandler: (() -> Void)?

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
		offlineStorageInfoRow = StaticTableViewRow(valueRowWithAction: nil, title: OCLocalizedString("Offline files use", nil), value: OCLocalizedString("unknown", nil))
		let deviceFreeTitle = String(format: OCLocalizedString("Free on %@", nil), UIDevice.current.name)
		deviceAvailableStorageInfoRow = StaticTableViewRow(valueRowWithAction: nil, title: deviceFreeTitle, value: OCLocalizedString("unknown", nil))

		addSection(StaticTableViewSection(headerTitle: OCLocalizedString("Storage", nil), footerTitle: nil, identifier: "section-storage", rows: [ offlineStorageInfoRow!, deviceAvailableStorageInfoRow! ]))

		// Compacting
		let includeAvailableOfflineCopiesRow = StaticTableViewRow(switchWithAction: { [weak self] (row, _) in
			if (row.value as? Bool) == true {
				let alertController = ThemedAlertController(title: OCLocalizedString("Really include available offline files?", nil),
									message: OCLocalizedString("Files and folders marked as Available Offline will become unavailable. They will be re-downloaded next time you log into your account (connectivity required).", nil),
									preferredStyle: .alert)

				alertController.addAction(UIAlertAction(title: OCLocalizedString("Cancel", nil), style: .cancel, handler: { [weak row] (_) in
					row?.value = false
				}))
				alertController.addAction(UIAlertAction(title: OCLocalizedString("Proceed", nil), style: .default, handler: nil))

				self?.present(alertController, animated: true, completion: nil)
			}
			}, title: OCLocalizedString("Include available offline files", nil), value: false, identifier: "row-include-available-offline")

		let deleteLocalFilesRow = StaticTableViewRow(buttonWithAction: { [weak self] (row, _) in
			if let bookmark  = self?.bookmark {
				OCCoreManager.shared.scheduleOfflineOperation({ (bookmark, completionHandler) in
					let vault : OCVault = OCVault(bookmark: bookmark)

					OnMainThread {
						let progressView = UIActivityIndicatorView(style: Theme.shared.activeCollection.css.getActivityIndicatorStyle() ?? .medium)
						progressView.startAnimating()
						row.cell?.accessoryView = progressView
					}

					var includeAvailableOfflineCopies : Bool = (includeAvailableOfflineCopiesRow.value as? Bool) ?? false
					if VendorServices.shared.isBranded {
						includeAvailableOfflineCopies = true
					}

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
								let alertController = ThemedAlertController(title: NSString(format: OCLocalizedString("Compacting of '%@' failed", nil) as NSString, bookmark.shortName as NSString) as String,
																		message: error?.localizedDescription,
																		preferredStyle: .alert)

								alertController.addAction(UIAlertAction(title: OCLocalizedString("OK", nil), style: .default, handler: nil))

								self?.present(alertController, animated: true, completion: nil)
							}

							self?.updateStorageInfo()

							completionHandler()
						}
					})
				}, for: bookmark)
			}
		}, title: OCLocalizedString("Delete all Offline Files", nil), style: .destructive, alignment: .center, identifier: "row-offline-copies-delete")

		if VendorServices.shared.isBranded {
			addSection(StaticTableViewSection(headerTitle: "", footerTitle: OCLocalizedString("Removes downloaded files and local copies of items marked as Available Offline. The latter will be re-downloaded next time you log into your account (connectivity required).", nil), identifier: "section-compact", rows: [ deleteLocalFilesRow ]))
		} else {
			addSection(StaticTableViewSection(headerTitle: OCLocalizedString("Compacting", nil), footerTitle: nil, identifier: "section-compact", rows: [ includeAvailableOfflineCopiesRow, deleteLocalFilesRow ]))
		}

		if DiagnosticManager.shared.enabled {
			let showDiagnostics = StaticTableViewRow(rowWithAction: { [weak self] (_, _) in
				if let bookmark = self?.bookmark {
					let vault = OCVault(bookmark: bookmark)

					vault.open(completionHandler: { (_, error) in
						let done : () -> Void = {
							vault.close { (_, _) in
							}
						}

						if let database = vault.database, error == nil {
							OnBackgroundQueue {
								var diagnosticNodes : [OCDiagnosticNode] = []

								diagnosticNodes.append(contentsOf: database.diagnosticNodes(with: nil))
								diagnosticNodes.append(OCDiagnosticNode.withLabel(OCLocalizedString("Bookmark Metadata", nil), children: bookmark.diagnosticNodes(with: nil)))

								OnMainThread {
									self?.navigationController?.pushViewController(DiagnosticViewController(for: OCDiagnosticNode.withLabel(OCLocalizedString("Diagnostic Overview", nil), children: diagnosticNodes), context: nil), animated: true)
								}

								done()
							}
						} else {
							done()
						}
					})
				}
			}, title: OCLocalizedString("Diagnostic Overview", nil), accessoryType: .disclosureIndicator, identifier: "row-show-diagnostics")

			addSection(StaticTableViewSection(headerTitle: OCLocalizedString("Diagnostics", nil), footerTitle: nil, identifier: "section-diagnostics", rows: [ showDiagnostics ]))
		}
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	// MARK: - View controller events

	override func viewDidLoad() {
		super.viewDidLoad()
		self.navigationItem.title = OCLocalizedString("Manage", nil)
		self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(BookmarkInfoViewController.userActionDone))
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		updateStorageInfo()
	}

	// MARK: - User actions
	@objc func userActionDone() {
		let completionHandler = completionHandler

		self.presentingViewController?.dismiss(animated: true, completion: {
			completionHandler?()
		})
	}

	// MARK: - Helper methods
	private func updateStorageInfo() {
		if let bookmark = bookmark {
			if let vaultURL = OCVault(bookmark: bookmark).filesRootURL {
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
