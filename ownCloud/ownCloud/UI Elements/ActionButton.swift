//
//  ActionButton.swift
//  ownCloud
//
//  Created by Felix Schwarz on 08.03.18.
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

@IBDesignable
class ActionButton: UIButton {
	override var intrinsicContentSize: CGSize {
		var intrinsicContentSize = super.intrinsicContentSize

		intrinsicContentSize.width += 30
		intrinsicContentSize.height += 10

		return (intrinsicContentSize)
	}

	private func styleButton() {
		self.layer.cornerRadius = 5

		self.setAttributedTitle(NSAttributedString.init(string: self.title(for: UIControlState.normal)!,
								attributes: [
									NSAttributedStringKey.font : UIFont.systemFont(ofSize: 16, weight: UIFont.Weight.semibold)
									// NSAttributedStringKey.foregroundColor : self.titleColor(for: UIControlState.normal) as Any
								]),
					for: UIControlState.normal)

		/*
			TODO:
			- change text and background color when pressing button
			- derive colors from theme object (TBD)
		*/
	}

	override init(frame: CGRect) {
		super.init(frame: frame)
		styleButton()
	}

	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		styleButton()
	}

	override func prepareForInterfaceBuilder() {
		super.prepareForInterfaceBuilder()
		styleButton()
	}
}
