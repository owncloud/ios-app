//
//  PurchasesSettingsSection.swift
//  ownCloud
//
//  Created by Felix Schwarz on 14.01.20.
//  Copyright © 2020 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2020, ownCloud GmbH.
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

class PurchasesSettingsSection: SettingsSection {
	// MARK: - More Settings Cells

	private var purchasesRow: StaticTableViewRow?
	private var transactionsRow: StaticTableViewRow?

	override init(userDefaults: UserDefaults) {
		super.init(userDefaults: userDefaults)

		self.headerTitle = "In-App Purchases".localized
		self.identifier = "settings-purchases-section"

		createRows()
		updateUI()
	}

	// MARK: - Creation of the rows
	private func createRows() {
		purchasesRow = StaticTableViewRow(rowWithAction: { (row, _) in
			row.viewController?.navigationController?.pushViewController(LicenseInAppProductListViewController(), animated: true)
		}, title: "Pro Features".localized, accessoryType: .disclosureIndicator, identifier: "pro-features")

		transactionsRow = StaticTableViewRow(rowWithAction: { (row, _) in
			row.viewController?.navigationController?.pushViewController(LicenseTransactionsViewController(), animated: true)
		}, title: "Purchases".localized, accessoryType: .disclosureIndicator, identifier: "Purchases")
	}

	// MARK: - Update UI
	func updateUI() {
		var rows : [StaticTableViewRow] = []

		if let purchasesRow = purchasesRow {
			rows.append(purchasesRow)
		}

		if let transactionsRow = transactionsRow {
			rows.append(transactionsRow)
		}

		add(rows: rows)
	}
}
