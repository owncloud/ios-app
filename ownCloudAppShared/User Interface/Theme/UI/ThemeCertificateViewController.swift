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

public class ThemeCertificateViewController: OCCertificateViewController, Themeable {
	override public func viewDidLoad() {
		super.viewDidLoad()

		Theme.shared.register(client: self, applyImmediately: true)
	}

	deinit {
		Theme.shared.unregister(client: self)
	}

	var cellBackgroundColor: UIColor?

	public func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		tableView.backgroundColor = collection.css.getColor(.fill, selectors: [.grouped], for:tableView)
		tableView.separatorColor = collection.css.getColor(.fill, selectors: [.separator], for:tableView)

		self.sectionHeaderTextColor = collection.css.getColor(.stroke, selectors: [.cell, .sectionHeader], for:tableView) ?? .secondaryLabel

		self.lineTitleColor = collection.css.getColor(.stroke, selectors: [.label, .secondary], for:tableView) ?? .secondaryLabel
		self.lineValueColor = collection.css.getColor(.stroke, selectors: [.label, .primary], for:tableView) ?? .label

		cellBackgroundColor = collection.css.getColor(.fill, selectors: [.grouped, .table, .cell], for:nil)
	}

	override public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell : UITableViewCell = super.tableView(tableView, cellForRowAt: indexPath)

		cell.backgroundColor = cellBackgroundColor

		return cell
	}
}
