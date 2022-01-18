//
//  Branding+App.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 21.01.21.
//  Copyright © 2021 ownCloud GmbH. All rights reserved.
//

import UIKit
import ownCloudApp
import ownCloudSDK

extension OCClassSettingsKey {
	// URLs
	public static let documentationURL : OCClassSettingsKey = OCClassSettingsKey("url-documentation")
	public static let helpURL : OCClassSettingsKey = OCClassSettingsKey("url-help")
	public static let privacyURL : OCClassSettingsKey = OCClassSettingsKey("url-privacy")
	public static let termsOfUseURL : OCClassSettingsKey = OCClassSettingsKey("url-terms-of-use")

	// Email
	public static let sendFeedbackAddress : OCClassSettingsKey = OCClassSettingsKey("send-feedback-address")
	public static let sendFeedbackURL : OCClassSettingsKey = OCClassSettingsKey("send-feedback-url")

	// Permissions
	public static let canAddAccount : OCClassSettingsKey = OCClassSettingsKey("can-add-account")
	public static let canEditAccount : OCClassSettingsKey = OCClassSettingsKey("can-edit-account")
	public static let enableReviewPrompt : OCClassSettingsKey = OCClassSettingsKey("enable-review-prompt")

	// Profiles
	public static let profileDefinitions : OCClassSettingsKey = OCClassSettingsKey("profile-definitions")

	// Themes
	public static let themeGenericColors : OCClassSettingsKey = OCClassSettingsKey("theme-generic-colors")
	public static let themeDefinitions : OCClassSettingsKey = OCClassSettingsKey("theme-definitions")
}

extension Branding : BrandingInitialization {
	public static func initializeBranding() {
		if #available(iOS 13, *) {
			self.registerOCClassSettingsDefaults([
				.documentationURL : "https://doc.owncloud.com/ios-app/latest/",
				.helpURL 	  : "https://owncloud.com/docs-guides/",
				.privacyURL 	  : "https://owncloud.org/privacy-policy/",
				.termsOfUseURL 	  : "https://raw.githubusercontent.com/owncloud/ios-app/master/LICENSE",

				.sendFeedbackAddress : "ios-app@owncloud.com",

				.canAddAccount : true,
				.canEditAccount : true,
				.enableReviewPrompt : false

	//			.profileDefinitions : [],
	//			.themeGenericColors : [:],
	//			.themeDefinitions : [:]
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
					.type 		: OCClassSettingsMetadataType.urlString,
					.label		: "Terms of use URL",
					.description 	: "URL to terms of use for the app. Opened when selecting \"Terms Of Use\" in the settings.",
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
				]
			])
		}
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
		return (organizationName != nil) && // Organization name must be set
		       ((profileDefinitions?.count ?? 0) > 0) // At least one profile needs to have been defined
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
}

extension Branding {
	func generateThemeStyle(from theme: [String : Any], generic: [String : Any]) -> ThemeStyle? {
		let style = theme["ThemeStyle"] as? String ?? "contrast"
		let identifier = theme["Identifier"] as? String ?? "com.owncloud.branding"
		let name = theme["Name"] as? String ?? "ownCloud-branding-theme"

		if let themeStyle = ThemeCollectionStyle(rawValue: style),
		   let darkBrandColor = theme["darkBrandColor"] as? String,
		   let lightBrandColor = theme["lightBrandColor"] as? String {
			let colors = theme["Colors"] as? NSDictionary
			let styles = theme["Styles"] as? NSDictionary
			return ThemeStyle(styleIdentifier: identifier, localizedName: name.localized, lightColor: lightBrandColor.colorFromHex ?? UIColor.red, darkColor: darkBrandColor.colorFromHex ?? UIColor.blue, themeStyle: themeStyle, customizedColorsByPath: nil, customColors: colors, genericColors: generic as NSDictionary?, interfaceStyles: styles)
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
