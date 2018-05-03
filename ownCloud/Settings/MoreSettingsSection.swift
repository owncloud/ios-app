//
//  MoreSettingsSection.swift
//  ownCloud
//
//  Created by Pablo Carrascal on 03/05/2018.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//
import UIKit
import WebKit

// MARK: - Section identifier
private let MoreSectionIdentifier: String = "settings-more-section"

// MARK: - Row identifiers
private let MoreHelpRowIdentifier: String = "more-help-row"
private let MoreSendFeedbackRowIdentifier: String = "more-feedback-row"
private let MoreRecommendRowIdentifier: String = "more-recommend-row"
private let MorePrivacyPolicyRowIdentifier: String = "more-privacy-policy-row"
private let MoreAppVersionRowIdentifier: String = "more-app-version-row"

class MoreSettingsSection: StaticTableViewSection {

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
            // TODO: Open mail to apps@owncloud.com
        }, title: "Send feedback".localized, accessoryType: .disclosureIndicator, identifier: MoreSendFeedbackRowIdentifier)

        return sendFeedbackRow
    }

    private func recommendRow() -> StaticTableViewRow {
        let recommendRow = StaticTableViewRow(rowWithAction: { (_, _) in
            // TODO: decide what to do
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
}
