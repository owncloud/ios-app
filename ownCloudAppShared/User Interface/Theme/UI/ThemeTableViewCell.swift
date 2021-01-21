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

open class ThemeTableViewCell: UITableViewCell, Themeable {
	private var themeRegistered = false

	var updateLabelColors : Bool = true

	override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
		if style == .default {
			// This is a workaround, because some cells with style .default does not support automatically Right-to-Left UI support. When switching to style .subtitle, the style will be kept, if no subtitle was set ant the RtL support will work on this cells
			super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
		} else {
			super.init(style: style, reuseIdentifier: reuseIdentifier)
		}
	}

	convenience public init(withLabelColorUpdates labelColorUpdates: Bool, style: UITableViewCell.CellStyle = .default, reuseIdentifier: String? = nil) {
		self.init(style: style, reuseIdentifier: reuseIdentifier)

		updateLabelColors = labelColorUpdates
	}

	required public init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	deinit {
		if themeRegistered {
			Theme.shared.unregister(client: self)
		}
	}

	open override func willMove(toSuperview newSuperview: UIView?) {
		super.willMove(toSuperview: newSuperview)

		if !themeRegistered {
			// Postpone registration with theme until we actually need to. Makes sure self.applyThemeCollection() can take all properties into account
			Theme.shared.register(client: self, applyImmediately: true)
			themeRegistered = true
		}
	}

	open func applyThemeCollectionToCellContents(theme: Theme, collection: ThemeCollection) {
		let state = ThemeItemState(selected: self.isSelected)

		if updateLabelColors {
			self.textLabel?.applyThemeCollection(collection, itemStyle: .defaultForItem, itemState: state)
			self.detailTextLabel?.applyThemeCollection(collection, itemStyle: .message, itemState: state)
		}
	}

	open func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		self.applyThemeCollection(Theme.shared.activeCollection)

		self.applyThemeCollectionToCellContents(theme: theme, collection: collection)
	}

	open override func setSelected(_ selected: Bool, animated: Bool) {
		super.setSelected(selected, animated: animated)

		if self.selectionStyle != .none {
			self.applyThemeCollectionToCellContents(theme: Theme.shared, collection: Theme.shared.activeCollection)
		}
	}
}
