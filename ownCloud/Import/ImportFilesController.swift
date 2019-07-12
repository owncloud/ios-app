//
//  ImportFilesController.swift
//  ownCloud
//
//  Created by Matthias Hühne on 10.07.19.
//  Copyright © 2019 ownCloud GmbH. All rights reserved.
//

/*
* Copyright (C) 2019, ownCloud GmbH.
*
* This code is covered by the GNU Public License Version 3.
*
* For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
* You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
*
*/

import UIKit
import ownCloudSDK

class ImportFilesController: NSObject {

	// MARK: - Instance variables
	var url: URL

	// MARK: - Init & Deinit
	init(url: URL) {
		self.url = url
	}

}

extension ImportFilesController {

	func accountOrImportUI() -> Bool {
		let bookmarks : [OCBookmark] = OCBookmarkManager.shared.bookmarks as [OCBookmark]

		if bookmarks.count > 1 {
			let moreViewController = self.cardViewController(for: url)
			if let wd = UIApplication.shared.delegate?.window {
				let vc = wd!.rootViewController
				if let navCon = vc as? UINavigationController, let topVC = navCon.visibleViewController {
					OnMainThread {
						topVC.present(asCard: moreViewController, animated: true)
					}
				} else {
					OnMainThread {
						vc?.present(asCard: moreViewController, animated: true)
					}
				}

				return true
			}
		} else if bookmarks.count == 1, let bookmark = bookmarks.first {
			self.importItemWithDirectoryPicker(with: url, into: bookmark)

			return true
		}

		return false
	}

	func importItemWithDirectoryPicker(with url : URL, into bookmark: OCBookmark) {
		OCCoreManager.shared.requestCore(for: bookmark, setup: { (_, _) in
		}, completionHandler: { (core, error) in
			if error == nil {
				OnMainThread {
					let directoryPickerViewController = ClientDirectoryPickerViewController(core: core!, path: "/", selectButtonTitle: "Save here".localized, avoidConflictsWith: [], choiceHandler: { [weak self] (selectedDirectory) in

						if let targetDirectory = selectedDirectory {
							self?.importFile(url: url, to: targetDirectory, core: core)
						}
					})

					let pickerNavigationController = ThemeNavigationController(rootViewController: directoryPickerViewController)

					if let wd = UIApplication.shared.delegate?.window {
						let vc = wd!.rootViewController
						if let navCon = vc as? UINavigationController, let topVC = navCon.visibleViewController {
							topVC.present(pickerNavigationController, animated: true)
						} else {
							vc?.present(pickerNavigationController, animated: true)
						}
					}
				}
			}
		})
	}

	func importFile(url : URL, to targetDirectory : OCItem, core : OCCore?) {
		let name = url.lastPathComponent
		if let progress = core?.importFileNamed(name,
												at: targetDirectory,
												from: url,
												isSecurityScoped: false,
												options: [OCCoreOption.importByCopying : true,
														  OCCoreOption.automaticConflictResolutionNameStyle : OCCoreDuplicateNameStyle.bracketed.rawValue],
												placeholderCompletionHandler: { (error, item) in
													if error != nil {
														Log.debug("Error uploading \(Log.mask(name)) to \(Log.mask(targetDirectory.path)), error: \(error?.localizedDescription ?? "" )")
													}
		},
												resultHandler: { (error, _ core, _ item, _) in
													if error != nil {
														Log.debug("Error uploading \(Log.mask(name)) to \(Log.mask(targetDirectory.path)), error: \(error?.localizedDescription ?? "" )")
													} else {
														Log.debug("Success uploading \(Log.mask(name)) to \(Log.mask(targetDirectory.path))")

														let fileManager = FileManager.default
														do {
															try fileManager.removeItem(at: url)
														} catch let error as NSError {
															Log.debug("Error deleting file \(Log.mask(url)) error: \(error.localizedDescription)")
														}
													}
		}) {
		} else {
			Log.debug("Error setting up upload of \(Log.mask(name)) to \(Log.mask(targetDirectory.path))")
		}
	}

	func cardViewController(for url: URL) -> UIViewController {
		let tableViewController = MoreStaticTableViewController(style: .grouped)
		let header = MoreViewHeader(url: url)
		let moreViewController = MoreViewController(header: header, viewController: tableViewController)

		let title = NSAttributedString(string: "Save File".localized, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 20, weight: .heavy)])

		var actionsRows: [StaticTableViewRow] = []
		let bookmarks : [OCBookmark] = OCBookmarkManager.shared.bookmarks as [OCBookmark]

		let rowDescription = StaticTableViewRow(label: "Select an account where to import the file and choose a destination directory.".localized, alignment: .center)
		actionsRows.append(rowDescription)

		for (bookmark) in bookmarks {
			let row = StaticTableViewRow(buttonWithAction: { (_ row, _ sender) in
				moreViewController.dismiss(animated: true, completion: {
					self.importItemWithDirectoryPicker(with: url, into: bookmark)
				})
				}, title: bookmark.shortName, style: .plain, image: Theme.shared.image(for: "owncloud-logo", size: CGSize(width: 25, height: 25)), imageWidth: 25, alignment: .left)
			actionsRows.append(row)
		}

		let row = StaticTableViewRow(buttonWithAction: { (_ row, _ sender) in
			moreViewController.dismiss(animated: true, completion: nil)
		}, title: "Cancel".localized, style: .destructive, alignment: .center)
		actionsRows.append(row)

		tableViewController.addSection(MoreStaticTableViewSection(headerAttributedTitle: title, identifier: "actions-section", rows: actionsRows))

		return moreViewController
	}
}
