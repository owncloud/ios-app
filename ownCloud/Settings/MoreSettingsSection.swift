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
import SafariServices
import ownCloudSDK

class MoreSettingsSection: SettingsSection {
	// MARK: - More Settings Cells

	private var helpRow: StaticTableViewRow?
	private var sendFeedbackRow: StaticTableViewRow?
	private var recommendRow: StaticTableViewRow?
	private var privacyPolicyRow: StaticTableViewRow?
	private var acknowledgementsRow: StaticTableViewRow?

	override init(userDefaults: UserDefaults) {
		super.init(userDefaults: userDefaults)
		self.headerTitle = "More".localized
		self.footerTitle = "\(OCAppIdentity.shared.appName!) beta version \(VendorServices.shared.appVersion) build \(VendorServices.shared.appBuildNumber) (\(VendorServices.shared.lastGitCommit))"

		self.identifier = "settings-more-section"

		createRows()
		updateUI()
	}

	// MARK: - Creation of the rows.

	private func createRows() {

		helpRow = StaticTableViewRow(rowWithAction: { (_, _) in
			let url = URL(string: "https://www.owncloud.com/help")
			self.openSFWebViewWithConfirmation(for: url!)
		}, title: "Help".localized, accessoryType: .disclosureIndicator)

		sendFeedbackRow = StaticTableViewRow(rowWithAction: { [weak self] (_, _) in
			if let viewController = self?.viewController {
				VendorServices.shared.sendFeedback(from: viewController)
			}
		}, title: "Send feedback".localized, accessoryType: .disclosureIndicator)

		recommendRow = StaticTableViewRow(rowWithAction: { [weak self] (_, _) in
			if let viewController = self?.viewController {
				VendorServices.shared.recommendToFriend(from: viewController)
			}
		}, title: "Recommend to a friend".localized, accessoryType: .disclosureIndicator)

		privacyPolicyRow = StaticTableViewRow(rowWithAction: { (_, _) in
			let url = URL(string: "https://owncloud.org/privacy-policy/")
			self.openSFWebViewWithConfirmation(for: url!)
		}, title: "Privacy Policy".localized, accessoryType: .disclosureIndicator)

		acknowledgementsRow = StaticTableViewRow(rowWithAction: { (row, _) in
			let context = OCExtensionContext(location: OCExtensionLocation(ofType: .license, identifier: nil), requirements: nil, preferences: nil)

			OCExtensionManager.shared.provideExtensions(for: context, completionHandler: { (_, context, licenses) in
				OnMainThread {
					let textViewController = TextViewController()
					let licenseText : NSMutableAttributedString = NSMutableAttributedString()

					textViewController.title = "Acknowledgements".localized

					if licenses != nil {
						for licenseExtensionMatch in licenses! {
							let extensionObject = licenseExtensionMatch.extension.provideObject(for: context)

							if let licenseDict = extensionObject as? [String : Any],
							   let licenseTitle = licenseDict["title"] as? String,
							   let licenseURL = licenseDict["url"] as? URL {
							   	// Title
								licenseText.append(NSAttributedString(string: licenseTitle + "\n", attributes: [.font : UIFont.boldSystemFont(ofSize: UIFont.systemFontSize * 1.5)]))

								// License text
								do {
									var encoding : String.Encoding = .utf8
									let licenseFileContents = try String(contentsOf: licenseURL, usedEncoding: &encoding)

									licenseText.append(NSAttributedString(string: "\n" + licenseFileContents + "\n\n", attributes: [
										.font : UIFont.systemFont(ofSize: UIFont.systemFontSize),
										.foregroundColor : UIColor.darkGray
									]))
								} catch {
								}
							}
						}
					}

					textViewController.attributedText = licenseText

					row.viewController?.navigationController?.pushViewController(textViewController, animated: true)
				}
			})
		}, title: "Acknowledgements".localized, accessoryType: .disclosureIndicator)
	}

	// MARK: - Update UI
	func updateUI() {
		add(rows: [helpRow!, sendFeedbackRow!, recommendRow!, privacyPolicyRow!, acknowledgementsRow!])
	}

	private func openSFWebViewWithConfirmation(for url: URL) {
		let alert = UIAlertController(title: "Do you want to open the following URL?".localized,
					      message: url.absoluteString,
					      preferredStyle: .alert)

		let okAction = UIAlertAction(title: "OK", style: .default) { (_) in
			self.viewController?.present(SFSafariViewController(url: url), animated: true)
		}
		let cancelAction = UIAlertAction(title: "Cancel".localized, style: .cancel)
		alert.addAction(okAction)
		alert.addAction(cancelAction)
		self.viewController?.present(alert, animated: true)
	}
}
