//
//  CellularSettingsViewController.swift
//  ownCloud
//
//  Created by Felix Schwarz on 20.05.20.
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
import ownCloudSDK
import ownCloudAppShared

class CellularSettingsViewController: StaticTableViewController {
	var changeHandler : (() -> Void)?

	private func updateCellularDataFooter() {
		var footerTitle = "Some cellular data may still be used. To completely avoid the usage of cellular data, please turn off access to cellular for the entire app in the Settings app.".localized

		if let mainSwitchAllowed = OCCellularManager.shared.switch(withIdentifier: .main)?.allowed, mainSwitchAllowed {
			footerTitle = ""
		}

		if let section = self.sectionForIdentifier("main-section") {
			if footerTitle != section.footerTitle {
				section.footerTitle = footerTitle
				tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
			}
		}
	}

	private func buildRow(for identifier: OCCellularSwitchIdentifier) -> StaticTableViewRow? {
		var row : StaticTableViewRow?

		if let cellularSwitch = OCCellularManager.shared.switch(withIdentifier: identifier), let title = cellularSwitch.localizedName {
			row = StaticTableViewRow(switchWithAction: { [weak self] (row, _) in
				if let allow = row.value as? Bool {
					OCCellularManager.shared.switch(withIdentifier: identifier)?.allowed = allow
				}

				if identifier == .main {
					self?.updateCellularDataFooter()
					self?.updateSwitchesVisibility()
				}

				self?.changeHandler?()
			}, title: title, value: cellularSwitch.allowed, identifier: cellularSwitch.identifier.rawValue)
		}

		return row
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		navigationItem.title = "Cellular transfers".localized

		if OCConnection.allowCellular {
			let mainSection = StaticTableViewSection(headerTitle: "General".localized, footerTitle: "".localized, identifier: "main-section", rows: [
				buildRow(for: .main)!
			])

			addSection(mainSection)

			updateCellularDataFooter()

			switchesSection = StaticTableViewSection(headerTitle: "By feature".localized, identifier: "options-section")

			for cellularSwitch in OCCellularManager.shared.switches {
				if cellularSwitch.identifier != .main, cellularSwitch.localizedName != nil, let switchRow = buildRow(for: cellularSwitch.identifier) {
					switchesSection?.add(row: switchRow)
				}
			}

			updateSwitchesVisibility(animated: false)
		} else {
			let cellularDisabledSection = StaticTableViewSection(headerTitle: "General".localized, identifier: "cellular-disabled-section", rows: [
				StaticTableViewRow(label: "Cellular transfers have been disabled via MDM configuration. Please contact your administrator for more information.".localized)
			])

			addSection(cellularDisabledSection)
		}
	}

	private var switchesSection : StaticTableViewSection?

	private func updateSwitchesVisibility(animated: Bool = true) {
		if OCCellularManager.shared.switch(withIdentifier: .main)?.allowed == true {
			if switchesSection?.attached == false, let switchesSection = switchesSection {
				addSection(switchesSection, animated: animated)
			}
		} else {
			if switchesSection?.attached == true, let switchesSection = switchesSection {
				removeSection(switchesSection, animated: animated)
			}
		}
	}
}
