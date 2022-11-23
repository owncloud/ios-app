//
//  ClientSessionManager.swift
//  ownCloud
//
//  Created by Felix Schwarz on 31.03.20.
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
import ownCloudApp
import ownCloudAppShared

protocol ClientSessionManagerDelegate : AnyObject {
	func canPresent(bookmark: OCBookmark, message: OCMessage?) -> OCMessagePresentationPriority
	func present(bookmark: OCBookmark, message: OCMessage?)
}

class ClientSessionManager: NSObject {
	public static let shared : ClientSessionManager = { return ClientSessionManager() }()
	var delegates : NSHashTable<NSObject>

	override init() {
		delegates = NSHashTable.weakObjects()

		super.init()

		NotificationCenter.default.addObserver(self, selector: #selector(ClientSessionManager.showMessage(notification:)), name: .NotificationMessagePresenterShowMessage, object: nil)
	}

	deinit {
		NotificationCenter.default.removeObserver(self, name: .NotificationMessagePresenterShowMessage, object: nil)
	}

	@objc func showMessage(notification: Notification) {
		if let message = notification.object as? OCMessage {
			// Ask delegates if they can open a session to present the issue
			if let bookmarkUUID = message.bookmarkUUID, let bookmark = OCBookmarkManager.shared.bookmark(for: bookmarkUUID) {
				let delegates = self.delegates.allObjects

				OnMainThread {
					var presentationDelegate : ClientSessionManagerDelegate?
					var presentationPriority : OCMessagePresentationPriority = .wontPresent

					// Find the best place for presentation
					for delegate in delegates {
						if let delegate = delegate as? ClientSessionManagerDelegate {
							let priority : OCMessagePresentationPriority = delegate.canPresent(bookmark: bookmark, message: message)

							if priority != .wontPresent {
								if priority.rawValue > presentationPriority.rawValue {
									presentationDelegate = delegate
									presentationPriority = priority
								}
							}
						}
					}

					// Present
					if presentationPriority != .wontPresent, let presentationDelegate = presentationDelegate {
						presentationDelegate.present(bookmark: bookmark, message: message)
					}
				}
			}
		}
	}

	func add(delegate: ClientSessionManagerDelegate) {
		if let object = delegate as? NSObject {
			OCSynchronized(self) {
				self.delegates.add(object)
			}
		}
	}

	func remove(delegate: ClientSessionManagerDelegate) {
		if let object = delegate as? NSObject {
			OCSynchronized(self) {
				self.delegates.remove(object)
			}
		}
	}
}
