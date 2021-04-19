//
//  StaticLoginProfile.swift
//  ownCloud
//
//  Created by Felix Schwarz on 26.11.18.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
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
import ownCloudAppShared

extension OCClassSettingsKey {
	public static let loginProfileIdentifier : OCClassSettingsKey = OCClassSettingsKey("profile-definitions[].identifier")
	public static let loginProfileName : OCClassSettingsKey = OCClassSettingsKey("profile-definitions[].name")
	public static let loginProfileBookmarkName : OCClassSettingsKey = OCClassSettingsKey("profile-definitions[].bookmarkName")
	public static let loginProfileURL : OCClassSettingsKey = OCClassSettingsKey("profile-definitions[].url")
	public static let loginProfileAllowedHosts : OCClassSettingsKey = OCClassSettingsKey("profile-definitions[].allowedHosts")
	public static let loginProfileAllowedAuthenticationMethods : OCClassSettingsKey = OCClassSettingsKey("profile-definitions[].allowedAuthenticationMethods")
	public static let loginProfilePromptForPasswordAuth : OCClassSettingsKey = OCClassSettingsKey("profile-definitions[].promptForPasswordAuth")
	public static let loginProfilePromptForTokenAuth : OCClassSettingsKey = OCClassSettingsKey("profile-definitions[].promptForTokenAuth")
	public static let loginProfilePromptForURL : OCClassSettingsKey = OCClassSettingsKey("profile-definitions[].promptForURL")
	public static let loginProfilePromptForHelpURL : OCClassSettingsKey = OCClassSettingsKey("profile-definitions[].promptForHelpURL")
	public static let loginProfileHelpURLButtonString : OCClassSettingsKey = OCClassSettingsKey("profile-definitions[].helpURLButtonString")
	public static let loginProfileWelcome : OCClassSettingsKey = OCClassSettingsKey("profile-definitions[].welcome")
	public static let loginProfileHelpURL : OCClassSettingsKey = OCClassSettingsKey("profile-definitions[].helpURL")
	public static let loginProfileCanConfigureURL : OCClassSettingsKey = OCClassSettingsKey("profile-definitions[].canConfigureURL")
}

extension StaticLoginProfile : OCClassSettingsSupport {
	static let classSettingsIdentifier : OCClassSettingsIdentifier = .branding

	static func defaultSettings(forIdentifier identifier: OCClassSettingsIdentifier) -> [OCClassSettingsKey : Any]? {
		return [:]
	}

	static func classSettingsMetadata() -> [OCClassSettingsKey : [OCClassSettingsMetadataKey : Any]]? {
		return [
			.loginProfileIdentifier : [
				.type 				: OCClassSettingsMetadataType.string,
				.description		: "Identifier uniquely identifying the static login profile.",
				.category			: "Branding",
				.status				: OCClassSettingsKeyStatus.advanced
			],

			.loginProfileName : [
				.type 				: OCClassSettingsMetadataType.string,
				.description		: "Name of the login profile during setup.",
				.category			: "Branding",
				.status				: OCClassSettingsKeyStatus.advanced
			],

			.loginProfileBookmarkName : [
				.type 				: OCClassSettingsMetadataType.string,
				.description		: "The name that should be used for the bookmark that's generated from this profile.",
				.category			: "Branding",
				.status				: OCClassSettingsKeyStatus.advanced
			],

			.loginProfileURL : [
				.type 				: OCClassSettingsMetadataType.string,
				.description		: "The URL of the server targeted by this profile.",
				.category			: "Branding",
				.status				: OCClassSettingsKeyStatus.advanced
			],

			.loginProfileAllowedHosts : [
				.type 				: OCClassSettingsMetadataType.stringArray,
				.description		: "Domain names (can also include subdomain name), which are allowed as server url when adding a new account.",
				.category			: "Branding",
				.status				: OCClassSettingsKeyStatus.advanced
			],

			.loginProfileAllowedAuthenticationMethods : [
				.type 				: OCClassSettingsMetadataType.stringArray,
				.description		: "The identifiers of the authentication methods allowed for this profile. Allows to f.ex. force OAuth2, or to use Basic Auth even if OAuth2 is available.",
				.category			: "Branding",
				.status				: OCClassSettingsKeyStatus.advanced,
				.possibleValues		: ["com.owncloud.basicauth", "com.owncloud.oauth2"]
			],

			.loginProfilePromptForPasswordAuth : [
				.type 				: OCClassSettingsMetadataType.string,
				.description		: "String which is shown in the profile password view as title.",
				.category			: "Branding",
				.status				: OCClassSettingsKeyStatus.advanced
			],

			.loginProfilePromptForTokenAuth : [
				.type 				: OCClassSettingsMetadataType.string,
				.description		: "String which is shown in the profile view as title, before showing the token authentication view.",
				.category			: "Branding",
				.status				: OCClassSettingsKeyStatus.advanced
			],

			.loginProfilePromptForURL : [
				.type 				: OCClassSettingsMetadataType.string,
				.description		: "String which is shown in the profile view before the Help URL will be opened",
				.category			: "Branding",
				.status				: OCClassSettingsKeyStatus.advanced
			],

			.loginProfilePromptForHelpURL : [
				.type 				: OCClassSettingsMetadataType.string,
				.description		: "Title which will be shown in an alert view, before the help url will be opened.",
				.category			: "Branding",
				.status				: OCClassSettingsKeyStatus.advanced
			],

			.loginProfileHelpURLButtonString : [
				.type 				: OCClassSettingsMetadataType.string,
				.description		: "The title for the help button, which will be shown, if a help url was provided.",
				.category			: "Branding",
				.status				: OCClassSettingsKeyStatus.advanced
			],

			.loginProfileWelcome : [
				.type 				: OCClassSettingsMetadataType.string,
				.description		: "String which is shown in the profile view as welcome title.",
				.category			: "Branding",
				.status				: OCClassSettingsKeyStatus.advanced
			],

			.loginProfileHelpURL : [
				.type 				: OCClassSettingsMetadataType.string,
				.description		: "The URL for an optional help link.",
				.category			: "Branding",
				.status				: OCClassSettingsKeyStatus.advanced
			],

			.loginProfileCanConfigureURL : [
				.type 				: OCClassSettingsMetadataType.boolean,
				.description		: "This value indicates, if the user can configure an own URL in the profile setup.",
				.category			: "Branding",
				.status				: OCClassSettingsKeyStatus.advanced
			]
		]
	}
}

typealias StaticLoginProfileIdentifier = String

class StaticLoginProfile: NSObject {
	static let staticLoginProfileIdentifierKey : String = "static-login-profile-identifier"

	var identifier : StaticLoginProfileIdentifier?
	var name : String?
	var promptForPasswordAuth : String?
	var promptForTokenAuth : String?
	var promptForURL : String?
	var promptForHelpURL : String?
	var helpURLButtonString : String?
	var welcome : String?
	var bookmarkName : String?
	var url : URL?
	var helpURL : URL?
	var canConfigureURL : Bool = false
	var allowedHosts : [String]?
	var allowedAuthenticationMethods : [OCAuthenticationMethodIdentifier]?
	var themeStyleID : ThemeStyleIdentifier?

	convenience init(from profileDict: [String : Any]) {
		self.init()

		if let identifier = profileDict["identifier"] as? String {
			self.identifier = identifier
		}
		if let name = profileDict["name"] as? String {
			self.name = name
		}
		if let prompt = profileDict["promptForTokenAuth"] as? String {
			self.promptForTokenAuth = prompt
		}
		if let promptForPasswordAuth = profileDict["promptForPasswordAuth"] as? String {
			self.promptForPasswordAuth = promptForPasswordAuth
		}
		if let promptForTokenAuth = profileDict["promptForTokenAuth"] as? String {
			self.promptForTokenAuth = promptForTokenAuth
		}
		if let promptForURL = profileDict["promptForURL"] as? String {
			self.promptForURL = promptForURL
		}
		if let promptForHelpURL = profileDict["promptForHelpURL"] as? String {
			self.promptForHelpURL = promptForHelpURL
		}
		if let helpURLButtonString = profileDict["helpURLButtonString"] as? String {
			self.helpURLButtonString = helpURLButtonString
		}
		if let welcome = profileDict["welcome"] as? String {
			self.welcome = welcome
		}
		if let bookmarkName = profileDict["bookmarkName"] as? String {
			self.bookmarkName = bookmarkName
		}
		if let url = profileDict["url"] as? String {
			self.url = URL(string: url)
		}
		if let helpURL = profileDict["helpURL"] as? String {
			self.helpURL = URL(string: helpURL)
		}
		if let canConfigureURL = profileDict["canConfigureURL"] as? Bool {
			self.canConfigureURL = canConfigureURL
		}
		if let allowedAuthenticationMethods = profileDict["allowedAuthenticationMethods"] as? NSArray {
			self.allowedAuthenticationMethods = allowedAuthenticationMethods as? [OCAuthenticationMethodIdentifier]
		}
		if let allowedHosts = profileDict["allowedHosts"] as? NSArray {
			self.allowedHosts = allowedHosts as? [String]
		}
	}
}
