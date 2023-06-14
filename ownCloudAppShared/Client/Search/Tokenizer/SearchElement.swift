//
//  SearchElement.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 12.08.22.
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

open class SearchElement: NSObject {
	open var text: String
	open var inputComplete: Bool

	open var representedObject: AnyObject?

	required public init(text: String, representedObject: AnyObject? = nil, inputComplete: Bool) {
		self.text = text
		self.inputComplete = inputComplete

		super.init()

		self.representedObject = representedObject
	}
}

open class SearchToken: SearchElement {
	open var icon: UIImage?

	required public init(text: String, icon: UIImage?, representedObject: AnyObject?, inputComplete: Bool) {
		super.init(text: text, representedObject: representedObject, inputComplete: inputComplete)

		self.icon = icon
	}

	required public init(text: String, representedObject: AnyObject? = nil, inputComplete: Bool) {
		fatalError("init(text:representedObject:inputComplete:) has not been implemented")
	}
}

extension SearchToken {
	var uiSearchToken: UISearchToken {
		let token = UISearchToken(icon: icon, text: text)
		token.representedObject = self

		return token
	}
}

extension [SearchElement] {
	var composedSearchTerm: String {
		return compactMap({ element in return element.text }).joined(separator: " ")
	}
}
