//
//  ServerListToolCell.swift
//  ownCloud
//
//  Created by Matthias Hühne on 03.03.20.
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
import ownCloudAppShared

class ServerListToolCell: ThemeTableViewCell {
	override func applyThemeCollectionToCellContents(theme: Theme, collection: ThemeCollection) {
		let state = ThemeItemState(selected: self.isSelected)

		self.textLabel?.applyThemeCollection(collection, itemStyle: .defaultForItem, itemState: state)

		self.textLabel?.textColor = collection.tableRowColors.secondaryLabelColor
		self.imageView?.tintColor = collection.tableRowColors.secondaryLabelColor
	}
}
