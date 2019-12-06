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

class LicenseOffersViewController: StaticTableViewController {
	init(withFeature featureIdentifier: OCLicenseFeatureIdentifier, in environment: OCLicenseEnvironment) {
		super.init(style: .grouped)

		let offerSection = StaticTableViewSection(headerTitle: "Offers")

		if let feature = OCLicenseManager.shared.feature(withIdentifier: featureIdentifier) {
			if let offers = OCLicenseManager.shared.offers(for: feature) {
				for offer in offers {
					let offerType = OCLicenseProduct.string(for: offer.type)
					let product = OCLicenseManager.shared.product(withIdentifier: offer.productIdentifier)
					let offerRow = StaticTableViewRow(subtitleRowWithAction: { (_, _) in
						offer.commit(options: nil)
					}, title: "\(product?.localizedName ?? "-") [\(offerType)]", subtitle: offer.localizedPriceTag + " – " + (product?.localizedDescription ?? ""), accessoryType: UITableViewCell.AccessoryType.disclosureIndicator, identifier: offer.identifier)

					offerSection.add(row: offerRow)
				}
			}
		}

		self.addSection(offerSection)

		OCLicenseManager.shared.observeProducts(nil, features: [featureIdentifier], in: environment, withOwner: self, updateHandler: { (observer, initial, authStatus) in
			if authStatus == .granted {
				(observer.owner as? LicenseOffersViewController)?.dismissAnimated()
			}
		})
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
