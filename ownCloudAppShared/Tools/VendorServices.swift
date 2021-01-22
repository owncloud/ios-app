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
import MessageUI
import ownCloudSDK
import ownCloudApp

public class VendorServices : NSObject {
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
		if let appName = Branding.shared.appName {
			return appName
		}

		if let organizationName = Branding.shared.organizationName {
			return organizationName
		}

		return OCAppIdentity.shared.appDisplayName ?? "ownCloud"
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
	public func recommendToFriend(from viewController: UIViewController) {

		guard let appStoreLink = self.classSetting(forOCClassSettingsKey: .appStoreLink) as? String else {
				return
		}
		let appName = VendorServices.shared.appName

		let message = """
		<p>I want to invite you to use \(appName) on your smartphone!</p>
		<a href="\(appStoreLink)">Download here</a>
		"""
		self.sendMail(to: nil, subject: "Try \(appName) on your smartphone!", message: message, from: viewController)
	}

	public func sendFeedback(from viewController: UIViewController) {
		var buildType = "release".localized

		if self.isBetaBuild {
			buildType = "beta".localized
		}

		var appSuffix = ""
		if OCLicenseEMMProvider.isEMMVersion {
			appSuffix = "-EMM"
		}

		guard let feedbackEmail = self.feedbackMail else {
			return
		}
		self.sendMail(to: feedbackEmail, subject: "\(self.appVersion) (\(self.appBuildNumber)) \(buildType) \(self.appName)\(appSuffix)", message: nil, from: viewController)
	}

	public func sendMail(to: String?, subject: String?, message: String?, from viewController: UIViewController) {
		if MFMailComposeViewController.canSendMail() {
			let mail = MFMailComposeViewController()
			mail.mailComposeDelegate = self
			if to != nil {
				mail.setToRecipients([to!])
			}

			if subject != nil {
				mail.setSubject(subject!)
			}

			if message != nil {
				mail.setMessageBody(message!, isHTML: true)
			}

			viewController.present(mail, animated: true)
		} else {
			let alert = ThemedAlertController(title: "Please configure an email account".localized,
											  message: "You need to configure an email account first to be able to send emails.".localized,
											  preferredStyle: .alert)

			let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
			alert.addAction(okAction)
			viewController.present(alert, animated: true)
		}
	}

	public func considerReviewPrompt() {
		guard
			let reviewPromptEnabled = self.classSetting(forOCClassSettingsKey: .enableReviewPrompt) as? Bool,
			reviewPromptEnabled == true else {
				return
		}

		// Make sure there is at least one bookmark configured, to not bother users who have never configured any accounts
		guard OCBookmarkManager.shared.bookmarks.count > 0 else { return }

		// Make sure at least 14 days have elapsed since the first launch of the app
		guard AppStatistics.shared.timeIntervalSinceFirstLaunch.days >= 14 else { return }

		// Make sure at least 7 days have elapsed since first launch of current version
		guard AppStatistics.shared.timeIntervalSinceUpdate.days >= 7 else { return }

		// Make sure at least 230 have elapsed since last prompting
		AppStatistics.shared.requestAppStoreReview(onceInDays: 230)
	}
}

extension VendorServices: MFMailComposeViewControllerDelegate {
	public func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
		controller.dismiss(animated: true)
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
	static let enableReviewPrompt = OCClassSettingsKey("enable-review-prompt")

	static let appStoreLink = OCClassSettingsKey("app-store-link")
	static let recommendToFriendEnabled = OCClassSettingsKey("recommend-to-friend-enabled")
}

extension VendorServices : OCClassSettingsSupport {
	public static let classSettingsIdentifier : OCClassSettingsIdentifier = .app

	public static func defaultSettings(forIdentifier identifier: OCClassSettingsIdentifier) -> [OCClassSettingsKey : Any]? {
		if identifier == .app {
			return [
				.isBetaBuild : true,
				.showBetaWarning : true,
				.enableUIAnimations: true,
				.enableReviewPrompt: !VendorServices.shared.isBranded,

				.appStoreLink : "https://itunes.apple.com/app/id1359583808?mt=8",
				.recommendToFriendEnabled: !VendorServices.shared.isBranded,
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
			],
		]
	}
}
