//
//  MessageQueueExample.swift
//  ownCloud
//
//  Created by Felix Schwarz on 14.06.20.
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

/*
		// Example of using this example:

		MessageQueueExample.shared.postMessage("One-off message"", 			withResponseHandling: false, preventDuplicates: true, bookmark: OCBookmarkManager.shared.bookmarks.first!)
		MessageQueueExample.shared.postMessage("One-off message (duplicate)"", 		withResponseHandling: false, preventDuplicates: true, bookmark: OCBookmarkManager.shared.bookmarks.first!)
		MessageQueueExample.shared.postMessage("One-off message (another duplicate)"", 	withResponseHandling: false, preventDuplicates: true, bookmark: OCBookmarkManager.shared.bookmarks.first!)

		MessageQueueExample.shared.postMessage("Make a choice", withResponseHandling: true, preventDuplicates: false, bookmark: OCBookmarkManager.shared.bookmarks.first!)
*/

extension OCMessageOriginIdentifier {
	static let queueExample: OCMessageOriginIdentifier  =  OCMessageOriginIdentifier(rawValue: "queue-example")
}

class MessageQueueExample: NSObject, OCMessageResponseHandler {
	static let shared : MessageQueueExample = {
		let example : MessageQueueExample = MessageQueueExample()

		example.registerForHandling()

		return example
	}()

	func postMessage(_ title: String, withResponseHandling: Bool, preventDuplicates: Bool, bookmark: OCBookmark) {
		let message = OCMessage(origin: withResponseHandling ? .queueExample : .dynamic, // .dynamic means we don't have to handle the response in order to get it removed; to re-identify your own messages, use your own origin identifier
					bookmarkUUID: bookmark.uuid,
					date: nil,
					uuid: preventDuplicates ? (withResponseHandling ? UUID(uuidString: "68753A44-4D6F-1226-9C60-0050E4C00067") : UUID(uuidString: "68753A44-4D6F-1226-9C60-0050E4C00068")) : nil, // If a message with the same UUID is still unresolved, the new message will be discarded, avoiding duplicates
					title: title,
					description: "Hello world",
					choices: withResponseHandling ? [
						OCMessageChoice(of: .default, identifier: .OK, label: "OK".localized, metaData: nil),
						OCMessageChoice(of: .regular, identifier: .retry, label: "Retry".localized, metaData: nil),
						OCMessageChoice(of: .destructive, identifier: .cancel, label: "Cancel".localized, metaData: nil)
					] : [
						OCMessageChoice(of: .regular, identifier: .OK, label: "OK".localized, metaData: nil)
					])

		// message.categoryIdentifier = // specify a category identifier if you want to allow user notifications and grouping of this message. Make sure you first register a OCMessageTemplate via OCMessageTemplate.registerTemplates() so that the choices are also available in notifications. Otherwise, behaviour is undefined
		message.representedObject = NSUUID()

		Log.debug("Enqueuing message with representedObject \(String(describing: message.representedObject))")

		OCMessageQueue.global.enqueue(message)
	}

	func registerForHandling() {
		OCMessageQueue.global.add(responseHandler: self)
	}

	func deregisterForHandling() {
		OCMessageQueue.global.remove(responseHandler: self)
	}

	func handleResponse(to message: OCMessage) -> Bool {
		// For the handler to be called, it must have been added to the queue first (=> see registerForHandling())

		if message.originIdentifier == .queueExample { // message originated from here
			Log.debug("Message with representedObject \(String(describing: message.representedObject)) was responded to with choice \(message.pickedChoice?.identifier.rawValue ?? "???")")

			return true
		}

		return false
	}
}
