//
//  AppStateActionConnect.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 08.02.23.
//  Copyright © 2023 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2023, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import UIKit
import ownCloudSDK

public class AppStateActionConnect: AppStateAction {
	var bookmarkUUID: String?

	public init(bookmarkUUID: String, children: [AppStateAction]? = nil) {
		super.init(with: children)
		self.bookmarkUUID = bookmarkUUID
	}

	override open class var supportsSecureCoding: Bool {
		return true
	}

	public required init?(coder: NSCoder) {
		bookmarkUUID = coder.decodeObject(of: NSString.self, forKey: "bookmarkUUID") as? String
		super.init(coder: coder)
	}

	override public func encode(with coder: NSCoder) {
		super.encode(with: coder)
		coder.encode(bookmarkUUID, forKey: "bookmarkUUID")
	}

	override public func perform(in clientContext: ClientContext, completion: @escaping AppStateAction.Completion) {
		if let bookmarkUUIDString = bookmarkUUID,
		   let bookmark = OCBookmarkManager.shared.bookmark(forUUIDString: bookmarkUUIDString),
		   let connection = AccountConnectionPool.shared.connection(for: bookmark) {
			connection.connect(completion: { error in
				if error == nil, let contextProvider = clientContext as? ClientContextProvider, let bookmarkUUID = UUID(uuidString: bookmarkUUIDString) {
					OnMainThread {
						// Fetch ClientContext for the bookmark, then pass it to the children
						contextProvider.provideClientContext(for: bookmarkUUID, completion: { (providerError, providedClientContext) in
							completion(providerError, providedClientContext ?? clientContext)
						})
					}
				} else {
					completion(error, clientContext)
				}
			})
		} else {
			completion(NSError.init(ocError: .unknown), clientContext)
		}
	}
}

public extension AppStateAction {
	static func connection(with bookmark: OCBookmark, children: [AppStateAction]? = nil) -> AppStateActionConnect {
		return AppStateActionConnect(bookmarkUUID: bookmark.uuid.uuidString, children: children)
	}
}
