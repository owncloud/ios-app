//
//  MoreSettingsSection.swift
//  ownCloud
//
//  Created by Pablo Carrascal on 03/05/2018.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//
import UIKit
import WebKit
import MessageUI

// MARK: - Section identifier
private let MoreSectionIdentifier: String = "settings-more-section"

class MoreSettingsSection: StaticTableViewSection, MFMailComposeViewControllerDelegate {

    // MARK: - More Settings Cells

    private var helpRow: StaticTableViewRow?
    private var sendFeedbackRow: StaticTableViewRow?
    private var recommendRow: StaticTableViewRow?
    private var privacyPolicyRow: StaticTableViewRow?

    override init() {
        super.init()
        self.headerTitle = "More".localized
        self.footerTitle = "owncloud 2018 iOS beta"
        self.identifier = MoreSectionIdentifier

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
            self.sendMail(to: "apps@owncloud.com", subject: nil, message: nil)
        }, title: "Send feedback".localized, accessoryType: .disclosureIndicator)

        recommendRow = StaticTableViewRow(rowWithAction: { (_, _) in
            let message = """
                <p>I want to invite you to use ownCloud on your smartphone!</p>
                <a href="https://itunes.apple.com/es/app/owncloud/id543672169?mt=8">Download here</a>
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

        self.reload()
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
        }
    }

    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
}
