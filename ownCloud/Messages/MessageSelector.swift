//
//  MessageSelector.swift
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

typealias MessageSelectorFilter = (_ message: OCMessage) -> Bool
typealias MessageSelectorChangeHandler = (_ messages: [OCMessage]?) -> Void

class MessageSelector: NSObject {
	private var observer : NSKeyValueObservation?
	private var rateLimiter : OCRateLimiter
	private var filter : MessageSelectorFilter

	var queue : OCMessageQueue?
	var handler : MessageSelectorChangeHandler?

	private var selectionUUIDs : [OCMessageUUID] = []
	var selection : [OCMessage]? {
		didSet {
			self.handler?(selection)
		}
	}

	init(from messageQueue: OCMessageQueue, filter messageFilter: @escaping MessageSelectorFilter, handler: MessageSelectorChangeHandler?) {
		rateLimiter = OCRateLimiter(minimumTime: 0.2)

		filter = messageFilter
		queue = messageQueue
		self.handler = handler

		super.init()

		observer = messageQueue.observe(\OCMessageQueue.messages, options: .initial, changeHandler: { [weak self] (_, _) in
			self?.rateLimiter.runRateLimitedBlock {
				self?.updateFromQueue()
			}
		})
	}

	private func updateFromQueue() {
		if let messages = queue?.messages {
			let filteredMessages = messages.filter(self.filter)
			var filteredMessageUUIDs : [OCMessageUUID] = []

			for message in filteredMessages {
				filteredMessageUUIDs.append(message.uuid as OCMessageUUID)
			}

			if (filteredMessageUUIDs.count != selectionUUIDs.count) || !filteredMessageUUIDs.elementsEqual(selectionUUIDs) {
				selectionUUIDs = filteredMessageUUIDs
				selection = filteredMessages
			}
		} else {
			selectionUUIDs = []
			selection = nil
		}
	}
}
