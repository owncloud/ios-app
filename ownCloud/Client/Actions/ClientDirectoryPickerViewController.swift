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

	// MARK: - Instance Properties
	private var selectButton: UIBarButtonItem!
	private var selectButtonTitle: String
	private var cancelBarButton: UIBarButtonItem!
	private var completion: (OCItem?) -> Void

	// MARK: - Init & deinit
	init(core inCore: OCCore, path: String, selectButtonTitle: String = "Move here".localized, completion: @escaping (OCItem?) -> Void) {
		self.selectButtonTitle = selectButtonTitle
		self.completion = completion

		let targetDirectoryQuery = OCQuery(forPath: path)

		// Sort folders first
		targetDirectoryQuery.sortComparator = { (left, right) in
			guard let leftItem  = left as? OCItem, let rightItem = right as? OCItem else {
				return .orderedSame
			}
			if leftItem.type == OCItemType.collection && rightItem.type != OCItemType.collection {
				return .orderedAscending
			} else if leftItem.type != OCItemType.collection && rightItem.type == OCItemType.collection {
				return .orderedDescending
			}
			return .orderedSame
		}

		super.init(core: inCore, query: targetDirectoryQuery)

		// Force disable sorting options
		self.shallShowSortBar = false
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	// MARK: - ViewController lifecycle
	override func viewDidLoad() {
		super.viewDidLoad()

		// Remove pull to refresh
		queryRefreshControl?.removeFromSuperview()
		self.tableView.alwaysBounceVertical = false

		// Select button creation
		selectButton = UIBarButtonItem(title: selectButtonTitle, style: .plain, target: self, action: #selector(selectButtonPressed))
		selectButton.title = selectButtonTitle

		// Cancel button creation
		cancelBarButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelBarButtonPressed))
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(true)
		navigationItem.rightBarButtonItems = [cancelBarButton]

		if let navController = self.navigationController {
			navController.isToolbarHidden = false
			navController.toolbar.isTranslucent = false
			let flexibleSpaceBarButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
			self.setToolbarItems([flexibleSpaceBarButton, selectButton, flexibleSpaceBarButton], animated: false)
		}
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = super.tableView(tableView, cellForRowAt: indexPath)

		if let clientItemCell = cell as? ClientItemCell {
			clientItemCell.isMoreButtonPermanentlyHidden = true
			clientItemCell.isActive = (clientItemCell.item?.type == OCItemType.collection) ? true : false
		}

		return cell
	}

	override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
		let item: OCItem = itemAtIndexPath(indexPath)
		if item.type != OCItemType.collection {
			return nil
		} else {
			return indexPath
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

	override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
		return .none
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
