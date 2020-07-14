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
import ownCloudAppShared

class VendorServices : NSObject {
	// MARK: - App version information
	var appVersion: String {
		if let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String {
			return version
		}

		return ""
	}

	var appBuildNumber: String {
		if let buildNumber = Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as? String {
			return buildNumber
		}

		return ""
	}

	var lastGitCommit: String {
		if let gitCommit = LastGitCommit() {
			return gitCommit
		}

		return ""
	}

	var brandingURL : URL? {
		return Bundle.main.url(forResource: "Branding", withExtension: "plist")
	}

	func brandingURLFor(name: String) -> URL? {
		return Bundle.main.url(forResource: name, withExtension: "plist")
	}

	var brandingProperties : NSDictionary? {
		var themingValues : NSDictionary?

		if let url = self.brandingURL {
			themingValues = NSDictionary(contentsOf: url)
		}

		return themingValues
	}

	var helpURL: URL? {
		if let themingValues = self.brandingProperties {
			guard let urls = themingValues["URLs"] as? NSDictionary, let help = urls["Help"] as? String, let url = URL(string: help) else { return nil }
			return url
		}

		return URL(string: "https://www.owncloud.com/help")
	}

	var privacyURL: URL? {
		if let themingValues = self.brandingProperties {
			guard let urls = themingValues["URLs"] as? NSDictionary, let privacy = urls["Privacy"] as? String, let url = URL(string: privacy) else { return nil }
			return url
		}

		return URL(string: "https://owncloud.org/privacy-policy/")
	}

	var appName: String {
		if let bundleValues = self.brandingProperties, let organizationName = bundleValues["organizationName"] as? String {
			return organizationName
		}

		return OCAppIdentity.shared.appName ?? "App"
	}

	var feedbackMail: String? {
		if let bundleValues = self.brandingProperties, let feedbackMail = bundleValues["feedbackMail"] as? String {
			return feedbackMail
		}
		if let feedbackMail = MoreSettingsSection.classSetting(forOCClassSettingsKey: .feedbackEmail) as? String {
			return feedbackMail
		}

		return nil
	}

	var isBetaBuild: Bool {
		if let isBetaBuild = self.classSetting(forOCClassSettingsKey: .isBetaBuild) as? Bool {
			return isBetaBuild
		}

		return false
	}

	var isBranded: Bool {
		if let themingValues = self.brandingProperties, let profileValues = themingValues["Profiles"] as? NSArray, profileValues.count > 0 {
			return true
		}

		return false
	}

	var hasBrandedProfiles: Bool {
		if let themingValues = self.brandingProperties, let profiles = themingValues["Profiles"] as? NSArray, profiles.count > 0 {
			return true
		}

		return false
	}

	var hasBrandedLogin: Bool {
		if let bundleValues = self.brandingProperties, bundleValues["organizationName"] != nil {
			return true
		}

		return false
	}

	var canAddAccount: Bool {
		if let themingValues = self.brandingProperties, let canAddAccount = themingValues["canAddAccount"] as? Bool {
			if canAddAccount, VendorServices.shared.hasBrandedProfiles {
				return true
			}

			return false
		}

		return true
	}

	var showBetaWarning: Bool {
		if let showBetaWarning = self.classSetting(forOCClassSettingsKey: .showBetaWarning) as? Bool {
			return showBetaWarning
		}

		return false
	}

	static var shared : VendorServices = {
		return VendorServices()
	}()

	// MARK: - Vendor services
	func recommendToFriend(from viewController: UIViewController) {

		guard let appStoreLink = MoreSettingsSection.classSetting(forOCClassSettingsKey: .appStoreLink) as? String,
			let appName = OCAppIdentity.shared.appName else {
				return
		}

		let message = """
		<p>I want to invite you to use \(appName) on your smartphone!</p>
		<a href="\(appStoreLink)">Download here</a>
		"""
		self.sendMail(to: nil, subject: "Try \(appName) on your smartphone!", message: message, from: viewController)
	}

	func sendFeedback(from viewController: UIViewController) {
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
		self.sendMail(to: feedbackEmail, subject: "\(self.appVersion) (\(self.appBuildNumber)) \(buildType) \(appName)\(appSuffix)", message: nil, from: viewController)
	}

	func sendMail(to: String?, subject: String?, message: String?, from viewController: UIViewController) {
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

	func considerReviewPrompt() {
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
	func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
		controller.dismiss(animated: true)
	}
}

// MARK: - OCClassSettings support
extension OCClassSettingsIdentifier {
	static let app = OCClassSettingsIdentifier("app")
}

extension OCClassSettingsKey {
	static let showBetaWarning = OCClassSettingsKey("show-beta-warning")
	static let isBetaBuild = OCClassSettingsKey("is-beta-build")
	static let enableUIAnimations = OCClassSettingsKey("enable-ui-animations")
	static let enableReviewPrompt = OCClassSettingsKey("enable-review-prompt")
}

extension VendorServices : OCClassSettingsSupport {
	static let classSettingsIdentifier : OCClassSettingsIdentifier = .app

	static func defaultSettings(forIdentifier identifier: OCClassSettingsIdentifier) -> [OCClassSettingsKey : Any]? {
		if identifier == .app {
			return [ .isBetaBuild : false, .showBetaWarning : false, .enableUIAnimations: true, .enableReviewPrompt: true]
		}

		return nil
	}
}
