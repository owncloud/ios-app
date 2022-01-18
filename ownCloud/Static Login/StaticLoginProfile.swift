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
import ownCloudApp
import ownCloudAppShared

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
	var isOnboardingEnabled : Bool {
		if promptForHelpURL != nil, helpURLButtonString != nil, helpURL != nil {
			return true
		}
		return false
	}

	enum Key : String, CaseIterable {
		case identifier
		case name
		case promptForPasswordAuth
		case promptForTokenAuth
		case promptForURL
		case promptForHelpURL
		case helpURLButtonString
		case welcome
		case bookmarkName
		case url
		case helpURL
		case canConfigureURL
		case allowedAuthenticationMethods
		case allowedHosts

		var settingsKey : OCClassSettingsKey {
			switch self {
				case .identifier: return OCClassSettingsKey("profile-identifier")
				case .name: return OCClassSettingsKey("profile-name")
				case .promptForPasswordAuth: return OCClassSettingsKey("profile-password-auth-prompt")
				case .promptForTokenAuth: return OCClassSettingsKey("profile-token-auth-prompt")
				case .promptForURL: return OCClassSettingsKey("profile-url-prompt")
				case .welcome: return OCClassSettingsKey("profile-welcome-message")
				case .bookmarkName: return OCClassSettingsKey("profile-bookmark-name")
				case .url: return OCClassSettingsKey("profile-url")
				case .promptForHelpURL: return OCClassSettingsKey("profile-open-help-message")
				case .helpURL: return OCClassSettingsKey("profile-help-url")
				case .helpURLButtonString: return OCClassSettingsKey("profile-help-button-label")
				case .canConfigureURL: return OCClassSettingsKey("profile-allow-url-configuration")
				case .allowedAuthenticationMethods: return OCClassSettingsKey("profile-allowed-authentication-methods")
				case .allowedHosts: return OCClassSettingsKey("profile-allowed-hosts")
			}
		}
	}

	convenience init(from profileDict: [String : Any]) {
		self.init()

		if let identifier = profileDict[Key.identifier.rawValue] as? String {
			self.identifier = identifier
		}
		if let name = profileDict[Key.name.rawValue] as? String {
			self.name = name
		}
		if let promptForPasswordAuth = profileDict[Key.promptForPasswordAuth.rawValue] as? String, promptForPasswordAuth.count > 0 {
			self.promptForPasswordAuth = promptForPasswordAuth
		} else if let promptForPasswordAuth = profileDict[Key.promptForPasswordAuth.settingsKey.rawValue] as? String, promptForPasswordAuth.count > 0 {
			self.promptForPasswordAuth = promptForPasswordAuth
		} else {
			self.promptForPasswordAuth = "Enter your username and password".localized
		}
		if let promptForTokenAuth = profileDict[Key.promptForTokenAuth.rawValue] as? String, promptForTokenAuth.count > 0 {
			self.promptForTokenAuth = promptForTokenAuth
		} else if let promptForTokenAuth = profileDict[Key.promptForTokenAuth.settingsKey.rawValue] as? String, promptForTokenAuth.count > 0 {
			self.promptForTokenAuth = promptForTokenAuth
		} else {
			self.promptForTokenAuth = "Please log in to authorize the app.".localized
		}
		if let promptForURL = profileDict[Key.promptForURL.rawValue] as? String, promptForURL.count > 0 {
			self.promptForURL = promptForURL
		} else if let promptForURL = profileDict[Key.promptForURL.settingsKey.rawValue] as? String, promptForURL.count > 0 {
			self.promptForURL = promptForURL
		} else {
			self.promptForURL = "Please enter a server URL".localized
		}
		if let promptForHelpURL = profileDict[Key.promptForHelpURL.rawValue] as? String {
			self.promptForHelpURL = promptForHelpURL
		} else if let promptForHelpURL = profileDict[Key.promptForHelpURL.settingsKey.rawValue] as? String {
			self.promptForHelpURL = promptForHelpURL
		}
		if let helpURLButtonString = profileDict[Key.helpURLButtonString.rawValue] as? String, helpURLButtonString.count > 0 {
			self.helpURLButtonString = helpURLButtonString
		} else if let helpURLButtonString = profileDict[Key.helpURLButtonString.settingsKey.rawValue] as? String, helpURLButtonString.count > 0 {
			self.helpURLButtonString = helpURLButtonString
		}
		if let welcome = profileDict[Key.welcome.rawValue] as? String, welcome.count > 0 {
			self.welcome = welcome
		} else if let welcome = profileDict[Key.welcome.settingsKey.rawValue] as? String, welcome.count > 0 {
			self.welcome = welcome
		} else if let name = self.name {
			self.welcome = String(format: "Welcome to %@".localized, name)
		} else {
			self.welcome = "Welcome".localized
		}
		if let bookmarkName = profileDict[Key.bookmarkName.rawValue] as? String {
			self.bookmarkName = bookmarkName
		} else if let bookmarkName = profileDict[Key.bookmarkName.settingsKey.rawValue] as? String {
			self.bookmarkName = bookmarkName
		}
		if let url = profileDict[Key.url.rawValue] as? String {
			self.url = URL(string: url)
		} else if let url = profileDict[Key.url.settingsKey.rawValue] as? String {
			self.url = URL(string: url)
		} else if let url = profileDict[Key.url.rawValue] as? URL {
			self.url = url
		} else if let url = profileDict[Key.url.settingsKey.rawValue] as? URL {
			self.url = url
		}
		if let helpURL = profileDict[Key.helpURL.rawValue] as? String {
			self.helpURL = URL(string: helpURL)
		} else if let helpURL = profileDict[Key.helpURL.settingsKey.rawValue] as? String {
			self.helpURL = URL(string: helpURL)
		} else if let helpURL = profileDict[Key.helpURL.rawValue] as? URL {
			self.helpURL = helpURL
		} else if let helpURL = profileDict[Key.helpURL.settingsKey.rawValue] as? URL {
			self.helpURL = helpURL
		}
		if let canConfigureURL = profileDict[Key.canConfigureURL.rawValue] as? Bool {
			self.canConfigureURL = canConfigureURL
		} else if let canConfigureURL = profileDict[Key.canConfigureURL.settingsKey.rawValue] as? Bool {
			self.canConfigureURL = canConfigureURL
		}
		if let allowedAuthenticationMethods = profileDict[Key.allowedAuthenticationMethods.rawValue] as? NSArray {
			self.allowedAuthenticationMethods = allowedAuthenticationMethods as? [OCAuthenticationMethodIdentifier]
		} else if let allowedAuthenticationMethods = profileDict[Key.allowedAuthenticationMethods.settingsKey.rawValue] as? NSArray {
			self.allowedAuthenticationMethods = allowedAuthenticationMethods as? [OCAuthenticationMethodIdentifier]
		}
		if let allowedHosts = profileDict[Key.allowedHosts.rawValue] as? NSArray {
			self.allowedHosts = allowedHosts as? [String]
		} else if let allowedHosts = profileDict[Key.allowedHosts.settingsKey.rawValue] as? NSArray {
			self.allowedHosts = allowedHosts as? [String]
		}
	}
}

extension Branding : StaticProfileBridge {
	public static func initializeStaticProfileBridge() {
		if #available(iOS 13, *) {
			self.registerOCClassSettingsDefaults([:], metadata: [
				StaticLoginProfile.Key.identifier.settingsKey : [
					.type 		: OCClassSettingsMetadataType.string,
					.label		: "Identifier",
					.description 	: "Identifier uniquely identifying the profile.",
					.status		: OCClassSettingsKeyStatus.advanced,
					.category	: "Branding",
					.subCategory	: "Profile"
				],

				StaticLoginProfile.Key.name.settingsKey : [
					.type 		: OCClassSettingsMetadataType.string,
					.label		: "Name",
					.description 	: "Name of the profile during setup.",
					.status		: OCClassSettingsKeyStatus.advanced,
					.category	: "Branding",
					.subCategory	: "Profile"
				],

				StaticLoginProfile.Key.promptForPasswordAuth.settingsKey : [
					.type 		: OCClassSettingsMetadataType.string,
					.label 		: "Password prompt",
					.description	: "Text that is shown when asking the user to enter their password.",
					.status		: OCClassSettingsKeyStatus.advanced,
					.category	: "Branding",
					.subCategory	: "Profile"
				],

				StaticLoginProfile.Key.promptForTokenAuth.settingsKey : [
					.type 		: OCClassSettingsMetadataType.string,
					.label 		: "Token authentication prompt",
					.description	: "Text that is shown to the user before opening the authentication web view (f.ex. for OAuth2, OIDC).",
					.status		: OCClassSettingsKeyStatus.advanced,
					.category	: "Branding",
					.subCategory	: "Profile"
				],

				StaticLoginProfile.Key.promptForURL.settingsKey : [
					.type 		: OCClassSettingsMetadataType.string,
					.label 		: "URL prompt",
					.description	: "Text shown above the URL field when setting up an account.",
					.status		: OCClassSettingsKeyStatus.advanced,
					.category	: "Branding",
					.subCategory	: "Profile"
				],

				StaticLoginProfile.Key.welcome.settingsKey : [
					.type 		: OCClassSettingsMetadataType.string,
					.label 		: "Welcome Message",
					.description	: "Welcome message shown during account setup.",
					.status		: OCClassSettingsKeyStatus.advanced,
					.category	: "Branding",
					.subCategory	: "Profile"
				],

				StaticLoginProfile.Key.bookmarkName.settingsKey : [
					.type 		: OCClassSettingsMetadataType.string,
					.label		: "Bookmark Name",
					.description	: "The name that should be used for the bookmark that's generated from this profile and appears in the account list.",
					.status		: OCClassSettingsKeyStatus.advanced,
					.category	: "Branding",
					.subCategory	: "Profile"
				],

				StaticLoginProfile.Key.url.settingsKey : [
					.type 		: OCClassSettingsMetadataType.urlString,
					.label		: "URL",
					.description 	: "The URL of the server targeted by this profile.",
					.status		: OCClassSettingsKeyStatus.advanced,
					.category	: "Branding",
					.subCategory	: "Profile"
				],

				StaticLoginProfile.Key.helpURL.settingsKey : [
					.type 		: OCClassSettingsMetadataType.urlString,
					.label 		: "Onboarding URL",
					.description	: "Optional URL to onboarding resources.",
					.status		: OCClassSettingsKeyStatus.advanced,
					.category	: "Branding",
					.subCategory	: "Profile"
				],

				StaticLoginProfile.Key.promptForHelpURL.settingsKey : [
					.type 		: OCClassSettingsMetadataType.string,
					.label		: "Open onboarding URL message",
					.description 	: "Message shown in an alert before opening the onboarding URL.",
					.status		: OCClassSettingsKeyStatus.advanced,
					.category	: "Branding",
					.subCategory	: "Profile"
				],

				StaticLoginProfile.Key.helpURLButtonString.settingsKey : [
					.type 		: OCClassSettingsMetadataType.string,
					.label		: "Onboarding button title",
					.description 	: "Text used for the onboarding button title",
					.status		: OCClassSettingsKeyStatus.advanced,
					.category	: "Branding",
					.subCategory	: "Profile"
				],

				StaticLoginProfile.Key.canConfigureURL.settingsKey : [
					.type 		: OCClassSettingsMetadataType.boolean,
					.label	 	: "Allow URL configuration",
					.description	: "Indicates if the user can change the server URL for the account.",
					.status		: OCClassSettingsKeyStatus.advanced,
					.category	: "Branding",
					.subCategory	: "Profile"
				],

				StaticLoginProfile.Key.allowedAuthenticationMethods.settingsKey : [
					.type 		: OCClassSettingsMetadataType.stringArray,
					.label		: "Allowed authentication methods",
					.description 	: "The identifiers of the authentication methods allowed for this profile. Allows to f.ex. force OAuth2, or to use Basic Auth even if OAuth2 is available.",
					.status		: OCClassSettingsKeyStatus.advanced,
					.possibleValues : OCConnection.authenticationMethodIdentifierMetadata(),
					.category	: "Branding",
					.subCategory	: "Profile"
				],

				StaticLoginProfile.Key.allowedHosts.settingsKey : [
					.type 		: OCClassSettingsMetadataType.stringArray,
					.label 		: "Allowed Hosts",
					.description	: "Domain names (can also include subdomain name), which are allowed as server url when adding a new account.",
					.status		: OCClassSettingsKeyStatus.advanced,
					.category	: "Branding",
					.subCategory	: "Profile"
				]
			])
		}
	}

	static public func composeBrandingDict() -> [String : Any]? {
		var profileDict : [String : Any] = [:]

		for key in StaticLoginProfile.Key.allCases {
			if let profileValue = self.classSetting(forOCClassSettingsKey: key.settingsKey) {
				profileDict[key.rawValue] = profileValue
			}
		}

		if profileDict.count == 0 {
			return nil
		}

		return profileDict
	}
}
