//
//  SyncIssueMessagePresenter.swift
//  ownCloud
//
//  Created by Felix Schwarz on 25.03.20.
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

class SyncIssueMessagePresenter: OCMessagePresenter {
	var clientRootViewController : ClientRootViewController

	init(for rootViewController: ClientRootViewController) {
		self.clientRootViewController = rootViewController

		super.init()

		self.identifier = OCMessagePresenterIdentifier(rawValue: "syncIssuePresenter.\(rootViewController.bookmark.uuid.uuidString)")
	}

	override func presentationPriority(for message: OCMessage) -> OCMessagePresentationPriority {
		if message.syncIssue != nil, message.bookmarkUUID == clientRootViewController.core?.bookmark.uuid {
			return .low
		}

		return .wontPresent
	}

	override func present(_ message: OCMessage, completionHandler: @escaping (OCMessagePresentationResult, OCSyncIssueChoice?) -> Void) {
		if let messageQueue = queue {
			if let issue = OCIssue(from: message, from: messageQueue), let core = self.clientRootViewController.core {
				self.clientRootViewController.core(core, handleError: nil, issue: issue)

				completionHandler(.didPresent, nil)
				return
			}
		}

		completionHandler([], nil)
	}
}
