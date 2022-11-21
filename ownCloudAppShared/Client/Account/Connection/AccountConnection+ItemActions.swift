//
//  AccountController+ItemActions.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 21.11.22.
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

extension AccountConnection : InlineMessageCenter {
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

extension AccountConnection : ActionProgressHandlerProvider {
	public func makeActionProgressHandler() -> ActionProgressHandler {
		return { [weak self] (progress, publish) in
			if publish {
				self?.progressSummarizer.startTracking(progress: progress)
			} else {
				self?.progressSummarizer.stopTracking(progress: progress)
			}
		}
	}
}
