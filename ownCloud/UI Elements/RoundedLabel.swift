//
//  RoundedLabel.swift
//  ownCloud
//
//  Created by Matthias Hühne on 13.05.19.
//  Copyright © 2019 ownCloud GmbH. All rights reserved.
//

/*
* Copyright (C) 2019, ownCloud GmbH.
*
* This code is covered by the GNU Public License Version 3.
*
* For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
* You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
*
*/

import UIKit

class RoundedLabel: UIView {

	struct Style {
		var textColor : UIColor
		var backgroundColor : UIColor

		var horizontalPadding : CGFloat
		var verticalPadding : CGFloat
		var cornerRadius : CGFloat

		static var token = Style(textColor: .white, backgroundColor: .red, horizontalPadding: 5, verticalPadding: 2, cornerRadius: 5)
		static var round = Style(textColor: .white, backgroundColor: .red, horizontalPadding: 10, verticalPadding: 5, cornerRadius: -1)
	}

	// MARK: - Constants
	private var horizontalPadding : CGFloat = 10.0
	private var verticalPadding : CGFloat = 5.0
	private var cornerRadius : CGFloat = 5.0

	// MARK: - Instance Variables
	private var label = UILabel()
	private var font : UIFont = UIFont.boldSystemFont(ofSize: 14)
	public var labelText : String = "" {
		didSet {
			label.text = labelText
		}
	}
	public var labelBackgroundColor : UIColor = UIColor.black {
		didSet {
			self.backgroundColor = labelBackgroundColor
		}
	}
	public var textColor : UIColor = UIColor.white {
		didSet {
			label.textColor = textColor
		}
	}

	// MARK: - Init & Deinit

	init() {
		super.init(frame: CGRect.zero)
		styleView()
	}

	init(text: String = "", style: Style = .token) {
		super.init(frame: CGRect.zero)

		labelText = text
		textColor = style.textColor
		labelBackgroundColor = style.backgroundColor

		horizontalPadding = style.horizontalPadding
		verticalPadding = style.verticalPadding
		cornerRadius = style.cornerRadius

		styleView()
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	// MARK: - Prepare and Update View

	private func styleView() {
		label.translatesAutoresizingMaskIntoConstraints = false

		label.textAlignment = .center
		label.font = font
		label.numberOfLines = 1
		label.text = labelText
		label.textColor = textColor

		label.setContentCompressionResistancePriority(.required, for: .vertical)
		label.setContentCompressionResistancePriority(.required, for: .horizontal)
		label.setContentHuggingPriority(.required, for: .vertical)
		label.setContentHuggingPriority(.required, for: .horizontal)

		self.addSubview(label)

		if cornerRadius == -1 {
			// Compute corner radius dynamically
			var temporaryText : Bool = false
			if label.text?.count == 0 {
				temporaryText = true
				label.text = "1234"
				label.layoutIfNeeded()
			}
			cornerRadius = (label.systemLayoutSizeFitting(CGSize(width: 240, height: 240), withHorizontalFittingPriority: .defaultHigh, verticalFittingPriority: .defaultHigh).height / 2.0) + verticalPadding
			if temporaryText {
				label.text = ""
			}
		}

		self.layer.cornerRadius = cornerRadius
		self.backgroundColor = labelBackgroundColor

		NSLayoutConstraint.activate([
			label.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: horizontalPadding),
			label.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -horizontalPadding),
			label.topAnchor.constraint(equalTo: self.topAnchor, constant: verticalPadding),
			label.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -verticalPadding)
		])
	}
}
