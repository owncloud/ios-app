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

	static var shared : VendorServices = {
		return VendorServices()
	}()

	// MARK: - Vendor services
	func recommendToFriend(from viewController: UIViewController) {
		let message = """
<p>I want to invite you to use ownCloud on your smartphone!</p>
<a href="https://itunes.apple.com/app/owncloud/id543672169?mt=8">Download here</a>
"""
		self.sendMail(to: nil, subject: "Try ownCloud on your smartphone!", message: message, from: viewController)
	}

	func sendFeedback(from viewController: UIViewController) {
		self.sendMail(to: "ios-beta@owncloud.com", subject: "ownCloud iOS app beta (\(self.appVersion) (\(self.appBuildNumber)))", message: nil, from: viewController)
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
			let alert = UIAlertController(title: "Please configure an email account".localized,
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
