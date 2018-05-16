//
//  MoreSettingsSection.swift
//  ownCloud
//
//  Created by Pablo Carrascal on 03/05/2018.
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

import CoreFoundation
import UIKit
import WebKit
import MessageUI

class MoreSettingsSection: SettingsSection {

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

    // MARK: - More Settings Cells

    private var helpRow: StaticTableViewRow?
    private var sendFeedbackRow: StaticTableViewRow?
    private var recommendRow: StaticTableViewRow?
    private var privacyPolicyRow: StaticTableViewRow?

    override init(userDefaults: UserDefaults) {
        super.init(userDefaults: userDefaults)
        self.headerTitle = "More".localized
        self.footerTitle = "Owncloud beta version \(appVersion) build \(appBuildNumber)"

        self.identifier = "settings-more-section"

        createRows()
        updateUI()
    }

    // MARK: - Creation of the rows.

    private func createRows() {

        helpRow = StaticTableViewRow(rowWithAction: { (_, _) in
            let url = URL(string: "https://www.owncloud.com/help")
            let title = "Help".localized
            self.viewController?.navigationController?.pushViewController(WebViewController(url:url!, title: title), animated: true)
        }, title: "Help".localized, accessoryType: .disclosureIndicator)

        sendFeedbackRow = StaticTableViewRow(rowWithAction: { (_, _) in
            self.sendMail(to: "apps@owncloud.com", subject: "ownCloud iOS app (\(self.appVersion) (\(self.appBuildNumber))", message: nil)
        }, title: "Send feedback".localized, accessoryType: .disclosureIndicator)

        recommendRow = StaticTableViewRow(rowWithAction: { (_, _) in
            let message = """
                <p>I want to invite you to use ownCloud on your smartphone!</p>
                <a href="https://itunes.apple.com/app/owncloud/id543672169?mt=8">Download here</a>
                """
            self.sendMail(to: nil, subject: "Try ownCloud on your smartphone!", message: message)
        }, title: "Recommend to a friend".localized, accessoryType: .disclosureIndicator)

        privacyPolicyRow = StaticTableViewRow(rowWithAction: { (_, _) in
            let url = URL(string: "https://owncloud.org/privacy-policy/")
            let title = "Privacy Policy".localized
            self.viewController?.navigationController?.pushViewController(WebViewController(url:url!, title: title), animated: true)
        }, title: "Privacy Policy".localized, accessoryType: .disclosureIndicator)

    }

    // MARK: - Update UI
    func updateUI() {
        add(rows: [helpRow!, sendFeedbackRow!, recommendRow!, privacyPolicyRow!])
    }

    private func sendMail(to: String?, subject: String?, message: String?) {
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

            self.viewController?.present(mail, animated: true)
        } else {
            if let vc = self.viewController {
                let alert = UIAlertController(title: "Please configure an email account".localized,
                                              message: "You need to configure an email account first to be able to send emails.".localized,
                                              preferredStyle: .alert)

                let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                alert.addAction(okAction)
                vc.present(alert, animated: true)
            }
        }
    }
}

extension MoreSettingsSection: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
}
