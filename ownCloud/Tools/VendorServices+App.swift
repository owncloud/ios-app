//
//  VendorServices.swift
//  ownCloud
//
//  Created by Felix Schwarz on 13.09.21.
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
import MessageUI
import ownCloudApp
import ownCloudAppShared
import ownCloudSDK

extension VendorServices {
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
		if let sendFeedbackURL = Branding.shared.feedbackURL {
			UIApplication.shared.open(sendFeedbackURL, options: [:], completionHandler: nil)
		} else {
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
}

extension VendorServices: MFMailComposeViewControllerDelegate {
	public func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
		controller.dismiss(animated: true)
	}
}
