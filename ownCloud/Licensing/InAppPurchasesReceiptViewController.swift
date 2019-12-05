//
//  InAppPurchasesReceiptViewController.swift
//  ownCloud
//
//  Created by Felix Schwarz on 04.12.19.
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

class InAppPurchasesReceiptViewController: StaticTableViewController {
	private var receipt : OCLicenseAppStoreReceipt?

	init(with receipt: OCLicenseAppStoreReceipt) {
		super.init(style: .grouped)

		self.receipt = receipt

		self.navigationItem.title = "Purchases".localized

		generateContent()
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	// MARK: - Parse
	func generateContent() {
		let appSection = StaticTableViewSection(headerTitle: "App".localized)

		if let originalAppVersion = receipt?.originalAppVersion {
			appSection.add(row: StaticTableViewRow(valueRowWithAction: nil, title: "Original app version".localized, value: originalAppVersion))
		}

		if appSection.rows.count > 0 {
			self.addSection(appSection)
		}

		if let iaps = receipt?.inAppPurchases {
			var line = 1

			for iap in iaps {
				let iapSection = StaticTableViewSection(headerTitle: "In-App Purchase".localized + " \(line)")

				if let productID = iap.productID {
					iapSection.add(row: StaticTableViewRow(valueRowWithAction: nil, title: "Product ID".localized, value: productID))
				}

				if let quantity = iap.quantity {
					iapSection.add(row: StaticTableViewRow(valueRowWithAction: nil, title: "Quantity".localized, value: quantity.stringValue))
				}

				if let purchaseDate = iap.originalPurchaseDate ?? iap.purchaseDate {
					iapSection.add(row: StaticTableViewRow(valueRowWithAction: nil, title: "Purchase Date".localized, value: purchaseDate.description))
				}

				if let expirationDate = iap.subscriptionExpirationDate {
					iapSection.add(row: StaticTableViewRow(valueRowWithAction: nil, title: "Expiration Date".localized, value: expirationDate.description))
				}

				if let cancellationDate = iap.cancellationDate {
					iapSection.add(row: StaticTableViewRow(valueRowWithAction: nil, title: "Cancellation Date".localized, value: cancellationDate.description))
				}

				self.addSection(iapSection)

				line += 1
			}
		}
	}
}
