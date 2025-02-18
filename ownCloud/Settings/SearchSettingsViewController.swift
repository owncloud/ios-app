//
//  SearchSettingsViewController.swift
//  ownCloud
//
//  Created by Felix Schwarz on 29.11.24.
//  Copyright © 2024 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2024, ownCloud GmbH.
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

class SearchSettingsViewController: StaticTableViewController {

	private var defaultScopeSection : StaticTableViewSection?

	private func addDefaultScopeSection() {
		var scopeRows: [StaticTableViewRow] = []
		let defaultScopeIdentifier = SearchScope.defaultSearchScopeIdentifier

		for descriptor in SearchScopeDescriptor.all {
			scopeRows.append(StaticTableViewRow(radioItemWithAction: { staticRow, sender in
				SearchScope.defaultSearchScopeIdentifier = descriptor.identifier
			}, groupIdentifier: "scope", value: descriptor.identifier, icon: descriptor.icon, title: descriptor.localizedName, subtitle: descriptor.localizedDescription, selected: descriptor.identifier == defaultScopeIdentifier))
		}

		defaultScopeSection = StaticTableViewSection(headerTitle: OCLocalizedString("Default search scope", nil), footerTitle: "", identifier: "default-search-scope", rows: scopeRows)
		addSection(defaultScopeSection!)
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		navigationItem.title = OCLocalizedString("Search Settings", nil)
		addDefaultScopeSection()
	}
}
