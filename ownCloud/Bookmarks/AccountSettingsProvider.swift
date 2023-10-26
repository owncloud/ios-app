//
//  AccountSettingsProvider.swift
//  ownCloud
//
//  Created by Matthias Hühne on 26.04.23.
//  Copyright © 2023 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2018, ownCloud GmbH.
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

class AccountSettingsProvider: NSObject {

	static public var shared : AccountSettingsProvider = {
		return AccountSettingsProvider()
	}()

	public var defaultBookmarkName: String? {
		if let name = Branding.shared.profileBookmarkName {
			return name
		} else if let name = self.classSetting(forOCClassSettingsKey: .bookmarkDefaultName) as? String {
			return name
		}

		return nil
	}

	public var defaultURL: URL? {
		if let url = Branding.shared.profileURL {
			return url
		} else if let urlString = self.classSetting(forOCClassSettingsKey: .bookmarkDefaultURL) as? String {
			return URL(string: urlString)
		}

		return nil
	}

	public var URLEditable: Bool {
		if let url = Branding.shared.profileAllowUrlConfiguration {
			return url
		} else if let value = self.classSetting(forOCClassSettingsKey: .bookmarkURLEditable) as? Bool {
			return value
		}

		return true
	}

	public var profileOpenHelpMessage: String? {
		return Branding.shared.profileOpenHelpMessage
	}

	public var profileHelpButtonLabel: String? {
		return Branding.shared.profileHelpButtonLabel
	}

	public var profileHelpURL: URL? {
		return Branding.shared.profileHelpURL
	}

	var logo: UIImage {
		if Branding.shared.isBranded, let image = Branding.shared.brandedImageNamed(.brandLogo) ?? Branding.shared.brandedImageNamed(.legacyBrandLogo) {
			return image
		}

		return Branding.shared.brandedImageNamed(.bookmarkIcon)!
	}
}

// MARK: - OCClassSettings support
extension OCClassSettingsIdentifier {
	static let accountSettings = OCClassSettingsIdentifier("account-settings")
}

extension OCClassSettingsKey {
	static let bookmarkDefaultName = OCClassSettingsKey("default-name")
	static let bookmarkDefaultURL = OCClassSettingsKey("default-url")
	static let bookmarkURLEditable = OCClassSettingsKey("url-editable")
}

extension AccountSettingsProvider : OCClassSettingsSupport {
	public static let classSettingsIdentifier : OCClassSettingsIdentifier = .accountSettings

	public static func defaultSettings(forIdentifier identifier: OCClassSettingsIdentifier) -> [OCClassSettingsKey : Any]? {
		if identifier == .bookmark {
			return [
				.bookmarkURLEditable : true
			]
		}

		return nil
	}

	public static func classSettingsMetadata() -> [OCClassSettingsKey : [OCClassSettingsMetadataKey : Any]]? {
		return [
			.bookmarkDefaultName : [
				.type         : OCClassSettingsMetadataType.string,
				.description    : "The default name for the creation of new bookmarks.",
				.category    : "Bookmarks",
				.status        : OCClassSettingsKeyStatus.supported
			],

			.bookmarkDefaultURL : [
				.type         : OCClassSettingsMetadataType.string,
				.description    : "The default URL for the creation of new bookmarks.",
				.category    : "Bookmarks",
				.status        : OCClassSettingsKeyStatus.supported
			],

			.bookmarkURLEditable : [
				.type         : OCClassSettingsMetadataType.boolean,
				.description    : "Controls whether the server URL in the text field during the creation of new bookmarks can be changed.",
				.category    : "Bookmarks",
				.status        : OCClassSettingsKeyStatus.supported
			]
		]
	}
}
