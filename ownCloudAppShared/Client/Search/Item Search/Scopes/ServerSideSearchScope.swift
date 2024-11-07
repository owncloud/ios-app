//
//  ServerSideSearchScope.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 04.11.24.
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
import ownCloudApp

class ServerSideSearchScope: SearchScope {
	var searchResult: OCSearchResult?

	public override init(with context: ClientContext, cellStyle: CollectionViewCellStyle?, localizedName name: String, localizedPlaceholder placeholder: String? = nil, icon: UIImage? = nil) {
		var pathAndRevealCellStyle : CollectionViewCellStyle?

		if let cellStyle = cellStyle {
			pathAndRevealCellStyle = CollectionViewCellStyle(from: cellStyle, changing: { cellStyle in
				cellStyle.showRevealButton = true
				cellStyle.showPathDetails = true
			})
		}

		super.init(with: context, cellStyle: pathAndRevealCellStyle, localizedName: name, localizedPlaceholder: placeholder, icon: icon)

		tokenizer = SearchTokenizer(scope: self, clientContext: clientContext)
		results = nil
	}

	open override func updateFor(_ searchElements: [SearchElement]) {
		let searchTerm = searchElements.composedSearchTerm
		let kqlQuery = "*" + searchTerm + "*"

		if searchResult?.kqlQuery != kqlQuery, let core = clientContext.core {
			searchResult?.cancel()

			searchResult = core.searchFiles(withPattern: kqlQuery, limit: 100)
			results = searchResult?.results
		}
	}
}
