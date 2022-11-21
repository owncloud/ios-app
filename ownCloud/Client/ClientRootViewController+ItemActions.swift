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

#warning("Evaluate removal of file")

import UIKit
import ownCloudSDK
import ownCloudAppShared
import ownCloudApp

extension ClientRootViewController : ActionProgressHandlerProvider {
	func makeActionProgressHandler() -> ActionProgressHandler {
		return { [weak self] (progress, publish) in
			if publish {
				self?.rootContext?.progressSummarizer?.startTracking(progress: progress)
			} else {
				self?.rootContext?.progressSummarizer?.stopTracking(progress: progress)
			}
		}
	}
}

extension ClientRootViewController : MoreItemAction {
	func moreOptions(for item: OCDataItem, at locationIdentifier: OCExtensionLocationIdentifier, context: ClientContext, sender: AnyObject?) -> Bool {
		guard let sender = sender, let core = context.core, let item = item as? OCItem else {
			return false
		}
		let originatingViewController : UIViewController = context.originatingViewController ?? self
		let actionsLocation = OCExtensionLocation(ofType: .action, identifier: locationIdentifier)
		let actionContext = ActionContext(viewController: originatingViewController, clientContext: context, core: core, query: context.query, items: [item], location: actionsLocation, sender: sender)

		if let moreViewController = Action.cardViewController(for: item, with: actionContext, progressHandler: makeActionProgressHandler(), completionHandler: nil) {
			originatingViewController.present(asCard: moreViewController, animated: true)
		}

		return true
	}
}

extension ClientRootViewController : ViewItemAction {
	func provideViewer(for item: OCDataItem, context: ClientContext) -> UIViewController? {
		guard let item = item as? OCItem, let query = context.query, let core = context.core else {
			return nil
		}

		let itemViewController = DisplayHostViewController(clientContext: context, core: core, selectedItem: item, query: query)
		itemViewController.hidesBottomBarWhenPushed = true
		itemViewController.progressSummarizer = context.progressSummarizer

		return itemViewController
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
