//
//  SearchScope+Registry.swift
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

extension SearchScope {
	static var preferredSearchedContent: OCKQLSearchedContent?

	static func availableScopes(for clientContext: ClientContext, cellStyle: CollectionViewCellStyle) -> [SearchScope] {
		var scopes : [SearchScope] = []

		let descriptors = SearchScopeDescriptor.all

		for descriptor in descriptors {
			if let scope = descriptor.createSearchScope(clientContext, cellStyle) {
				scopes.append(scope)
			}
		}

		return scopes
	}
}
