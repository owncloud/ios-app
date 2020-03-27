//
//  AlertView.swift
//  ownCloud
//
//  Created by Felix Schwarz on 26.03.20.
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
import ownCloudSDK

class AlertOption : NSObject {
	typealias ChoiceHandler = (_: AlertView, _: AlertOption) -> Void

	var label : String
	var handler : ChoiceHandler
	var type : OCIssueChoiceType

	init(label: String, type: OCIssueChoiceType, handler: @escaping ChoiceHandler) {
		self.label = label
		self.type = type
		self.handler = handler

		super.init()
	}
}

class AlertView: UIView, Themeable {
	var localizedTitle : String
	var localizedDescription : String

	var options : [AlertOption]

	var titleLabel : UILabel = UILabel()
	var descriptionLabel : UILabel = UILabel()
	var optionStackView : UIStackView?

	var optionViews : [ThemeButton] = []

	init(localizedTitle: String, localizedDescription: String, options: [AlertOption]) {
		self.localizedTitle = localizedTitle
		self.localizedDescription = localizedDescription
		self.options = options

		super.init(frame: .zero)

		prepareViewAndConstraints()

		Theme.shared.register(client: self, applyImmediately: true)
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	deinit {
		Theme.shared.unregister(client: self)
	}

	func createOptionViews() {
		var optionIdx : Int = 0

		for option in options {
			let optionButton = ThemeButton(type: .custom)

			optionButton.setTitle(option.label, for: .normal)
			optionButton.tag = optionIdx
			optionButton.translatesAutoresizingMaskIntoConstraints = false

//			optionButton.setContentHuggingPriority(.defaultLow, for: .horizontal)
			optionButton.setContentHuggingPriority(.required, for: .vertical)
//			optionButton.setContentCompressionResistancePriority(.required, for: .horizontal)
			optionButton.setContentCompressionResistancePriority(.required, for: .vertical)

			optionButton.addTarget(self, action: #selector(optionSelected), for: .primaryActionTriggered)

			optionViews.append(optionButton)

			optionIdx += 1
		}
	}

	@objc func optionSelected(sender: ThemeButton) {
		let option = options[sender.tag]

		option.handler(self, option)
	}

	func prepareViewAndConstraints() {
		titleLabel.numberOfLines = 0
		titleLabel.translatesAutoresizingMaskIntoConstraints = false
		descriptionLabel.numberOfLines = 0
		descriptionLabel.translatesAutoresizingMaskIntoConstraints = false

		titleLabel.text = localizedTitle
		descriptionLabel.text = localizedDescription

		titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
		descriptionLabel.font = .systemFont(ofSize: 14)
		descriptionLabel.textColor = .gray

		createOptionViews()
		optionStackView = UIStackView(arrangedSubviews: optionViews)
		guard let optionStackView = optionStackView else { return }
		optionStackView.translatesAutoresizingMaskIntoConstraints = false

		optionStackView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
		optionStackView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
		optionStackView.setContentHuggingPriority(.required, for: .vertical)
		optionStackView.setContentHuggingPriority(.required, for: .horizontal)
		optionStackView.distribution = .fillEqually
		optionStackView.axis = .horizontal
		optionStackView.spacing = 10

		self.setContentCompressionResistancePriority(.required, for: .vertical)
		self.setContentHuggingPriority(.required, for: .vertical)

		self.addSubview(titleLabel)
		self.addSubview(descriptionLabel)
		self.addSubview(optionStackView)

		titleLabel.setContentHuggingPriority(.required, for: .vertical)
		descriptionLabel.setContentHuggingPriority(.required, for: .vertical)
		titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
		descriptionLabel.setContentCompressionResistancePriority(.required, for: .vertical)

		let enclosure = self.safeAreaLayoutGuide

		NSLayoutConstraint.activate([
			titleLabel.topAnchor.constraint(equalTo: enclosure.topAnchor, constant: 20),
			titleLabel.bottomAnchor.constraint(equalTo: descriptionLabel.topAnchor, constant: -5),
			descriptionLabel.bottomAnchor.constraint(equalTo: optionStackView.topAnchor, constant: -20),
			optionStackView.bottomAnchor.constraint(equalTo: enclosure.bottomAnchor, constant: -20),

			titleLabel.leftAnchor.constraint(equalTo: enclosure.leftAnchor, constant: 20),
			titleLabel.rightAnchor.constraint(equalTo: enclosure.rightAnchor, constant: -20),

			descriptionLabel.leftAnchor.constraint(equalTo: enclosure.leftAnchor, constant: 20),
			descriptionLabel.rightAnchor.constraint(equalTo: enclosure.rightAnchor, constant: -20),

			optionStackView.leftAnchor.constraint(equalTo: enclosure.leftAnchor, constant: 20),
			optionStackView.rightAnchor.constraint(equalTo: enclosure.rightAnchor, constant: -20)
		])
	}

	func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		self.titleLabel.applyThemeCollection(collection)
		self.descriptionLabel.applyThemeCollection(collection)

		var idx : Int = 0

		for optionView in self.optionViews {
			switch options[idx].type {
				case .cancel:
					optionView.themeColorCollection = collection.neutralColors

				case .destructive:
					optionView.themeColorCollection = collection.destructiveColors

				case .regular, .default:
					optionView.themeColorCollection = collection.approvalColors
			}

			idx += 1
		}
	}
}
