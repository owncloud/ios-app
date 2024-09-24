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
import ownCloudSDK
import ownCloudApp
import ownCloudAppShared

class MoreSettingsSection: SettingsSection {
	// MARK: - More Settings Cells

	private var documentationRow: StaticTableViewRow?
	private var helpRow: StaticTableViewRow?
	private var sendFeedbackRow: StaticTableViewRow?
	private var helpAndSupportRow: StaticTableViewRow?
	private var recommendRow: StaticTableViewRow?
	private var privacyPolicyRow: StaticTableViewRow?
	private var termsOfUseRow: StaticTableViewRow?
	private var acknowledgementsRow: StaticTableViewRow?
	private var appVersionRow: StaticTableViewRow?

	override init(userDefaults: UserDefaults) {
		super.init(userDefaults: userDefaults)
		self.headerTitle = OCLocalizedString("More", nil)

		self.identifier = "settings-more-section"

		createRows()
		updateUI()
	}

	// MARK: - Creation of the rows.

	private func createRows() {

		documentationRow = StaticTableViewRow(rowWithAction: { [weak self] (_, _) in
			if let url = VendorServices.shared.documentationURL, let viewController = self?.viewController {
				VendorServices.shared.openSFWebView(on: viewController, for: url)
			}
		}, title: OCLocalizedString("Documentation", nil), accessoryType: .disclosureIndicator, identifier: "documentation")

		if let helpURL = VendorServices.shared.helpURL {
			helpRow = StaticTableViewRow(rowWithAction: { [weak self] (_, _) in
				if let viewController = self?.viewController {
					VendorServices.shared.openSFWebView(on: viewController, for: helpURL)
				}
			}, title: OCLocalizedString("Help", nil), accessoryType: .disclosureIndicator, identifier: "help")
		}

		sendFeedbackRow = StaticTableViewRow(rowWithAction: { [weak self] (_, _) in
			if let viewController = self?.viewController {
				VendorServices.shared.sendFeedback(from: viewController)
			}
		}, title: OCLocalizedString("Send feedback", nil), accessoryType: .disclosureIndicator, identifier: "send-feedback")

		helpAndSupportRow = StaticTableViewRow(rowWithAction: { [weak self] (_, _) in
			if let viewController = self?.viewController {
				VendorServices.shared.showHelpAndSupportOptions(from: viewController)
			}
		}, title: OCLocalizedString("Help & Contact", nil), accessoryType: .disclosureIndicator, identifier: "help-and-contact")

		recommendRow = StaticTableViewRow(rowWithAction: { [weak self] (_, _) in
			if let viewController = self?.viewController {
				VendorServices.shared.recommendToFriend(from: viewController)
			}
		}, title: OCLocalizedString("Recommend to a friend", nil), accessoryType: .disclosureIndicator, identifier: "recommend-friend")

		if let privacyURL = VendorServices.shared.privacyURL {
			privacyPolicyRow = StaticTableViewRow(rowWithAction: { [weak self] (_, _) in
				if let viewController = self?.viewController {
					VendorServices.shared.openSFWebView(on: viewController, for: privacyURL)
				}
			}, title: OCLocalizedString("Privacy Policy", nil), accessoryType: .disclosureIndicator, identifier: "privacy-policy")
		}

		if let termsOfUseURL = VendorServices.shared.termsOfUseURL {
			termsOfUseRow = StaticTableViewRow(rowWithAction: { [weak self] (_, _) in
				if let viewController = self?.viewController {
					VendorServices.shared.openSFWebView(on: viewController, for: termsOfUseURL)
				}
			}, title: OCLocalizedString("Terms Of Use", nil), accessoryType: .disclosureIndicator, identifier: "terms-of-use")
		}

		acknowledgementsRow = StaticTableViewRow(rowWithAction: { (row, _) in
			row.viewController?.navigationController?.pushViewController(AcknowledgementsTableViewController(style: .insetGrouped), animated: true)
		}, title: OCLocalizedString("Acknowledgements", nil), accessoryType: .disclosureIndicator, identifier: "acknowledgements")

		var buildType = OCLocalizedString("release", nil)
		if VendorServices.shared.isBetaBuild {
			buildType = OCLocalizedString("beta", nil)
		}

		var appSuffix = ""
		if OCLicenseEMMProvider.isEMMVersion {
			appSuffix = "-EMM"
		}

		let localizedFooter = OCLocalizedString("%@%@ %@ version %@ build %@\n(app: %@, sdk: %@)", nil)
		let footerTitle = String(format: localizedFooter, VendorServices.shared.appName, appSuffix, buildType, VendorServices.shared.appVersion, "\(VendorServices.shared.appBuildNumber) (\(GitInfo.app.buildDate ?? ""))", GitInfo.app.versionInfo, GitInfo.sdk.versionInfo)

		appVersionRow = StaticTableViewRow(rowWithAction: { (_, _) in
			UIPasteboard.general.string = footerTitle
			guard let viewController = self.viewController else { return }
			_ = NotificationHUDViewController(on: viewController, title: OCLocalizedString("App Version", nil), subtitle: OCLocalizedString("Version information were copied to the clipboard", nil), completion: nil)
		}, title: OCLocalizedString("App Version", nil), subtitle: footerTitle, identifier: "app-version")
	}

	// MARK: - Update UI
	func updateUI() {
		var rows : [StaticTableViewRow] = []

		if Branding.shared.isBranded {
			if VendorServices.shared.documentationURL != nil {
				rows.append(documentationRow!)
			}

			if VendorServices.shared.helpURL != nil {
				rows.append(helpRow!)
			}

			if VendorServices.shared.feedbackMail != nil || Branding.shared.feedbackURL != nil {
				rows.append(sendFeedbackRow!)
			}
		} else {
			if VendorServices.shared.documentationURL != nil || (VendorServices.shared.feedbackMail != nil || Branding.shared.feedbackURL != nil) {
				rows.append(helpAndSupportRow!)
			}
		}

		if let recommendToFriend = VendorServices.classSetting(forOCClassSettingsKey: .recommendToFriendEnabled) as? Bool, recommendToFriend {
			rows.append(recommendRow!)
		}

		if let privacyPolicyRow = privacyPolicyRow {
			rows.append(privacyPolicyRow)
		}
		if let termsOfUseRow = termsOfUseRow {
			rows.append(termsOfUseRow)
		}

		rows.append(contentsOf: [acknowledgementsRow!, appVersionRow!])

		add(rows: rows)
	}
}
