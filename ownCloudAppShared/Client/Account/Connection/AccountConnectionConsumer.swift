//
//  AccountConnectionConsumer.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 16.11.22.
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
import ownCloudApp

public protocol AccountConnectionCoreErrorHandler: NSObject {
	func account(connnection: AccountConnection, handleError: Error?, issue: OCIssue?) -> Bool //!< Return true if you handled the error/issue - otherwise false to allow propagation to the next consumer
}

public protocol AccountConnectionStatusObserver: NSObject {
	func account(connection: AccountConnection, changedStatusTo: AccountConnection.Status, initial: Bool)
	// func account(connection: AccountConnection, changedConnectionStatusTo: OCCoreConnectionStatus?)
}

public protocol AccountConnectionProgressUpdates: NSObject {
	func account(connection: AccountConnection, progressSummary: ProgressSummary, autoCollapse: Bool)
}

public protocol AccountConnectionMessageUpdates: NSObject {
	func handleMessagesUpdates(messages: [OCMessage]?, groups : [MessageGroup]?)
}

public class AccountConnectionConsumer: NSObject {
	open weak var owner: AnyObject?

	// Fixed components - have to remain identical across the lifetime of an AccountConnectionConsumer object
	open var messagePresenter : OCMessagePresenter? // f.ex. a CardIssueMessagePresenter
	open var progressSummarizerNotificationHandler: ProgressSummarizerNotificationBlock?

	// Dynamic components - called as needed, allowed to change over time
	open var busyHandler: OCCoreBusyStatusHandler?

	open weak var coreErrorHandler: AccountConnectionCoreErrorHandler?
	open weak var statusObserver: AccountConnectionStatusObserver?

	open weak var progressUpdateHandler: AccountConnectionProgressUpdates?
	open weak var messageUpdateHandler: AccountConnectionMessageUpdates?

	init(owner: AnyObject? = nil, messagePresenter: OCMessagePresenter? = nil, progressSummarizerNotificationHandler: ProgressSummarizerNotificationBlock? = nil, busyHandler: OCCoreBusyStatusHandler? = nil, coreErrorHandler: AccountConnectionCoreErrorHandler? = nil, statusObserver: AccountConnectionStatusObserver? = nil, progressUpdateHandler: AccountConnectionProgressUpdates? = nil, messageUpdateHandler: AccountConnectionMessageUpdates? = nil) {
		self.owner = owner
		self.messagePresenter = messagePresenter
		self.progressSummarizerNotificationHandler = progressSummarizerNotificationHandler
		self.busyHandler = busyHandler
		self.coreErrorHandler = coreErrorHandler
		self.statusObserver = statusObserver
		self.progressUpdateHandler = progressUpdateHandler
		self.messageUpdateHandler = messageUpdateHandler
	}
}
