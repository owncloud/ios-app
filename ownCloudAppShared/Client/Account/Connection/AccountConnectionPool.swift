//
//  AccountConnectionPool.swift
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

public class AccountConnectionPool: NSObject {
	public static var shared: AccountConnectionPool = AccountConnectionPool()

	var connectionsByBookmarkUUID: [String:AccountConnection] = [:]

	var taskQueue: OCAsyncSequentialQueue
	let serialQueue = DispatchQueue(label: "com.owncloud.connection-pool")

	public override init() {
		taskQueue = OCAsyncSequentialQueue(queue: serialQueue)

		super.init()
	}

	public func connection(for bookmark: OCBookmark) -> AccountConnection? {
		var connection: AccountConnection?
		let bookmarkUUID = bookmark.uuid.uuidString

		OCSynchronized(self) {
			if let existingConnection = connectionsByBookmarkUUID[bookmarkUUID] {
				connection = existingConnection
			} else {
				connection = AccountConnection(bookmark: bookmark)
				connectionsByBookmarkUUID[bookmarkUUID] = connection

				if let connection {
					connection.add(consumer: AccountConnectionAuthErrorConsumer(for: connection))
				}
			}
		}

		return connection
	}
}
