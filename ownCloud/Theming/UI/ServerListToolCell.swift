//
//  ThemeTableViewCell.swift
//  ownCloud
//
//  Created by Felix Schwarz on 16.04.18.
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

class ServerListToolCell: ThemeTableViewCell {

	override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func applyThemeCollectionToCellContents(theme: Theme, collection: ThemeCollection) {
		let state = ThemeItemState(selected: self.isSelected)

		self.textLabel?.applyThemeCollection(collection, itemStyle: .defaultForItem, itemState: state)

		self.textLabel?.textColor = collection.tableRowColors.secondaryLabelColor
		self.imageView?.tintColor = collection.tableRowColors.secondaryLabelColor
	}

	override func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		self.applyThemeCollection(Theme.shared.activeCollection)

		self.applyThemeCollectionToCellContents(theme: theme, collection: collection)
	}
}
