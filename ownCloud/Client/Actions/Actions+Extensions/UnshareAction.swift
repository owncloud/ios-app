//
//  UnshareAction.swift
//  ownCloud
//
//  Created by Matthias Hühne on 04/04/2019.
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

import ownCloudSDK
import ownCloudAppShared

extension Array where Element: OCItem {
	var sharedWithUser : [OCItem] {
		return self.filter({ (item) -> Bool in return item.isSharedWithUser })
	}
	var isShared : [OCItem] {
		return self.filter({ (item) -> Bool in return item.isShared })
	}
}

class UnshareAction : Action {
	override class var identifier : OCExtensionIdentifier? { return OCExtensionIdentifier("com.owncloud.action.unshare") }
	override class var category : ActionCategory? { return .destructive }
	override class var name : String? { return "Unshare".localized }
	override class var locations : [OCExtensionLocationIdentifier]? { return [.moreItem, .tableRow, .moreFolder, .toolbar] }

	// MARK: - Extension matching
	override class func applicablePosition(forContext: ActionContext) -> ActionPosition {
		let sharedWithUser = forContext.items.sharedWithUser

		if forContext.items.count != sharedWithUser.count {
			return .none
		}

		if let core = forContext.core {
			for sharedItem in sharedWithUser {
				if !sharedItem.isShareRootItem(from: core) {
					return .none
				}
			}
		}

		return .last
	}

	// MARK: - Action implementation
	override func run() {
		guard context.items.count > 0, let viewController = context.viewController else {
			self.completed(with: NSError(ocError: .insufficientParameters))
			return
		}

		let items = context.items

		let message: String
		if items.count > 1 {
			message = "Are you sure you want to unshare these items?".localized
		} else {
			message = "Are you sure you want to unshare this item?".localized
		}

		let itemDescripton: String?
		if items.count > 1 {
			itemDescripton = "Multiple items".localized
		} else {
			itemDescripton = items.first?.name
		}

		guard let name = itemDescripton else {
			self.completed(with: NSError(ocError: .insufficientParameters))
			return
		}

		let unshareItemAndPublishProgress = { (items: [OCItem]) in
			for item in items {
				if let owner = item.owner {
					if !owner.isRemote {
						_ = self.core?.sharesSharedWithMe(for: item, initialPopulationHandler: { (shares) in
							let userGroupShares = shares.filter { (share) -> Bool in
								return share.type != .link
							}
							if let share = userGroupShares.first, let progress = self.core?.makeDecision(on: share, accept: false, completionHandler: { (error) in
								if error != nil {
									Log.log("Error \(String(describing: error)) unshare \(String(describing: item.path))")
								}
							}) {
								self.publish(progress: progress)
							}

						}, keepRunning: false)
					} else {
						_ = self.core?.acceptedCloudShares(for: item, initialPopulationHandler: { (shares) in
							let userGroupShares = shares.filter { (share) -> Bool in
								return share.type != .link
							}
							if let share = userGroupShares.first, let progress = self.core?.makeDecision(on: share, accept: false, completionHandler: { (error) in
								if error != nil {
									Log.log("Error \(String(describing: error)) unshare \(String(describing: item.path))")
								}
							}) {
								self.publish(progress: progress)
							}

						}, keepRunning: false)
					}
				}
			}

			self.completed()
		}

		let alertController = ThemedAlertController(
			with: name,
			message: message,
			destructiveLabel: "Unshare".localized,
			preferredStyle: UIDevice.current.isIpad() ? UIAlertController.Style.alert : UIAlertController.Style.actionSheet,
			destructiveAction: {
				unshareItemAndPublishProgress(items)
		})

		viewController.present(alertController, animated: true)

	}

	override class func iconForLocation(_ location: OCExtensionLocationIdentifier) -> UIImage? {
		if location == .moreItem || location == .moreFolder {
			return UIImage(named: "trash")
		}

		return nil
	}
}
