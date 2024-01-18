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

	open var promptText: String?
	open var hasCancelButton: Bool

	var activityIndicator: UIActivityIndicatorView?
	var showActivityIndicatorWhileModalActionRunning = true
	open var modalActionRunning: Bool = false {
		didSet {
			if modalActionRunning {
				if activityIndicator == nil, showActivityIndicatorWhileModalActionRunning {
					activityIndicator = UIActivityIndicatorView(style: .medium)
					activityIndicator?.translatesAutoresizingMaskIntoConstraints = false

					if let activityIndicator {
						self.addSubview(activityIndicator)
						NSLayoutConstraint.activate([
							activityIndicator.centerYAnchor.constraint(equalTo: selectButton.centerYAnchor),
							activityIndicator.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20)
						])
					}

					activityIndicator?.startAnimating()
				}
			} else {
				if activityIndicator != nil {
					activityIndicator?.stopAnimating()
					activityIndicator?.removeFromSuperview()
					activityIndicator = nil
				}
			}

			cancelButton.isEnabled = !modalActionRunning
			selectButton.isEnabled = !modalActionRunning
		}
	}

	public init(prompt: String? = nil, selectButtonTitle: String, cancelButtonTitle: String? = "Cancel".localized, hasCancelButton: Bool, selectAction: UIAction?, cancelAction: UIAction?) {
		self.selectButtonTitle = selectButtonTitle
		self.hasCancelButton = hasCancelButton

		super.init()

		cssSelector = .bottomButtonBar

		self.cancelButtonTitle = cancelButtonTitle

		translatesAutoresizingMaskIntoConstraints = false
		selectButton.translatesAutoresizingMaskIntoConstraints = false
		cancelButton.translatesAutoresizingMaskIntoConstraints = false
		promptLabel.translatesAutoresizingMaskIntoConstraints = false
		bottomSeparatorLine.translatesAutoresizingMaskIntoConstraints = false

		selectButton.setContentCompressionResistancePriority(.required, for: .vertical)
		cancelButton.setContentCompressionResistancePriority(.required, for: .vertical)

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
		}

		promptText = prompt
		promptLabel.text = prompt

		addSubview(selectButton)
		addSubview(promptLabel)
		addSubview(bottomSeparatorLine)

		updateLayout()
	}

	var barConstraints: [NSLayoutConstraint]? {
		willSet {
			if let barConstraints {
				NSLayoutConstraint.deactivate(barConstraints)
			}
		}
		didSet {
			if let barConstraints {
				NSLayoutConstraint.activate(barConstraints)
			}
		}
	}

	func updateLayout() {
		var constraints: [NSLayoutConstraint] = []
		let isHorizontalLayout = (traitCollection.horizontalSizeClass == .regular) || (promptText == nil)

		if isHorizontalLayout {
			let leadingButtonAnchor = hasCancelButton ? cancelButton.leadingAnchor : selectButton.leadingAnchor

			constraints.append(contentsOf: [
				promptLabel.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 20),
				promptLabel.trailingAnchor.constraint(lessThanOrEqualTo: leadingButtonAnchor, constant: -20),
				promptLabel.centerYAnchor.constraint(equalTo: selectButton.centerYAnchor),

				selectButton.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -20),
				selectButton.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 20),
				selectButton.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -20)
			])
		} else {
			constraints.append(contentsOf: [
				promptLabel.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 20),
				promptLabel.trailingAnchor.constraint(lessThanOrEqualTo: safeAreaLayoutGuide.trailingAnchor, constant: -20),
				promptLabel.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 10),

				selectButton.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 20).with(priority: .defaultHigh),
				selectButton.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -20),
				selectButton.topAnchor.constraint(equalTo: promptLabel.bottomAnchor, constant: 10),
				selectButton.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -20)
			])

			if hasCancelButton {
				constraints.append(
					cancelButton.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 20)
				)
			}
		}

		if hasCancelButton {
			constraints.append(contentsOf: [
				cancelButton.trailingAnchor.constraint(equalTo: selectButton.leadingAnchor, constant: -15),
				cancelButton.centerYAnchor.constraint(equalTo: selectButton.centerYAnchor)
			])
		}

		constraints.append(contentsOf: [
			bottomSeparatorLine.leftAnchor.constraint(equalTo: leftAnchor),
			bottomSeparatorLine.rightAnchor.constraint(equalTo: rightAnchor),
			bottomSeparatorLine.topAnchor.constraint(equalTo: topAnchor),
			bottomSeparatorLine.heightAnchor.constraint(equalToConstant: 1)
		])

		barConstraints = constraints
	}

	required public init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
		super.traitCollectionDidChange(previousTraitCollection)

		updateLayout()
	}
}

extension ThemeCSSSelector {
	static let bottomButtonBar = ThemeCSSSelector(rawValue: "bottomButtonBar")
}
