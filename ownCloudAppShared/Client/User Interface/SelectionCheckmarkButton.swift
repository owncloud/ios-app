//
//  SelectionCheckmarkButton.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 12.04.23.
//  Copyright © 2023 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2023, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import UIKit

class SelectionCheckmarkView: UIImageView, Themeable {
	private var _themeRegistered = false
	public override func didMoveToWindow() {
		super.didMoveToWindow()

		if window != nil, !_themeRegistered {
			_themeRegistered = true

			cssSelector = .selectionCheckmark
			Theme.shared.register(client: self)
		}
	}

	func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		updateImage()
	}

	var isSelected: Bool = false {
		didSet {
			updateImage()
		}
	}

	func updateImage() {
		var name: String
		var colors: [UIColor]

		let fillColor = getThemeCSSColor(.fill, state: isSelected ? [.selected] : nil) ?? .systemBlue
		let strokeColor = getThemeCSSColor(.stroke, state: isSelected ? [.selected] : nil) ?? .white

		colors = [strokeColor, fillColor]

		if isSelected {
			name = "checkmark.circle.fill"
		} else {
			name = "circle.fill"
		}

		let symbolConfig = UIImage.SymbolConfiguration(paletteColors: colors)
		let symbolImage = UIImage(systemName: name, withConfiguration: symbolConfig)

		let shadowColor = isSelected ? strokeColor : fillColor

		layer.shadowColor = shadowColor.cgColor
		layer.shadowOpacity = 1.0
		layer.shadowOffset = .zero
		layer.shadowRadius = 2

		image = symbolImage
	}
}

extension ThemeCSSSelector {
	static let selectionCheckmark = ThemeCSSSelector(rawValue: "selectionCheckmark")
}
