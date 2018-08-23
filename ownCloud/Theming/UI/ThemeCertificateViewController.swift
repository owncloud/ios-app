//
//  ThemeCertificateViewController.swift
//  ownCloud
//
//  Created by Felix Schwarz on 23.08.18.
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

import UIKit
import ownCloudUI

class ThemeCertificateViewController: OCCertificateViewController, Themeable {
	override func viewDidLoad() {
		super.viewDidLoad()

		Theme.shared.register(client: self, applyImmediately: true)
	}

	deinit {
		Theme.shared.unregister(client: self)
	}

	func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		self.tableView.backgroundColor = collection.tableGroupBackgroundColor
		self.tableView.separatorColor = collection.tableSeparatorColor

		self.sectionHeaderTextColor = collection.tableRowColors.secondaryLabelColor

		self.lineTitleColor = collection.tableRowColors.secondaryLabelColor
		self.lineValueColor = collection.tableRowColors.labelColor
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell : UITableViewCell = super.tableView(tableView, cellForRowAt: indexPath)

		cell.backgroundColor = Theme.shared.activeCollection.tableRowColors.backgroundColor

		return cell
	}
}
