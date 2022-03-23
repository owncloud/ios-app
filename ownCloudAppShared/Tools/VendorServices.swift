//
//  VendorServices.swift
//  ownCloud
//
//  Created by Felix Schwarz on 29.10.18.
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

public class VendorServices : NSObject {

	enum UserDefaultsKeys: String {
		case notFirstAppLaunch
	}

	// MARK: - App version information
	public var appVersion: String {
		if let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String {
			return version
		}

		return ""
	}

	public var appBuildNumber: String {
		if let buildNumber = Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as? String {
			return buildNumber
		}

		return ""
	}

	public var lastGitCommit: String {
		if let gitCommit = LastGitCommit() {
			return gitCommit
		}

		return ""
	}

	public var documentationURL: URL? {
		return Branding.shared.documentationURL
	}

	public var helpURL: URL? {
		return Branding.shared.helpURL
	}

	public var privacyURL: URL? {
		return Branding.shared.privacyURL
	}

	public var termsOfUseURL: URL? {
		return Branding.shared.termsOfUseURL
	}

	public var appName: String {
		return Branding.shared.appDisplayName
	}

	public var feedbackMail: String? {
		return Branding.shared.feedbackEmailAddress
	}

	public var isBetaBuild: Bool {
		if let isBetaBuild = self.classSetting(forOCClassSettingsKey: .isBetaBuild) as? Bool {
			return isBetaBuild
		}

		return false
	}

	public var isBranded: Bool {
		return Branding.shared.isBranded
	}

	public var canAddAccount: Bool {
		return Branding.shared.canAddAccount
	}

	public var canEditAccount: Bool {
		return Branding.shared.canEditAccount
	}

	public var enableReviewPrompt: Bool {
		if VendorServices.shared.isBranded {
			return Branding.shared.enableReviewPrompt
		}

		return true
	}

	public var showBetaWarning: Bool {
		if let showBetaWarning = self.classSetting(forOCClassSettingsKey: .showBetaWarning) as? Bool {
			return showBetaWarning
		}

		return false
	}

	static public var shared : VendorServices = {
		return VendorServices()
	}()

	// MARK: - Vendor services
	public func considerReviewPrompt() {
		guard
			let reviewPromptEnabled = self.classSetting(forOCClassSettingsKey: .enableReviewPrompt) as? Bool,
			reviewPromptEnabled == true else {
				return
		}

		// Make sure there is at least one bookmark configured, to not bother users who have never configured any accounts
		guard OCBookmarkManager.shared.bookmarks.count > 0 else { return }

		// Make sure at least 7 days have elapsed since the first launch of the app
		guard AppStatistics.shared.timeIntervalSinceFirstLaunch.days >= 7 else { return }

		// Make sure at least 7 days have elapsed since first launch of current version
		guard AppStatistics.shared.timeIntervalSinceUpdate.days >= 7 else { return }

		// Make sure at least 122 have elapsed since last prompting (Apple allows to show the dialog 3 times per 365 days)
		AppStatistics.shared.requestAppStoreReview(onceInDays: 122)
	}

	public func onFirstLaunch(executeBlock:() -> Void) {
		guard let userDefaults = OCAppIdentity.shared.userDefaults else { return }
		guard userDefaults.bool(forKey: UserDefaultsKeys.notFirstAppLaunch.rawValue) == false else { return }

		executeBlock()

		userDefaults.setValue(true, forKey: UserDefaultsKeys.notFirstAppLaunch.rawValue)
		userDefaults.synchronize()
	}
}

// MARK: - OCClassSettings support
public extension OCClassSettingsIdentifier {
	static let app = OCClassSettingsIdentifier("app")
}

public extension OCClassSettingsKey {
	static let showBetaWarning = OCClassSettingsKey("show-beta-warning")
	static let isBetaBuild = OCClassSettingsKey("is-beta-build")
	static let enableUIAnimations = OCClassSettingsKey("enable-ui-animations")

	static let appStoreLink = OCClassSettingsKey("app-store-link")
	static let recommendToFriendEnabled = OCClassSettingsKey("recommend-to-friend-enabled")
}

extension VendorServices : OCClassSettingsSupport {
	public static let classSettingsIdentifier : OCClassSettingsIdentifier = .app

	public static func defaultSettings(forIdentifier identifier: OCClassSettingsIdentifier) -> [OCClassSettingsKey : Any]? {
		if identifier == .app {
			return [
				.isBetaBuild : false,
				.showBetaWarning : false,
				.enableUIAnimations: true,
				.enableReviewPrompt: VendorServices.shared.enableReviewPrompt,

				.appStoreLink : "https://itunes.apple.com/app/id1359583808?mt=8",
				.recommendToFriendEnabled: !VendorServices.shared.isBranded
			]
		}

		return nil
	}

	public static func classSettingsMetadata() -> [OCClassSettingsKey : [OCClassSettingsMetadataKey : Any]]? {
		return [
			.showBetaWarning : [
				.type 		: OCClassSettingsMetadataType.boolean,
				.description	: "Controls whether a warning should be shown on the first run of a beta version.",
				.category	: "App",
				.status		: OCClassSettingsKeyStatus.debugOnly
			],

			.isBetaBuild : [
				.type 		: OCClassSettingsMetadataType.boolean,
				.description	: "Controls if the app is built for beta or release purposes.",
				.category	: "App",
				.status		: OCClassSettingsKeyStatus.debugOnly
			],

			.enableUIAnimations : [
				.type 		: OCClassSettingsMetadataType.boolean,
				.description	: "Enable/disable UI animations.",
				.category	: "App",
				.status		: OCClassSettingsKeyStatus.debugOnly
			],

			.enableReviewPrompt : [
				.type 		: OCClassSettingsMetadataType.boolean,
				.description	: "Enable/disable review prompt.",
				.category	: "App",
				.status		: OCClassSettingsKeyStatus.advanced
			],

			.appStoreLink : [
				.type 		: OCClassSettingsMetadataType.string,
				.description	: "URL for the app in the App Store.",
				.category	: "App",
				.status		: OCClassSettingsKeyStatus.advanced
			],

			.recommendToFriendEnabled : [
				.type 		: OCClassSettingsMetadataType.boolean,
				.description	: "Enables/disables the recommend to a friend entry in the settings.",
				.category	: "App",
				.status		: OCClassSettingsKeyStatus.advanced
			]
		]
	}
}
