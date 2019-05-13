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

	// MARK: - Constants
	private let cornerRadius : CGFloat = 5.0
	private let borderWidth : CGFloat = 1.0
	private let horizontalPadding : CGFloat = 10.0
	private let verticalPadding : CGFloat = 20.0
	private let verticalLabelPadding : CGFloat = 5.0

	// MARK: - Instance Variables
	private var label = UILabel()
	private var font : UIFont = UIFont.boldSystemFont(ofSize: 14)
	public var labelText : String = "" {
		didSet {
			label.text = labelText
		}
	}
	public var mainColor : UIColor = UIColor.black {
		didSet {
			self.backgroundColor = mainColor
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

	init(text: String, textColor: UIColor, backgroundColor: UIColor) {
		super.init(frame: CGRect.zero)
		labelText = text
		self.textColor = textColor
		mainColor = backgroundColor
		styleView()
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	// MARK: - Prepare and Update View

	private func styleView() {
		self.layer.cornerRadius = cornerRadius
		self.backgroundColor = mainColor

		label.textAlignment = .center
		label.font = font
		label.numberOfLines = 1
		label.text = labelText
		label.translatesAutoresizingMaskIntoConstraints = false
		label.textColor = mainColor
		self.addSubview(label)

		NSLayoutConstraint.activate([
			label.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: horizontalPadding),
			label.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -horizontalPadding),
			label.topAnchor.constraint(equalTo: self.topAnchor),
			label.bottomAnchor.constraint(equalTo: self.bottomAnchor),
			label.widthAnchor.constraint(greaterThanOrEqualToConstant: 0),
			label.heightAnchor.constraint(greaterThanOrEqualToConstant: 0)
			])
	}

	public func update(text: String, textColor: UIColor, backgroundColor: UIColor) {
		labelText = text
		mainColor = backgroundColor
		self.textColor = textColor
	}

}
