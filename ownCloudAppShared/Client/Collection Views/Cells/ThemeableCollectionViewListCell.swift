//
//  ThemeableCollectionViewListCell.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 27.05.22.
//  Copyright © 2022 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2022, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import UIKit

open class ThemeableCollectionViewListCell: UICollectionViewListCell, Themeable {
	private var themeRegistered : Bool = false
	public var updateColors : Bool = true

	override init(frame: CGRect) {
		super.init(frame: frame)
	}

	required public init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}

	deinit {
		if themeRegistered {
			Theme.shared.unregister(client: self)
		}
	}

	open override func didMoveToWindow() {
		super.didMoveToWindow()

		if !themeRegistered, window != nil {
			// Postpone registration with theme until we actually need to. Makes sure self.applyThemeCollection() can take all properties into account
			automaticallyUpdatesBackgroundConfiguration = false
			automaticallyUpdatesContentConfiguration = false
			Theme.shared.register(client: self, applyImmediately: true)
			themeRegistered = true
		}
	}

	public var configuredConstraints : [NSLayoutConstraint]? {
		willSet {
			if let configuredConstraints = configuredConstraints {
				NSLayoutConstraint.deactivate(configuredConstraints)
			}
		}
		didSet {
			if let configuredConstraints = configuredConstraints {
				NSLayoutConstraint.activate(configuredConstraints)
			}
		}
	}

	open override func updateConfiguration(using state: UICellConfigurationState) {
		super.updateConfiguration(using: state)
		self.applyThemeCollection(Theme.shared.activeCollection, cellState: state)
	}

	open func applyThemeCollectionToCellContents(theme: Theme, collection: ThemeCollection, state: ThemeItemState) {
	}

	open func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		self.applyThemeCollection(collection, cellState: configurationState)

		self.applyThemeCollectionToCellContents(theme: theme, collection: collection, state: ThemeItemState(selected: self.isSelected))
	}

	var hostingCollectionView: UICollectionView? {
		var superView: UIView? = self.superview

		while superView != nil && !(superView is UICollectionView) {
			superView = superView?.superview
		}

		return superView as? UICollectionView
	}
}
