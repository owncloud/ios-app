//
//  ShareViewController.swift
//  ownCloud Share Extension
//
//  Created by Matthias Hühne on 10.03.20.
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
import ownCloudAppShared
import CoreServices

extension NSErrorDomain {
	static let ShareViewErrorDomain = "ShareViewErrorDomain"
}

class ShareViewController: MoreStaticTableViewController {

	var appearedInitial = false

	override func viewDidLoad() {
		super.viewDidLoad()
		setupNavigationBar()
		setupAccountSelection()
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		if !appearedInitial {
			appearedInitial = true
			AppLockManager.shared.showLockscreenIfNeeded()
		}
	}

	@objc private func cancelAction () {
		let error = NSError(domain: NSErrorDomain.ShareViewErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey: "Canceled by user"])
		extensionContext?.cancelRequest(withError: error)
	}

	private func setupNavigationBar() {
		self.navigationItem.title = OCAppIdentity.shared.appDisplayName ?? "ownCloud"

		let itemCancel = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelAction))
		self.navigationItem.setRightBarButton(itemCancel, animated: false)
	}

	func setupAccountSelection() {
		let title = NSAttributedString(string: "Save File".localized, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 20, weight: .heavy)])

		var actionsRows: [StaticTableViewRow] = []
		OCBookmarkManager.shared.loadBookmarks()
		let bookmarks : [OCBookmark] = OCBookmarkManager.shared.bookmarks as [OCBookmark]
		if bookmarks.count > 0 {
			if bookmarks.count > 1 {
				let rowDescription = StaticTableViewRow(label: "Choose an account and folder to import into.".localized, alignment: .center)
				actionsRows.append(rowDescription)

				for (bookmark) in bookmarks {
					let row = StaticTableViewRow(buttonWithAction: { (_ row, _ sender) in
						OCCoreManager.shared.requestCore(for: bookmark, setup: nil, completionHandler: { (core, error) in
							if let core = core, error == nil {
								let directoryPickerViewController = ShareViewClientDirectoryPickerViewController(core: core, bookmark: bookmark, path: "/", selectButtonTitle: "Save here".localized, avoidConflictsWith: [], appearedInitial: self.appearedInitial, choiceHandler: { (selectedDirectory, controller) in
									if let targetDirectory = selectedDirectory {
										controller.importFiles(to: targetDirectory, bookmark: bookmark, core: core)
									}
								})

								OnMainThread {
									self.navigationController?.pushViewController(directoryPickerViewController, animated: true)
								}
							}
						})
					}, title: bookmark.shortName, style: .plain, image: UIImage(named: "bookmark-icon")?.scaledImageFitting(in: CGSize(width: 25.0, height: 25.0)), imageWidth: 25, alignment: .left)
					actionsRows.append(row)
				}

				self.addSection(MoreStaticTableViewSection(headerAttributedTitle: title, identifier: "actions-section", rows: actionsRows))
			}
		} else {
			let rowDescription = StaticTableViewRow(label: "No account configured.\nSetup an new account in the app to save to.".localized, alignment: .center)
			actionsRows.append(rowDescription)

			self.addSection(MoreStaticTableViewSection(headerAttributedTitle: title, identifier: "actions-section", rows: actionsRows))
		}
	}
}
