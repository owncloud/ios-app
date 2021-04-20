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
				case .identifier: return OCClassSettingsKey("identifier")
				case .name: return OCClassSettingsKey("name")
				case .promptForPasswordAuth: return OCClassSettingsKey("prompt-for-password-auth")
				case .promptForTokenAuth: return OCClassSettingsKey("prompt-for-token-auth")
				case .promptForURL: return OCClassSettingsKey("prompt-for-url")
				case .promptForHelpURL: return OCClassSettingsKey("prompt-for-help-url")
				case .helpURLButtonString: return OCClassSettingsKey("help-url-button-string")
				case .welcome: return OCClassSettingsKey("welcome")
				case .bookmarkName: return OCClassSettingsKey("bookmark-name")
				case .url: return OCClassSettingsKey("url")
				case .helpURL: return OCClassSettingsKey("help-url")
				case .canConfigureURL: return OCClassSettingsKey("can-configure-url")
				case .allowedAuthenticationMethods: return OCClassSettingsKey("allowed-authentication-methods")
				case .allowedHosts: return OCClassSettingsKey("allowed-hosts")
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
		if let helpURLButtonString = profileDict[Key.helpURLButtonString.rawValue] as? String {
			self.helpURLButtonString = helpURLButtonString
		} else if let helpURLButtonString = profileDict[Key.helpURLButtonString.settingsKey.rawValue] as? String {
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
		}
		if let helpURL = profileDict[Key.helpURL.rawValue] as? String {
			self.helpURL = URL(string: helpURL)
		} else if let helpURL = profileDict[Key.helpURL.settingsKey.rawValue] as? String {
			self.helpURL = URL(string: helpURL)
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
					.description 	: "Profile: identifier",
					.status		: OCClassSettingsKeyStatus.advanced,
					.category	: "Branding"
				],

				StaticLoginProfile.Key.name.settingsKey : [
					.type 		: OCClassSettingsMetadataType.string,
					.description 	: "Profile: name",
					.status		: OCClassSettingsKeyStatus.advanced,
					.category	: "Branding"
				],

				StaticLoginProfile.Key.promptForPasswordAuth.settingsKey : [
					.type 		: OCClassSettingsMetadataType.string,
					.description 	: "Profile: prompt for password auth",
					.status		: OCClassSettingsKeyStatus.advanced,
					.category	: "Branding"
				],

				StaticLoginProfile.Key.promptForTokenAuth.settingsKey : [
					.type 		: OCClassSettingsMetadataType.string,
					.description 	: "Profile: prompt for token auth",
					.status		: OCClassSettingsKeyStatus.advanced,
					.category	: "Branding"
				],

				StaticLoginProfile.Key.promptForURL.settingsKey : [
					.type 		: OCClassSettingsMetadataType.string,
					.description 	: "Profile: prompt for URL",
					.status		: OCClassSettingsKeyStatus.advanced,
					.category	: "Branding"
				],

				StaticLoginProfile.Key.promptForHelpURL.settingsKey : [
					.type 		: OCClassSettingsMetadataType.string,
					.description 	: "Profile: prompt for help URL",
					.status		: OCClassSettingsKeyStatus.advanced,
					.category	: "Branding"
				],

				StaticLoginProfile.Key.helpURLButtonString.settingsKey : [
					.type 		: OCClassSettingsMetadataType.string,
					.description 	: "Profile: help URL button string",
					.status		: OCClassSettingsKeyStatus.advanced,
					.category	: "Branding"
				],

				StaticLoginProfile.Key.welcome.settingsKey : [
					.type 		: OCClassSettingsMetadataType.string,
					.description 	: "Profile: welcome message",
					.status		: OCClassSettingsKeyStatus.advanced,
					.category	: "Branding"
				],

				StaticLoginProfile.Key.bookmarkName.settingsKey : [
					.type 		: OCClassSettingsMetadataType.string,
					.description 	: "Profile: bookmark name",
					.status		: OCClassSettingsKeyStatus.advanced,
					.category	: "Branding"
				],

				StaticLoginProfile.Key.url.settingsKey : [
					.type 		: OCClassSettingsMetadataType.urlString,
					.description 	: "Profile: URL",
					.status		: OCClassSettingsKeyStatus.advanced,
					.category	: "Branding"
				],

				StaticLoginProfile.Key.helpURL.settingsKey : [
					.type 		: OCClassSettingsMetadataType.urlString,
					.description 	: "Profile: Help URL",
					.status		: OCClassSettingsKeyStatus.advanced,
					.category	: "Branding"
				],

				StaticLoginProfile.Key.canConfigureURL.settingsKey : [
					.type 		: OCClassSettingsMetadataType.boolean,
					.description 	: "Profile: can configure URL",
					.status		: OCClassSettingsKeyStatus.advanced,
					.category	: "Branding"
				],

				StaticLoginProfile.Key.allowedAuthenticationMethods.settingsKey : [
					.type 		: OCClassSettingsMetadataType.stringArray,
					.description 	: "Profile: allowed authentication methods",
					.status		: OCClassSettingsKeyStatus.advanced,
					.category	: "Branding"
				],

				StaticLoginProfile.Key.allowedHosts.settingsKey : [
					.type 		: OCClassSettingsMetadataType.stringArray,
					.description 	: "Profile: allowed hosts",
					.status		: OCClassSettingsKeyStatus.advanced,
					.category	: "Branding"
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
