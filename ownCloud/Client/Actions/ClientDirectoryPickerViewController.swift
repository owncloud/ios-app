//
//  ClientDirectoryPickerViewController.swift
//  ownCloud
//
//  Created by Pablo Carrascal on 22/08/2018.
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

class ClientDirectoryPickerViewController: ClientQueryViewController {

	private let SELECT_BUTTON_HEIGHT: CGFloat = 44.0

	// MARK: - Query directory filter
	private static let DIRECTORY_FILTER_IDENTIFIER: String = "directory-filter"
	private static var directoryFilterHandler: OCQueryFilterHandler = { (_, _, item) -> Bool in
		if let item = item {
			if item.type == .collection {return true}
		}
		return false
	}
	private static var directoryFilter: OCQueryFilter {
		return OCQueryFilter(handler: ClientDirectoryPickerViewController.directoryFilterHandler)
	}

	// MARK: - Instance Properties
	private var selectButton: UIBarButtonItem!
	private var selectButtonTitle: String
	private var cancelBarButton: UIBarButtonItem!
	private var completion: (OCItem?) -> Void

	// MARK: - Init & deinit
	init(core inCore: OCCore, path: String, selectButtonTitle: String = "Move here".localized, completion: @escaping (OCItem?) -> Void) {
		self.selectButtonTitle = selectButtonTitle
		self.completion = completion

		super.init(core: inCore, query: OCQuery(forPath: path))

		self.query.addFilter(ClientDirectoryPickerViewController.directoryFilter, withIdentifier: ClientDirectoryPickerViewController.DIRECTORY_FILTER_IDENTIFIER)
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	// MARK: - ViewController lifecycle
	override func viewDidLoad() {
		super.viewDidLoad()

		// Select button creation
		selectButton = UIBarButtonItem(title: selectButtonTitle, style: .plain, target: self, action: #selector(selectButtonPressed))
		selectButton.title = selectButtonTitle

		// Cancel button creation
		cancelBarButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelBarButtonPressed))
		navigationItem.rightBarButtonItems = [cancelBarButton]
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(true)

		if let navController = self.navigationController {
			navController.isToolbarHidden = false
			let flexibleSpaceBarButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
			self.setToolbarItems([flexibleSpaceBarButton, selectButton, flexibleSpaceBarButton], animated: false)
		}
	}

	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let item: OCItem = itemAtIndexPath(indexPath)

		guard item.type == OCItemType.collection, let core = self.core, let path = item.path else {
			return
		}

		self.navigationController?.pushViewController(ClientDirectoryPickerViewController(core: core, path: path, selectButtonTitle: selectButtonTitle, completion: completion), animated: true)
	}

	override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
		return nil
	}

	// MARK: - Actions
	@objc private func cancelBarButtonPressed() {
		self.dismiss(animated: true, completion: {
			self.completion(nil)
		})
	}

	@objc private func selectButtonPressed() {
		self.dismiss(animated: true, completion: {
			self.completion(self.query.rootItem)
		})
	}
}
