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

// MARK: - Row identifiers
private let MoreHelpRowIdentifier: String = "more-help-row"
private let MoreSendFeedbackRowIdentifier: String = "more-feedback-row"
private let MoreRecommendRowIdentifier: String = "more-recommend-row"
private let MorePrivacyPolicyRowIdentifier: String = "more-privacy-policy-row"
private let MoreAppVersionRowIdentifier: String = "more-app-version-row"

class MoreSettingsSection: StaticTableViewSection, MFMailComposeViewControllerDelegate {

    override init() {
        super.init()
        self.headerTitle = "More".localized
        self.identifier = MoreSectionIdentifier

        updateUI()
    }

    // MARK: - Creation of the rows.

    private func helpRow() -> StaticTableViewRow {
        let helpRow = StaticTableViewRow(rowWithAction: { (_, _) in
            let url = URL(string: "https://www.owncloud.com/help")
            let title = "Help".localized
        self.viewController?.navigationController?.pushViewController(WebViewController(url:url!, title: title), animated: true)
        }, title: "Help".localized, accessoryType: .disclosureIndicator, identifier: MoreHelpRowIdentifier)

        return helpRow
    }

    private func sendFeedbackRow() -> StaticTableViewRow {
        let sendFeedbackRow = StaticTableViewRow(rowWithAction: { (_, _) in
            self.sendMail(to: "apps@owncloud.com", subject: nil, message: nil)
        }, title: "Send feedback".localized, accessoryType: .disclosureIndicator, identifier: MoreSendFeedbackRowIdentifier)

        return sendFeedbackRow
    }

    private func recommendRow() -> StaticTableViewRow {
        let recommendRow = StaticTableViewRow(rowWithAction: { (_, _) in
            let message = """
                <p>I want to invite you to use ownCloud on your smartphone!</p>
                <a href="https://itunes.apple.com/es/app/owncloud/id543672169?mt=8">Download here</a>
                """
            self.sendMail(to: nil, subject: "Try ownCloud on your smartphone!", message: message)
        }, title: "Recommend to a friend".localized, accessoryType: .disclosureIndicator, identifier: MoreRecommendRowIdentifier)

        return recommendRow
    }

    private func privacyPolicyRow() -> StaticTableViewRow {
        let privacyPolicyRow = StaticTableViewRow(rowWithAction: { (_, _) in
            let url = URL(string: "https://owncloud.org/privacy-policy/")
            let title = "Privacy Policy".localized
            self.viewController?.navigationController?.pushViewController(WebViewController(url:url!, title: title), animated: true)
        }, title: "Privacy Policy".localized, accessoryType: .disclosureIndicator, identifier: MorePrivacyPolicyRowIdentifier)

        return privacyPolicyRow
    }

    private func appVersionRow() -> StaticTableViewRow {
        let appVersionRow = StaticTableViewRow(rowWithAction: nil, title: "owncloud 2018 iOS beta", identifier: MoreAppVersionRowIdentifier)

        return appVersionRow
    }

    // MARK: - Update UI
    func updateUI() {

        if self.row(withIdentifier: MoreHelpRowIdentifier) == nil {
            self.add(rows: [helpRow()])
        }

        if self.row(withIdentifier: MoreSendFeedbackRowIdentifier) == nil {
            self.add(rows: [sendFeedbackRow()])
        }

        if self.row(withIdentifier: MoreRecommendRowIdentifier) == nil {
            self.add(rows: [recommendRow()])
        }

        if self.row(withIdentifier: MorePrivacyPolicyRowIdentifier) == nil {
            self.add(rows: [privacyPolicyRow()])
        }

        if self.row(withIdentifier: MoreAppVersionRowIdentifier) == nil {
            self.add(rows: [appVersionRow()])
        }

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
