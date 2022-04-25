//
//  ClientRootViewController+ItemActions.swift
//  ownCloud
//
//  Created by Felix Schwarz on 21.04.22.
//  Copyright © 2022 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2022, ownCloud GmbH.
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

extension ClientRootViewController : MoreItemAction {
	func makeActionProgressHandler() -> ActionProgressHandler {
		return { [weak self] (progress, publish) in
			if publish {
				self?.rootContext?.progressSummarizer?.startTracking(progress: progress)
			} else {
				self?.rootContext?.progressSummarizer?.stopTracking(progress: progress)
			}
		}
	}

	func moreOptions(for item: OCItem, at locationIdentifier: OCExtensionLocationIdentifier, context: ClientContext, sender: AnyObject?) -> Bool {
		guard let sender = sender, let core = context.core else {
			return false
		}
		let actionsLocation = OCExtensionLocation(ofType: .action, identifier: locationIdentifier)
		let actionContext = ActionContext(viewController: self, core: core, query: context.query, items: [item], location: actionsLocation, sender: sender)

		if let moreViewController = Action.cardViewController(for: item, with: actionContext, progressHandler: makeActionProgressHandler(), completionHandler: nil) {
			self.present(asCard: moreViewController, animated: true)
		}

		return true
	}
}

extension ClientRootViewController : OpenItemAction {
	@discardableResult public func open(item: OCItem, context: ClientContext, animated: Bool, pushViewController: Bool) -> UIViewController? {
		if let core = context.core {
			if let bookmarkContainer = self.tabBarController as? BookmarkContainer {
				let activity = OpenItemUserActivity(detailItem: item, detailBookmark: bookmarkContainer.bookmark)
				view.window?.windowScene?.userActivity = activity.openItemUserActivity
			}

			switch item.type {
				case .collection:
					if let location = item.location {
						let queryViewController = ClientItemViewController(context: context, query: OCQuery(for: location))
						if pushViewController {
							context.navigationController?.pushViewController(queryViewController, animated: animated)
						}
						return queryViewController
					}

				case .file:
					guard let query = context.query else {
						return nil
					}

					let itemViewController = DisplayHostViewController(core: core, selectedItem: item, query: query)
					itemViewController.hidesBottomBarWhenPushed = true
					//!! itemViewController.progressSummarizer = self.progressSummarizer
					context.navigationController?.pushViewController(itemViewController, animated: animated)
			}
		}

		return nil
	}
}

extension ClientRootViewController : InlineMessageCenter {
	public func hasInlineMessage(for item: OCItem) -> Bool {
		guard let activeSyncRecordIDs = item.activeSyncRecordIDs, let syncRecordIDsWithMessages = self.syncRecordIDsWithMessages else {
			return false
		}

		return syncRecordIDsWithMessages.contains { (syncRecordID) -> Bool in
			return activeSyncRecordIDs.contains(syncRecordID)
		}
	}

	public func showInlineMessageFor(item: OCItem) {
		if let messages = self.messageSelector?.selection,
		   let firstMatchingMessage = messages.first(where: { (message) -> Bool in
			guard let syncRecordID = message.syncIssue?.syncRecordID, let containsSyncRecordID = item.activeSyncRecordIDs?.contains(syncRecordID) else {
				return false
			}

			return containsSyncRecordID
		}) {
			firstMatchingMessage.showInApp()
		}
	}
}
