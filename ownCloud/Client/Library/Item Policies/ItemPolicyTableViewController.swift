//
//  ItemPolicyTableViewController.swift
//  ownCloud
//
//  Created by Felix Schwarz on 18.07.19.
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
import ownCloudAppShared

enum ItemPolicySectionIndex : Int {
	case all
	case policies
}

class ItemPolicyTableViewController : FileListTableViewController {

	var policyKind: OCItemPolicyKind
	weak var policyProcessor : OCItemPolicyProcessor?

	var messageView : MessageView?

	init(core: OCCore, policyKind: OCItemPolicyKind) {
		self.policyKind = policyKind

		super.init(core: core, style: .grouped)

		policyProcessor = core.itemPolicyProcessor(forKind: policyKind)

		if let policyProcessor = policyProcessor {
			self.navigationItem.title = policyProcessor.localizedName
		}

		NotificationCenter.default.addObserver(self, selector: #selector(loadItemPolicies), name: .OCCoreItemPolicyProcessorUpdated, object: policyProcessor)
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	deinit {
		NotificationCenter.default.removeObserver(self, name: .OCCoreItemPolicyProcessorUpdated, object: nil)
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		messageView = MessageView(add: self.view)
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		self.loadItemPolicies()
	}

	@objc func loadItemPolicies() {
		self.core?.retrievePolicies(ofKind: policyKind, affectingItem: nil, includeInternal: false, completionHandler: { (_, policies) in
			self.itemPolicies = policies?.sorted(by: { (policy1, policy2) -> Bool in
				if let path1 = policy1.path, let path2 = policy2.path {
					return path1.compare(path2) == .orderedAscending
				}

				return false
			}) ?? []
		})
	}

	var itemPolicies : [OCItemPolicy] = [] {
		didSet {
			OnMainThread {
				if self.itemPolicies.count == 0 {
					self.messageView?.message(show: true, imageName: "icon-available-offline", title: "Available Offline".localized, message: "No items have been selected for offline availability.".localized)
				} else {
					self.messageView?.message(show: false)
				}

				self.reloadTableData()
			}
		}
	}

	override func registerCellClasses() {
		self.collectionView.register(ItemPolicyCell.self, forCellWithReuseIdentifier: "itemCell")
		self.collectionView.register(ThemeTableViewCell.self, forCellWithReuseIdentifier: "metaCell")
	}

	// MARK: - Table view data source
	func itemPolicyAt(_ indexPath : IndexPath) -> OCItemPolicy {
		return itemPolicies[indexPath.row]
	}

	override func itemAt(indexPath: IndexPath) -> OCItem? {
		if let section = ItemPolicySectionIndex(rawValue: indexPath.section) {
			switch section {
				case .all: 	return nil
				case .policies: return super.itemAt(indexPath: indexPath)
			}
		}

		return nil
	}

	override func numberOfSections(in collectionView: UICollectionView) -> Int {
		return (itemPolicies.count > 0) ? 2 : 0
	}

	override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		if let section = ItemPolicySectionIndex(rawValue: section) {
			switch section {
				case .all: 	return 1
				case .policies: return itemPolicies.count
			}
		} else {
			return 0
		}
	}

	// TODO:
	/*
	override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		if let section = ItemPolicySectionIndex(rawValue: section) {
			switch section {
				case .all: 	return "Overview".localized
				case .policies: return "Locations".localized
			}
		} else {
			return nil
		}
	}*/

	override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		if let section = ItemPolicySectionIndex(rawValue: indexPath.section) {
			switch section {
				case .all:
					let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "metaCell", for: indexPath) as? ThemeCollectionViewCell
/*
					cell?.textLabel?.text = "All Files".localized
					cell?.imageView?.image = UIImage(named: "cloud-available-offline")?.tinted(with: Theme.shared.activeCollection.tableRowColors.labelColor)?.paddedTo(width: 60)
					cell?.accessoryType = .disclosureIndicator
*/
					return cell!

				case .policies:
					let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "itemCell", for: indexPath) as? ItemPolicyCell
/*
					cell?.accessibilityIdentifier = itemPolicy.path ?? itemPolicy.localID
					cell?.core = self.core
					cell?.itemPolicy = itemPolicy
					cell?.isMoreButtonPermanentlyHidden = true
*/
					if cell?.delegate == nil {
						cell?.delegate = self
					}

					return cell!
			}
		}

		return UICollectionViewCell()
	}

	override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		if let section = ItemPolicySectionIndex(rawValue: indexPath.section) {
			var query : OCQuery?
			var title : String?

			switch section {
				case .all:
					query = OCQuery(condition: .require([
						.where(.downloadTrigger, isEqualTo: OCItemDownloadTriggerID.availableOffline)
					]), inputFilter:nil)
				case .policies:
					if let item = self.itemAt(indexPath: indexPath) {
						if item.type == .collection {
							query = self.query(forItem: item)
							title = item.name
						} else {
							super.collectionView(collectionView, didSelectItemAt: indexPath)
						}
					}
			}

			if let core = core, let query = query {
				let customFileListController = QueryFileListTableViewController(core: core, query: query)
				customFileListController.title = title
				customFileListController.pullToRefreshAction = nil
				self.navigationController?.pushViewController(customFileListController, animated: true)
			}
		}
	}
/*
	override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
		if let section = ItemPolicySectionIndex(rawValue: indexPath.section), section == .policies {
			return UISwipeActionsConfiguration(actions: [UIContextualAction(style: .destructive, title: "Make unavailable offline".localized, handler: { [weak self] (_, _, completionHandler) in
				if let core = self?.core, let itemPolicy = self?.itemPolicyAt(indexPath) {
					core.removeAvailableOfflinePolicy(itemPolicy, completionHandler: nil)
				}
				completionHandler(true)
			})])
		} else {
			return nil
		}
	}*/

	// MARK: - Theming
	override func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		super.applyThemeCollection(theme: theme, collection: collection, event: event)

		self.view.backgroundColor = theme.activeCollection.tableGroupBackgroundColor
	}

}
