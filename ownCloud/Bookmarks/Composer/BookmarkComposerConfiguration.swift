//
//  BookmarkComposerConfiguration.swift
//  ownCloud
//
//  Created by Felix Schwarz on 05.09.23.
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
import ownCloudApp
import ownCloudAppShared

class BookmarkComposerConfiguration: NSObject {
	var bookmark: OCBookmark?

	var url: URL?
	var urlEditable: Bool = true

	var name: String?
	var nameEditable: Bool = true

	init(bookmark: OCBookmark? = nil, url: URL? = nil, urlEditable: Bool, name: String? = nil, nameEditable: Bool) {
		self.bookmark = bookmark
		self.url = url
		self.urlEditable = urlEditable
		self.name = name
		self.nameEditable = nameEditable
	}
}

extension BookmarkComposerConfiguration {
	static var newBookmarkConfiguration: BookmarkComposerConfiguration {
		return BookmarkComposerConfiguration(url: Branding.shared.profileURL, urlEditable: true, name: Branding.shared.profileBookmarkName, nameEditable: true)
	}
}
