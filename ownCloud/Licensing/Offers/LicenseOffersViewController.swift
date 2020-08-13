//
//  LicenseOffersViewController.swift
//  ownCloud
//
//  Created by Felix Schwarz on 30.11.19.
//  Copyright © 2019 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2019, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import UIKit
import ownCloudApp
import ownCloudAppShared

class LicenseOffersViewController: StaticTableViewController {
	var featureIdentifier: OCLicenseFeatureIdentifier
	var environment: OCLicenseEnvironment

	init(withFeature featureIdentifier: OCLicenseFeatureIdentifier, in environment: OCLicenseEnvironment) {
		self.featureIdentifier = featureIdentifier
		self.environment = environment

		super.init(style: .grouped)

		setupHeaderView()
		composeSections()

		OCLicenseManager.shared.observeProducts(nil, features: [featureIdentifier], in: environment, withOwner: self, updateHandler: { (observer, _, authStatus) in
			if authStatus == .granted {
				OnMainThread(after: 1.5) {
					(observer.owner as? LicenseOffersViewController)?.dismissAnimated()
				}
			}
		})
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	var cardHeaderView : UIView?

	func setupHeaderView() {
		let headerView = UIView()
		let titleView = UILabel()
		let fontSize : CGFloat = 22

		let headerText = NSMutableAttributedString(string: "Pro Features".localized, attributes: [
			.font : UIFont.systemFont(ofSize: fontSize, weight: .light)
		])

		headerText.addAttribute(.font, value: UIFont.systemFont(ofSize: fontSize, weight: .semibold), range: (headerText.string as NSString).range(of: "Pro"))

		titleView.translatesAutoresizingMaskIntoConstraints = false
		titleView.attributedText = headerText

		titleView.applyThemeCollection(Theme.shared.activeCollection)

		headerView.addSubview(titleView)

		NSLayoutConstraint.activate([
			titleView.leftAnchor.constraint(equalTo: headerView.leftAnchor, constant: 15),
			titleView.rightAnchor.constraint(equalTo: headerView.rightAnchor, constant: -15),
			titleView.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 10),
			titleView.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -10)
		])

		self.cardHeaderView = headerView
	}

	func composeSections() {
		let iapSection = StaticTableViewSection(headerTitle: "Purchase")
		let subSection = StaticTableViewSection(headerTitle: "Subscribe")

		if let feature = OCLicenseManager.shared.feature(withIdentifier: featureIdentifier) {
			if let offers = OCLicenseManager.shared.offers(for: feature) {
				for offer in offers {

					let offerRow = StaticTableViewRow(customView: LicenseOfferView(with: offer, focusedOn: feature, in: environment, baseViewController: self), inset: UIEdgeInsets(top: 15, left: 18, bottom: 15, right: 18))

					switch offer.type {
						case .subscription:
							subSection.add(row: offerRow)

						case .purchase:
							iapSection.add(row: offerRow)

						default: break
					}
				}
			}
		}

		// (Re)build sections
		var sections : [StaticTableViewSection] = []

		if let iapMessages = OCLicenseManager.shared.inAppPurchaseMessage(forFeature: featureIdentifier) {
			let messageRow = StaticTableViewRow(message: iapMessages, icon: UIImage(named: "info-icon")?.scaledImageFitting(in: CGSize(width: 24, height: 24)), style: .warning, identifier: "iap-messages")

			sections.append(StaticTableViewSection(headerTitle: nil, rows: [ messageRow ]))
		}

		if iapSection.rows.count > 0 {
			sections.append(iapSection)
		}

		if subSection.rows.count > 0 {
			sections.append(subSection)
		}

		let restoreSection = StaticTableViewSection()

		restoreSection.add(row: StaticTableViewRow(rowWithAction: { (_, _) in
			OCLicenseManager.shared.restorePurchases(on: self, with: { (_) in
				self.composeSections()
			})
		}, title: "Restore purchases".localized, alignment: .center))

		sections.append(restoreSection)

		// Set sections
		self.sections = sections
	}

	override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		if sections[section].headerTitle != nil {
			return 40
		}

		return 20
	}

	override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
		if sections[section].footerTitle != nil {
			return super.tableView(tableView, heightForFooterInSection: section)
		}

		return .leastNormalMagnitude
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		self.tableView.sectionFooterHeight = .leastNormalMagnitude
		self.tableView.contentInsetAdjustmentBehavior = .never
	}
}
