//
//  RoundedInfoView.swift
//  ownCloud
//
//  Created by Matthias Hühne on 19.03.19.
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
import ownCloudAppShared

class RoundedInfoView: UIView, Themeable {

	// MARK: - Constants
	let cornerRadius : CGFloat = 10.0
	let borderWidth : CGFloat = 1.0
	let horizontalPadding : CGFloat = 10.0
	let verticalPadding : CGFloat = 20.0
	let verticalLabelPadding : CGFloat = 10.0
	let font : UIFont = UIFont.systemFont(ofSize: 14)

	// MARK: - Instance Variables
	var infoText : String = ""
	var messageThemeApplierToken : ThemeApplierToken?
	var backgroundView = UIView()
	var label = UILabel()

	init(text: String) {
		super.init(frame: CGRect.zero)
		infoText = text
		Theme.shared.register(client: self, applyImmediately: true)
		setupView()
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	deinit {
		Theme.shared.unregister(client: self)

		if messageThemeApplierToken != nil {
			Theme.shared.remove(applierForToken: messageThemeApplierToken)
			messageThemeApplierToken = nil
		}
	}

	private func setupView() {
		backgroundView.layer.cornerRadius = cornerRadius
		backgroundView.layer.borderWidth = borderWidth
		backgroundView.translatesAutoresizingMaskIntoConstraints = false
		self.addSubview(backgroundView)

		label.textAlignment = .center
		label.font = font
		label.numberOfLines = 0
		label.text = infoText
		label.translatesAutoresizingMaskIntoConstraints = false
		self.addSubview(label)

		NSLayoutConstraint.activate([
			backgroundView.leftAnchor.constraint(equalTo: self.safeAreaLayoutGuide.leftAnchor, constant: horizontalPadding),
			backgroundView.rightAnchor.constraint(equalTo: self.safeAreaLayoutGuide.rightAnchor, constant: -horizontalPadding),
			backgroundView.topAnchor.constraint(equalTo: self.topAnchor, constant: verticalPadding),
			backgroundView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: 0),
			backgroundView.widthAnchor.constraint(greaterThanOrEqualToConstant: 0),

			label.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor, constant: horizontalPadding),
			label.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor, constant: -horizontalPadding),
			label.topAnchor.constraint(equalTo: backgroundView.topAnchor, constant: verticalLabelPadding),
			label.bottomAnchor.constraint(equalTo: backgroundView.bottomAnchor, constant: -verticalLabelPadding),
			label.widthAnchor.constraint(greaterThanOrEqualToConstant: 0),
			label.heightAnchor.constraint(greaterThanOrEqualToConstant: 0)
			])
	}

	// MARK: - Theme support

	func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		backgroundView.backgroundColor = Theme.shared.activeCollection.tableRowColors.backgroundColor
		backgroundView.layer.borderColor = Theme.shared.activeCollection.tableRowBorderColor?.cgColor
		label.textColor = Theme.shared.activeCollection.tableRowColors.labelColor
	}

}
