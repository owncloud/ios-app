//
//  BottomButtonBar.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 20.04.23.
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

open class BottomButtonBar: ThemeCSSView {
	open var selectButton: UIButton = UIButton()
	open var cancelButton: UIButton = UIButton()
	open var promptLabel: UILabel = ThemeCSSLabel(withSelectors: [.label])
	open var bottomSeparatorLine: UIView = ThemeCSSView(withSelectors: [.separator])

	open var selectButtonTitle: String {
		didSet {
			var buttonConfiguration = selectButton.configuration
			if buttonConfiguration != nil {
				buttonConfiguration?.title = selectButtonTitle
				selectButton.configuration = buttonConfiguration
			}
		}
	}
	open var cancelButtonTitle: String? {
		didSet {
			var buttonConfiguration = cancelButton.configuration
			if buttonConfiguration != nil {
				buttonConfiguration?.title = cancelButtonTitle
				cancelButton.configuration = buttonConfiguration
			}
		}
	}

	public init(prompt: String? = nil, selectButtonTitle: String, cancelButtonTitle: String? = "Cancel".localized, hasCancelButton: Bool, selectAction: UIAction?, cancelAction: UIAction?) {
		self.selectButtonTitle = selectButtonTitle

		super.init()

		cssSelector = .bottomButtonBar

		self.cancelButtonTitle = cancelButtonTitle

		translatesAutoresizingMaskIntoConstraints = false
		selectButton.translatesAutoresizingMaskIntoConstraints = false
		cancelButton.translatesAutoresizingMaskIntoConstraints = false
		promptLabel.translatesAutoresizingMaskIntoConstraints = false
		bottomSeparatorLine.translatesAutoresizingMaskIntoConstraints = false

		var constraints: [NSLayoutConstraint] = []
		var leadingButtonAnchor = selectButton.leadingAnchor

		var selectButtonConfig = UIButton.Configuration.borderedProminent()
		selectButtonConfig.title = selectButtonTitle
		selectButtonConfig.cornerStyle = .large
		selectButton.configuration = selectButtonConfig
		if let selectAction {
			selectButton.addAction(selectAction, for: .primaryActionTriggered)
		}

		if hasCancelButton {
			var cancelButtonConfig = UIButton.Configuration.bordered()
			cancelButtonConfig.title = "Cancel".localized
			cancelButtonConfig.cornerStyle = .large
			cancelButton.configuration = cancelButtonConfig
			if let cancelAction {
				cancelButton.addAction(cancelAction, for: .primaryActionTriggered)
			}

			addSubview(cancelButton)

			leadingButtonAnchor = cancelButton.leadingAnchor

			constraints.append(contentsOf: [
				cancelButton.trailingAnchor.constraint(equalTo: selectButton.leadingAnchor, constant: -15),
				cancelButton.centerYAnchor.constraint(equalTo: selectButton.centerYAnchor)
			])
		}

		promptLabel.text = prompt

		addSubview(selectButton)
		addSubview(promptLabel)
		addSubview(bottomSeparatorLine)

		constraints.append(contentsOf: [
			promptLabel.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 20),
			promptLabel.trailingAnchor.constraint(lessThanOrEqualTo: leadingButtonAnchor, constant: -20),
			promptLabel.centerYAnchor.constraint(equalTo: safeAreaLayoutGuide.centerYAnchor),

			selectButton.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -20),
			selectButton.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 20),
			selectButton.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -20),

			bottomSeparatorLine.leftAnchor.constraint(equalTo: leftAnchor),
			bottomSeparatorLine.rightAnchor.constraint(equalTo: rightAnchor),
			bottomSeparatorLine.topAnchor.constraint(equalTo: topAnchor),
			bottomSeparatorLine.heightAnchor.constraint(equalToConstant: 1)
		])

		NSLayoutConstraint.activate(constraints)
	}

	required public init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}

extension ThemeCSSSelector {
	static let bottomButtonBar = ThemeCSSSelector(rawValue: "bottomButtonBar")
}
