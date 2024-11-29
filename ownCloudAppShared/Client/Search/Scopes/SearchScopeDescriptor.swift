//
//  SearchScopeDescriptor.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 29.11.24.
//  Copyright © 2024 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2024, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import UIKit
import ownCloudSDK

public struct SearchScopeDescriptor {
	var identifier: String

	var title: String
	var icon: UIImage?

	var searchableContent: OCKQLSearchedContent

	var scopeCreator: (_ clientContext: ClientContext, _ cellStyle: CollectionViewCellStyle?, _ descriptor: SearchScopeDescriptor) -> SearchScope?

	func createSearchScope(_ clientContext: ClientContext, _ cellStyle: CollectionViewCellStyle?) -> SearchScope? {
		return self.scopeCreator(clientContext, cellStyle, self)
	}
}

public extension SearchScopeDescriptor {
	static var all: [SearchScopeDescriptor] {
		return [
			.folder,
			.tree,
			.drive,
			.account,
			.server
		]
	}
}
