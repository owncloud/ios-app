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

class ShareViewController: MoreStaticTableViewController {
	override func viewDidLoad() {
		super.viewDidLoad()

		OCItem.registerIcons()
		setupNavigationBar()

		let title = NSAttributedString(string: "Save File".localized, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 20, weight: .heavy)])

		var actionsRows: [StaticTableViewRow] = []
		let bookmarks : [OCBookmark] = OCBookmarkManager.shared.bookmarks as [OCBookmark]

		let rowDescription = StaticTableViewRow(label: "Choose an account and folder to import the file into.".localized, alignment: .center)
		actionsRows.append(rowDescription)

		for (bookmark) in bookmarks {
			let row = StaticTableViewRow(buttonWithAction: { (_ row, _ sender) in

				self.openDirectoryPicker(for: bookmark)
				/*
				moreViewController.dismiss(animated: true, completion: {
				self.importItemWithDirectoryPicker(with: url, into: bookmark)
				})*/
			}, title: bookmark.shortName, style: .plain, image: Theme.shared.image(for: "owncloud-logo", size: CGSize(width: 25, height: 25)), imageWidth: 25, alignment: .left)
			actionsRows.append(row)
		}

		self.addSection(MoreStaticTableViewSection(headerAttributedTitle: title, identifier: "actions-section", rows: actionsRows))
	}

	func openDirectoryPicker(for bookmark: OCBookmark ) {
		OCCoreManager.shared.requestCore(for: bookmark, setup: { (_, _) in
		}, completionHandler: { (core, error) in
			if let core = core, error == nil {
				let directoryPickerViewController = ClientDirectoryPickerViewController(core: core, path: "/", selectButtonTitle: "Save here".localized, avoidConflictsWith: [], choiceHandler: { (selectedDirectory) in
					if let targetDirectory = selectedDirectory {
						print("--> targetDire \(targetDirectory)")

						self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
						//self.importFile(url: url, to: targetDirectory, bookmark: bookmark, core: core)
					}
				})
				OnMainThread {
					self.navigationController?.pushViewController(directoryPickerViewController, animated: true)
				}
			}
		})
	}

	private func setupNavigationBar() {
		self.navigationItem.title = "ownCloud"

		let itemCancel = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelAction))
		self.navigationItem.setLeftBarButton(itemCancel, animated: false)

		let itemDone = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneAction))
		self.navigationItem.setRightBarButton(itemDone, animated: false)
	}

	@objc private func cancelAction () {
		let error = NSError(domain: "some.bundle.identifier", code: 0, userInfo: [NSLocalizedDescriptionKey: "An error description"])
		extensionContext?.cancelRequest(withError: error)
	}

	@objc private func doneAction() {
		extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
	}
}
