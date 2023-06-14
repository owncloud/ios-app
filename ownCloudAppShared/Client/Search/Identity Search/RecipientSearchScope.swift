//
//  RecipientSearchScope.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 19.04.23.
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

open class RecipientSearchScope: SearchScope {
	var recipientSearchController: OCRecipientSearchController?
	var item: OCItem

	public init(with context: ClientContext, cellStyle: CollectionViewCellStyle?, item: OCItem, localizedName name: String, localizedPlaceholder placeholder: String? = nil, icon: UIImage? = nil) {
		if let core = context.core {
			recipientSearchController = core.recipientSearchController(for: item)
			recipientSearchController?.minimumSearchTermLength = core.connection.capabilities?.sharingSearchMinLength?.uintValue ?? UInt(OCCapabilities.defaultSharingSearchMinLength)
		}

		self.item = item

		super.init(with: context, cellStyle: cellStyle, localizedName: name, localizedPlaceholder: placeholder, icon: icon)

		tokenizer = SearchTokenizer(scope: self, clientContext: clientContext)
		results = recipientSearchController?.recipientsDataSource
	}

	open override func updateFor(_ searchElements: [SearchElement]) {
		let searchTerm = searchElements.composedSearchTerm

		recipientSearchController?.searchTerm = searchTerm
	}
}
