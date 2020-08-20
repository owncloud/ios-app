//
//  MessageGroup.swift
//  ownCloud
//
//  Created by Felix Schwarz on 25.05.20.
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

class MessageGroup: NSObject {
	var identifier : OCMessageCategoryIdentifier?

	private var _groupTitle : String?
	var groupTitle : String? {
		get {
			// Derive group title
			if let identifier = identifier, let issueTemplate = OCMessageTemplate(forIdentifier: OCMessageTemplateIdentifier(rawValue: identifier.rawValue)) {
				_groupTitle = issueTemplate.categoryName
			}

			return _groupTitle
		}
		set {
			_groupTitle = newValue
		}
	}

	var messages : [OCMessage] = []

	init(with message: OCMessage) {
		identifier = message.categoryIdentifier
		messages = [message]
	}
}
