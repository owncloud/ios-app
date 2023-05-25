//
//  Branding+App.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 21.01.21.
//  Copyright © 2021 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2021, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import UIKit
import ownCloudApp
import ownCloudSDK

extension OCClassSettingsKey {
	// URLs
	public static let documentationURL : OCClassSettingsKey = OCClassSettingsKey("url-documentation")
	public static let helpURL : OCClassSettingsKey = OCClassSettingsKey("url-help")
	public static let privacyURL : OCClassSettingsKey = OCClassSettingsKey("url-privacy")
	public static let termsOfUseURL : OCClassSettingsKey = OCClassSettingsKey("url-terms-of-use")
	public static let themeJSONURL : OCClassSettingsKey = OCClassSettingsKey("url-theme-json")

	// Email
	public static let sendFeedbackAddress : OCClassSettingsKey = OCClassSettingsKey("send-feedback-address")
	public static let sendFeedbackURL : OCClassSettingsKey = OCClassSettingsKey("send-feedback-url")

	// Permissions
	public static let canAddAccount : OCClassSettingsKey = OCClassSettingsKey("can-add-account")
	public static let canEditAccount : OCClassSettingsKey = OCClassSettingsKey("can-edit-account")
	public static let enableReviewPrompt : OCClassSettingsKey = OCClassSettingsKey("enable-review-prompt")

	public static let profileBookmarkName : OCClassSettingsKey = OCClassSettingsKey("profile-bookmark-name")
	public static let profileURL : OCClassSettingsKey = OCClassSettingsKey("profile-url")
	public static let profileAllowUrlConfiguration : OCClassSettingsKey = OCClassSettingsKey("profile-allow-url-configuration")
	public static let profileHelpButtonLabel = OCClassSettingsKey("profile-help-button-label")
	public static let profileOpenHelpMessage = OCClassSettingsKey("profile-open-help-message")
	public static let profileHelpURL = OCClassSettingsKey("profile-help-url")

	public static let sidebarLinks = OCClassSettingsKey("sidebar-links")
	public static let sidebarLinksTitle = OCClassSettingsKey("sidebar-links-title")

	// Profiles
	public static let profileDefinitions : OCClassSettingsKey = OCClassSettingsKey("profile-definitions")

	// Themes
	public static let themeGenericColors : OCClassSettingsKey = OCClassSettingsKey("theme-generic-colors")
	public static let themeDefinitions : OCClassSettingsKey = OCClassSettingsKey("theme-definitions")
}

extension Branding : BrandingInitialization {
	public static func initializeBranding() {
		self.registerOCClassSettingsDefaults([
			.documentationURL : "https://doc.owncloud.com/ios-app/latest/",
			.helpURL 	  : "https://owncloud.com/docs-guides/",
			.privacyURL 	  : "https://owncloud.org/privacy-policy/",
			.termsOfUseURL 	  : "https://raw.githubusercontent.com/owncloud/ios-app/master/LICENSE",
			.sendFeedbackAddress : "ios-app@owncloud.com",
			.canAddAccount : true,
			.canEditAccount : true,
			.enableReviewPrompt : false
		], metadata: [
			.documentationURL : [
				.type 		: OCClassSettingsMetadataType.urlString,
				.label		: "Documentation URL",
				.description 	: "URL to documentation for the app. Opened when selecting \"Documentation\" in the settings.",
				.status		: OCClassSettingsKeyStatus.advanced,
				.category	: "Branding"
			],

			.helpURL : [
				.type 		: OCClassSettingsMetadataType.urlString,
				.label		: "Help URL",
				.description 	: "URL to get help for the app. Opened when selecting \"Help\" in the settings.",
				.status		: OCClassSettingsKeyStatus.advanced,
				.category	: "Branding"
			],

			.privacyURL : [
				.type 		: OCClassSettingsMetadataType.urlString,
				.label		: "Privacy URL",
				.description 	: "URL to get privacy information for the app. Opened when selecting \"Privacy\" in the settings.",
				.status		: OCClassSettingsKeyStatus.advanced,
				.category	: "Branding"
			],

			.termsOfUseURL : [
				.type		: OCClassSettingsMetadataType.urlString,
				.label		: "Terms of use URL",
				.description	: "URL to terms of use for the app. Opened when selecting \"Terms Of Use\" in the settings.",
				.status		: OCClassSettingsKeyStatus.advanced,
				.category	: "Branding"
			],

			.themeJSONURL : [
				.type		: OCClassSettingsMetadataType.urlString,
				.label		: "URL of the theme.json",
				.description	: "URL of the instance theme.json file, which can contain instance or app specific branding parameter. Setting this to `auto` will construct the URL by adding `themes/owncloud/theme.json` to the respective server's base address.",
				.status		: OCClassSettingsKeyStatus.advanced,
				.category	: "Branding"
			],

			.sendFeedbackAddress : [
				.type 		: OCClassSettingsMetadataType.string,
				.label		: "Feedback Email address",
				.description	: "Email address to send feedback to. Set to `null` to disable this feature.",
				.category	: "Branding",
				.status		: OCClassSettingsKeyStatus.advanced
			],

			.sendFeedbackURL : [
				.type 		: OCClassSettingsMetadataType.string,
				.label		: "Feedback URL",
				.description	: "URL to open when selecting the \"Send feedback\" option. Allows the use of all placeholders provided in `http.user-agent`.",
				.category	: "Branding",
				.status		: OCClassSettingsKeyStatus.advanced
			],

			.canAddAccount : [
				.type 		: OCClassSettingsMetadataType.boolean,
				.label		: "Allow adding accounts",
				.description	: "Controls whether the user can add accounts.",
				.category	: "Branding",
				.status		: OCClassSettingsKeyStatus.advanced
			],

			.canEditAccount : [
				.type 		: OCClassSettingsMetadataType.boolean,
				.label		: "Allow editing accounts",
				.description	: "Controls whether the user can edit accounts.",
				.category	: "Branding",
				.status		: OCClassSettingsKeyStatus.advanced
			],

			.enableReviewPrompt : [
				.type 		: OCClassSettingsMetadataType.boolean,
				.description	: "Controls whether the app should prompt for an App Store review. Only applies if the app is branded.",
				.category	: "Branding",
				.status		: OCClassSettingsKeyStatus.advanced
			],

			.profileDefinitions : [
				.type 		: OCClassSettingsMetadataType.dictionaryArray,
				.label		: "Profile definitions",
				.description	: "Array of dictionaries, each specifying a profile. All `Profile` keys can be used in the profile dictionaries.",
				.category	: "Branding",
				.status		: OCClassSettingsKeyStatus.advanced
			],

			.themeGenericColors : [
				.type 		: OCClassSettingsMetadataType.dictionary,
				.description	: "Dictionary defining generic colors that can be used in the definitions.",
				.category	: "Branding",
				.status		: OCClassSettingsKeyStatus.advanced
			],

			.themeDefinitions : [
				.type 		: OCClassSettingsMetadataType.dictionaryArray,
				.description	: "Array of dictionaries, each specifying a theme.",
				.category	: "Branding",
				.status		: OCClassSettingsKeyStatus.advanced
			],

			.profileBookmarkName : [
				.type         : OCClassSettingsMetadataType.string,
				.label        : "Bookmark Name",
				.description    : "The name that should be used for the bookmark that's generated from this profile and appears in the account list.",
				.status        : OCClassSettingsKeyStatus.advanced,
				.category    : "Branding"
			],

			.profileURL : [
				.type         : OCClassSettingsMetadataType.urlString,
				.label        : "URL",
				.description     : "The URL of the server targeted by this profile.",
				.status        : OCClassSettingsKeyStatus.advanced,
				.category    : "Branding"
			],

			.profileHelpURL : [
				.type         : OCClassSettingsMetadataType.urlString,
				.label         : "Onboarding URL",
				.description    : "Optional URL to onboarding resources.",
				.status        : OCClassSettingsKeyStatus.advanced,
				.category    : "Branding"
			],

			.profileOpenHelpMessage: [
				.type         : OCClassSettingsMetadataType.string,
				.label        : "Open onboarding URL message",
				.description     : "Message shown in an alert before opening the onboarding URL.",
				.status        : OCClassSettingsKeyStatus.advanced,
				.category    : "Branding"
			],

			.profileHelpButtonLabel : [
				.type         : OCClassSettingsMetadataType.string,
				.label        : "Onboarding button title",
				.description     : "Text used for the onboarding button title",
				.status        : OCClassSettingsKeyStatus.advanced,
				.category    : "Branding"
			],

			.profileAllowUrlConfiguration : [
				.type         : OCClassSettingsMetadataType.boolean,
				.label         : "Allow URL configuration",
				.description    : "Indicates if the user can change the server URL for the account.",
				.status        : OCClassSettingsKeyStatus.advanced,
				.category    : "Branding"
			],

			.sidebarLinks : [
				.type         : OCClassSettingsMetadataType.array,
				.label         : "Sidebar Links",
				.description    : "Array with Links, which should appear in the sidebar.",
				.status        : OCClassSettingsKeyStatus.advanced,
				.category    : "Branding"
			],

			.sidebarLinksTitle : [
				.type         : OCClassSettingsMetadataType.string,
				.label         : "Sidebar Links Title",
				.description    : "Title for the sidebar links section.",
				.status        : OCClassSettingsKeyStatus.advanced,
				.category    : "Branding"
			]
		])
	}

	public func initializeSharedBranding() {
		// swiftlint:disable comma
		registerLegacyKeyPath("URLs.Documentation",	forClassSettingsKey: .documentationURL)
		registerLegacyKeyPath("URLs.Help",		forClassSettingsKey: .helpURL)
		registerLegacyKeyPath("URLs.Privacy",		forClassSettingsKey: .privacyURL)
		registerLegacyKeyPath("URLs.TermsOfUse",	forClassSettingsKey: .termsOfUseURL)

		registerLegacyKeyPath("feedbackMail",		forClassSettingsKey: .sendFeedbackAddress)

		registerLegacyKeyPath("canAddAccount",		forClassSettingsKey: .canAddAccount)
		registerLegacyKeyPath("canEditAccount",		forClassSettingsKey: .canEditAccount)
		registerLegacyKeyPath("enableReviewPrompt",	forClassSettingsKey: .enableReviewPrompt)

		registerLegacyKeyPath("Profiles",		forClassSettingsKey: .profileDefinitions)

		registerLegacyKeyPath("Generic",		forClassSettingsKey: .themeGenericColors)
		registerLegacyKeyPath("Themes",			forClassSettingsKey: .themeDefinitions)
		// swiftlint:enable comma
	}
}

extension BrandingImageName {
	public static let loginLogo : BrandingImageName = BrandingImageName("branding-login-logo")
	public static let loginBackground : BrandingImageName = BrandingImageName("branding-login-background")

	public static let splashscreenLogo : BrandingImageName = BrandingImageName("branding-splashscreen")
	public static let splashscreenBackground : BrandingImageName = BrandingImageName("branding-splashscreen-background")

	public static let bookmarkIcon : BrandingImageName = BrandingImageName("branding-bookmark-icon")
}

extension Branding {
	public var isBranded: Bool {
		return (organizationName != nil) // Organization name must be set
	}

	public var documentationURL : URL? {
		return url(forClassSettingsKey: .documentationURL)
	}

	public var helpURL : URL? {
		return url(forClassSettingsKey: .helpURL)
	}

	public var privacyURL : URL? {
		return url(forClassSettingsKey: .privacyURL)
	}

	public var termsOfUseURL : URL? {
		return url(forClassSettingsKey: .termsOfUseURL)
	}

	public var themeJSONURL : URL? {
		let themeJSONURL = url(forClassSettingsKey: .themeJSONURL)

		if themeJSONURL?.absoluteString == "auto" {
			return nil
		}

		return themeJSONURL
	}

	public var useThemeJSON: Bool {
		return ((computedValue(forClassSettingsKey: .themeJSONURL) as? URL)?.absoluteString == "auto") || (themeJSONURL != nil)
	}

	public var feedbackEmailAddress : String? {
		var feedbackEmailAddress = computedValue(forClassSettingsKey: .sendFeedbackAddress) as? String

		if feedbackEmailAddress == "" || feedbackEmailAddress == "null" {
			feedbackEmailAddress = nil
		}

		return feedbackEmailAddress
	}

	public var feedbackURL : URL? {
		var feedbackURLTemplate = computedValue(forClassSettingsKey: .sendFeedbackURL) as? String

		if let template = feedbackURLTemplate {
			feedbackURLTemplate = OCHTTPPipeline.string(forTemplate:template, variables: nil)
		}

		if let feedbackURLTemplate = feedbackURLTemplate, feedbackURLTemplate.count > 0 {
			return URL(string: feedbackURLTemplate)
		}

		return nil
	}

	public var canAddAccount : Bool {
		return computedValue(forClassSettingsKey: .canAddAccount) as? Bool ?? true
	}

	public var canEditAccount : Bool {
		return computedValue(forClassSettingsKey: .canEditAccount) as? Bool ?? true
	}

	public var enableReviewPrompt : Bool {
		return computedValue(forClassSettingsKey: .enableReviewPrompt) as? Bool ?? false
	}

	public var profileDefinitions : [[String : Any]]? {
		var definitions = computedValue(forClassSettingsKey: .profileDefinitions) as? [[String : Any]]

		if definitions == nil {
			if let bridge = self as? StaticProfileBridge, let definitionDict = type(of: bridge).composeBrandingDict() {
				definitions = [ definitionDict ]
			}
		}

		return definitions
	}

	public var profileBookmarkName: String? {
		return computedValue(forClassSettingsKey: .profileBookmarkName) as? String ?? nil
	}

	public var profileURL: URL? {
		return url(forClassSettingsKey: .profileURL) ?? nil
	}

	public var profileAllowUrlConfiguration: Bool? {
		return computedValue(forClassSettingsKey: .profileAllowUrlConfiguration) as? Bool ?? nil
	}

	public var profileOpenHelpMessage: String? {
		return computedValue(forClassSettingsKey: .profileOpenHelpMessage) as? String ?? nil
	}

	public var profileHelpButtonLabel: String? {
		return computedValue(forClassSettingsKey: .profileHelpButtonLabel) as? String ?? nil
	}

	public var profileHelpURL: URL? {
		return url(forClassSettingsKey: .profileHelpURL) ?? nil
	}

	public var sidebarLinks: Array<SidebarLink>? {
		if let values = computedValue(forClassSettingsKey: .sidebarLinks) as? Array<Dictionary<String, String>> {
			return values.compactMap { link in
				if let title = link["title"], let urlString = link["url"], let url = URL(string: urlString) {
					return SidebarLink(title: title, symbol: link["symbol"], image: link["image"], url: url)
				}

				return nil
			}
		}

		return nil
	}

	public var sidebarLinksTitle: String? {
		return computedValue(forClassSettingsKey: .sidebarLinksTitle) as? String ?? nil
	}
}

public struct SidebarLink {
    var title: String
    var symbol: String?
    var image: String?
    var url: URL
}

extension Branding {
	func generateThemeStyle(from theme: [String : Any], generic: [String : Any]) -> ThemeStyle? {
		let style = theme["ThemeStyle"] as? String ?? ThemeCollectionStyle.light.rawValue
		let identifier = theme["Identifier"] as? String ?? "com.owncloud.branding"
		let name = theme["Name"] as? String ?? "ownCloud-branding-theme"
		let cssRecordStrings = theme["cssRecords"] as? [String]

		if let themeStyle = ThemeCollectionStyle(rawValue: style),
		   let darkBrandColor = theme["darkBrandColor"] as? String,
		   let lightBrandColor = theme["lightBrandColor"] as? String {
			let colors = theme["Colors"] as? NSDictionary
			let styles = theme["Styles"] as? NSDictionary
			return ThemeStyle(styleIdentifier: identifier, localizedName: name.localized, lightColor: lightBrandColor.colorFromHex ?? UIColor.red, darkColor: darkBrandColor.colorFromHex ?? UIColor.blue, themeStyle: themeStyle, customColors: colors, genericColors: generic as NSDictionary?, interfaceStyles: styles, cssRecordStrings: cssRecordStrings)
		}

		return nil
	}

	public func setupThemeStyles() -> Bool {
		var extractedThemeStyles : [ThemeStyle] = []

		if let themeStyleDefinitions = self.computedValue(forClassSettingsKey: .themeDefinitions) as? [[String : Any]] {
			let generic = self.computedValue(forClassSettingsKey: .themeGenericColors) as? [String : Any] ?? [:]
			for themeStyleDefinition in themeStyleDefinitions {
				if let themeStyle = self.generateThemeStyle(from: themeStyleDefinition, generic: generic) {
					extractedThemeStyles.append(themeStyle)
				}
			}
		}

		var isDefault = true

		for themeStyle in extractedThemeStyles {
			let themeStyleExtension = themeStyle.themeStyleExtension(isDefault: isDefault)
			OCExtensionManager.shared.addExtension(themeStyleExtension)
			isDefault = false
		}

		return !isDefault // only true if there's at least one theme
	}
}

public extension ThemeCSSSelector {
	static let welcome = ThemeCSSSelector(rawValue: "welcome")
}
