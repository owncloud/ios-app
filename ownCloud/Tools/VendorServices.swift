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

	var helpURL: URL? {
		if let path = Bundle.main.path(forResource: "Branding", ofType: "plist") {
			if let themingValues = NSDictionary(contentsOfFile: path), let urls = themingValues["URLs"] as? NSDictionary, let help = urls["Help"] as? String {
				return URL(string: help)
			}
		}

		return URL(string: "https://www.owncloud.com/help")
	}

	var privacyURL: URL? {
		if let path = Bundle.main.path(forResource: "Branding", ofType: "plist") {
			if let themingValues = NSDictionary(contentsOfFile: path), let urls = themingValues["URLs"] as? NSDictionary, let privacy = urls["Privacy"] as? String {
				return URL(string: privacy)
			}
		}

		return URL(string: "https://owncloud.org/privacy-policy/")
	}

	var appName: String {
		if let path = Bundle.main.path(forResource: "Branding", ofType: "plist") {
			if let themingValues = NSDictionary(contentsOfFile: path), let appName = themingValues["AppName"] as? String {
				return appName
			}
		}

		return OCAppIdentity.shared.appName ?? "App"
	}

	var isBetaBuild: Bool {
		if let isBetaBuild = self.classSetting(forOCClassSettingsKey: .isBetaBuild) as? Bool {
			return isBetaBuild
		}

		return false
	}

	var isBranded: Bool {
		if let path = Bundle.main.path(forResource: "Branding", ofType: "plist") {
			if let themingValues = NSDictionary(contentsOfFile: path), let appName = themingValues["AppName"] as? String, !appName.hasPrefix("ownCloud") {
				return true
			}
		}

		return false
	}

	var hasBrandedProfiles: Bool {
		if let path = Bundle.main.path(forResource: "Branding", ofType: "plist") {
			if let themingValues = NSDictionary(contentsOfFile: path), let profiles = themingValues["Profiles"] as? NSArray, profiles.count > 0 {
				return true
			}
		}

		return false
	}

	var hasBrandedLogin: Bool {
		if let path = Bundle.main.path(forResource: "Branding", ofType: "plist") {
			if let themingValues = NSDictionary(contentsOfFile: path), let bundleValues = themingValues["Bundle"] as? NSDictionary, bundleValues["organizationLogoName"] != nil, bundleValues["organizationBackgroundName"] != nil, bundleValues["organizationName"] != nil {
				return true
			}
		}

		return false
	}

	var canAddAccount: Bool {
		if let path = Bundle.main.path(forResource: "Branding", ofType: "plist") {
			if let themingValues = NSDictionary(contentsOfFile: path), let canAddAccount = themingValues["canAddAccount"] as? Bool {
				if canAddAccount, VendorServices.shared.hasBrandedProfiles {
					return true
				}

				return false
			}
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

		guard let feedbackEmail = MoreSettingsSection.classSetting(forOCClassSettingsKey: .feedbackEmail) as? String,
			let appName = OCAppIdentity.shared.appName else {
				return
		}
		self.sendMail(to: feedbackEmail, subject: "\(self.appVersion) (\(self.appBuildNumber)) \(buildType) \(appName)", message: nil, from: viewController)
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
}

extension VendorServices : OCClassSettingsSupport {
	static let classSettingsIdentifier : OCClassSettingsIdentifier = .app

	static func defaultSettings(forIdentifier identifier: OCClassSettingsIdentifier) -> [OCClassSettingsKey : Any]? {
		if identifier == .app {
			return [ .isBetaBuild : false, .showBetaWarning : false, .enableUIAnimations: true ]
		}

		return nil
	}
}
