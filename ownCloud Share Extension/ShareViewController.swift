//
//  ShareViewController.swift
//  ownCloud Share Extension
//
//  Created by Matthias Hühne on 10.03.20.
//  Copyright © 2020 ownCloud GmbH. All rights reserved.
//

import UIKit
import ownCloudAppShared

class ShareViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        // 1: Set the background and call the function to create the navigation bar
        self.view.backgroundColor = .systemGray6
        setupNavBar()
    }

    // 2: Set the title and the navigation items
    private func setupNavBar() {
        self.navigationItem.title = "My app"

        let itemCancel = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelAction))
        self.navigationItem.setLeftBarButton(itemCancel, animated: false)

        let itemDone = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneAction))
        self.navigationItem.setRightBarButton(itemDone, animated: false)




		////////

/*
		OCCoreManager.shared.requestCore(for: bookmark, setup: { (_, _) in
		}, completionHandler: { (core, error) in
			if let core = core, error == nil {
				OnMainThread {
					let directoryPickerViewController = ClientDirectoryPickerViewController(core: core, path: "/", selectButtonTitle: "Save here".localized, avoidConflictsWith: [], choiceHandler: { (selectedDirectory) in
						if let targetDirectory = selectedDirectory {
							self.importFile(url: url, to: targetDirectory, bookmark: bookmark, core: core)
						}
					})

					let pickerNavigationController = ThemeNavigationController(rootViewController: directoryPickerViewController)
					pickerNavigationController.modalPresentationStyle = .formSheet

					if let window = UIApplication.shared.currentWindow() {
						let viewController = window.rootViewController
						if let navCon = viewController as? UINavigationController, let viewController = navCon.visibleViewController {
							viewController.present(pickerNavigationController, animated: true)
						} else {
							viewController?.present(pickerNavigationController, animated: true)
						}
					}
				}
			}
		})*/
    }

/*
	func cardViewController(for url: URL) -> UIViewController {
		let tableViewController = MoreStaticTableViewController(style: .grouped)
		let header = MoreViewHeader(url: url)
		let moreViewController = MoreViewController(header: header, viewController: tableViewController)

		let title = NSAttributedString(string: "Save File".localized, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 20, weight: .heavy)])

		var actionsRows: [StaticTableViewRow] = []
		let bookmarks : [OCBookmark] = OCBookmarkManager.shared.bookmarks as [OCBookmark]

		let rowDescription = StaticTableViewRow(label: "Choose an account and folder to import the file into.\n\nOnly one file can be imported at once.".localized, alignment: .center)
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
	}*/

    // 3: Define the actions for the navigation items
    @objc private func cancelAction () {
        let error = NSError(domain: "some.bundle.identifier", code: 0, userInfo: [NSLocalizedDescriptionKey: "An error description"])
        extensionContext?.cancelRequest(withError: error)
    }

    @objc private func doneAction() {
        extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }
}
