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

class BookmarkComposerConfiguration {
	var bookmark: OCBookmark?

	var hasIntro: Bool = false
	var hasSettings: Bool = false

	var url: URL?
	var urlEditable: Bool = true

	var name: String?
	var nameEditable: Bool = true

	var helpButtonLabel: String?
	var helpButtonURL: URL?
	var helpMessage: String?

	init(bookmark: OCBookmark? = nil, hasIntro: Bool = false, hasSettings: Bool = true, url: URL? = nil, urlEditable: Bool = true, name: String? = nil, nameEditable: Bool, helpButtonLabel: String? = nil, helpButtonURL: URL? = nil, helpMessage: String? = nil) {
		self.bookmark = bookmark
		self.hasIntro = hasIntro
		self.hasSettings = hasSettings
		self.url = url
		self.urlEditable = urlEditable
		self.name = name
		self.nameEditable = nameEditable
		self.helpButtonLabel = helpButtonLabel
		self.helpButtonURL = helpButtonURL
		self.helpMessage = helpMessage
	}
}

extension BookmarkComposerConfiguration {
	static var newBookmarkConfiguration: BookmarkComposerConfiguration {
		return BookmarkComposerConfiguration(url: Branding.shared.profileURL, urlEditable: Branding.shared.profileAllowUrlConfiguration ?? true, name: Branding.shared.profileBookmarkName, nameEditable: Branding.shared.canEditAccount, helpButtonLabel: Branding.shared.profileHelpButtonLabel, helpButtonURL: Branding.shared.profileHelpURL, helpMessage: Branding.shared.profileOpenHelpMessage)
	}
}
