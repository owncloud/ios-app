//
//  SearchScope.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 22.06.22.
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
import ownCloudSDK

open class SearchScope: NSObject {
	public var localizedName : String
	public var icon : UIImage?

	@objc public dynamic var results: OCDataSource?
	@objc public dynamic var resultsCellStyle: CollectionViewCellStyle?

	public var isSelected: Bool = false

	public var clientContext: ClientContext

	public var tokenizer: SearchTokenizer?

	static public func modifyingQuery(with context: ClientContext, localizedName: String) -> SearchScope {
		return SingleFolderSearchScope(with: context, cellStyle: nil, localizedName: localizedName, icon: UIImage(systemName: "folder"))
	}

	static public func driveSearch(with context: ClientContext, cellStyle: CollectionViewCellStyle, localizedName: String) -> SearchScope {
		return DriveSearchScope(with: context, cellStyle: cellStyle, localizedName: localizedName, icon: UIImage(systemName: "person"))
	}

	static public func accountSearch(with context: ClientContext, cellStyle: CollectionViewCellStyle, localizedName: String) -> SearchScope {
		return AccountSearchScope(with: context, cellStyle: cellStyle, localizedName: localizedName, icon: UIImage(systemName: "square.grid.2x2j"))
	}

	public init(with context: ClientContext, cellStyle: CollectionViewCellStyle?, localizedName name: String, icon: UIImage? = nil) {
		clientContext = context
		localizedName = name

		super.init()

		resultsCellStyle = cellStyle
		self.icon = icon
	}

	open func updateFor(_ searchElements: [SearchElement]) {
	}
}
