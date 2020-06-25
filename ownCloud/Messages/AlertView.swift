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
	var localizedHeader : String?

	var localizedTitle : String
	var localizedDescription : String

	var options : [AlertOption]

	var headerLabel : UILabel = UILabel()
	var headerContainer : UIView = UIView()

	var titleLabel : UILabel = UILabel()
	var descriptionLabel : UILabel = UILabel()
	var optionStackView : UIStackView?

	var optionViews : [ThemeButton] = []

	init(localizedHeader: String? = nil, localizedTitle: String, localizedDescription: String, options: [AlertOption]) {
		self.localizedHeader = localizedHeader
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

	private let headerTextHorizontalInset : CGFloat = 20
	private let headerTextVerticalInset : CGFloat = 7
	private let titleAndDescriptionSpacing : CGFloat = 5
	private let contentPadding : CGFloat = 20
	private let optionInnerSpacing : CGFloat = 10

	private let headerLabelFontSize : CGFloat = 14
	private let titleLabelFontSize : CGFloat = 17
	private let descriptionLabelFontSize : CGFloat = 14

	func prepareViewAndConstraints() {
		headerLabel.numberOfLines = 1
		headerLabel.translatesAutoresizingMaskIntoConstraints = false
		titleLabel.numberOfLines = 0
		titleLabel.translatesAutoresizingMaskIntoConstraints = false
		descriptionLabel.numberOfLines = 0
		descriptionLabel.translatesAutoresizingMaskIntoConstraints = false

		headerLabel.text = localizedHeader
		titleLabel.text = localizedTitle
		descriptionLabel.text = localizedDescription

		headerLabel.font = .systemFont(ofSize: headerLabelFontSize, weight: .regular)
		headerLabel.textColor = .gray

		titleLabel.font = .systemFont(ofSize: titleLabelFontSize, weight: .semibold)

		descriptionLabel.font = .systemFont(ofSize: descriptionLabelFontSize)
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
		optionStackView.spacing = optionInnerSpacing

		self.setContentCompressionResistancePriority(.required, for: .vertical)
		self.setContentHuggingPriority(.required, for: .vertical)

		self.addSubview(titleLabel)
		self.addSubview(descriptionLabel)
		self.addSubview(optionStackView)

		headerLabel.setContentHuggingPriority(.required, for: .vertical)
		titleLabel.setContentHuggingPriority(.required, for: .vertical)
		descriptionLabel.setContentHuggingPriority(.required, for: .vertical)

		headerLabel.setContentCompressionResistancePriority(.required, for: .vertical)
		titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
		descriptionLabel.setContentCompressionResistancePriority(.required, for: .vertical)

		let enclosure = self.safeAreaLayoutGuide

		if localizedHeader != nil {
			headerContainer.translatesAutoresizingMaskIntoConstraints = false
			headerContainer.setContentCompressionResistancePriority(.required, for: .vertical)
			headerContainer.setContentHuggingPriority(.required, for: .vertical)

			headerContainer.addSubview(headerLabel)
			self.addSubview(headerContainer)

			NSLayoutConstraint.activate([
				headerLabel.leftAnchor.constraint(equalTo: headerContainer.leftAnchor, constant: headerTextHorizontalInset),
				headerLabel.rightAnchor.constraint(equalTo: headerContainer.rightAnchor, constant: -headerTextHorizontalInset),
				headerLabel.topAnchor.constraint(equalTo: headerContainer.topAnchor, constant: headerTextVerticalInset),
				headerLabel.bottomAnchor.constraint(equalTo: headerContainer.bottomAnchor, constant: -headerTextVerticalInset),

				headerContainer.topAnchor.constraint(equalTo: enclosure.topAnchor),
				headerContainer.leftAnchor.constraint(equalTo: enclosure.leftAnchor),
				headerContainer.rightAnchor.constraint(equalTo: enclosure.rightAnchor)
			])
		}

		NSLayoutConstraint.activate([
			titleLabel.topAnchor.constraint(equalTo: ((localizedHeader != nil) ? headerContainer.bottomAnchor : enclosure.topAnchor), constant: contentPadding),
			titleLabel.bottomAnchor.constraint(equalTo: descriptionLabel.topAnchor, constant: -titleAndDescriptionSpacing),
			descriptionLabel.bottomAnchor.constraint(equalTo: optionStackView.topAnchor, constant: -contentPadding),
			optionStackView.bottomAnchor.constraint(equalTo: enclosure.bottomAnchor, constant: -contentPadding),

			titleLabel.leftAnchor.constraint(equalTo: enclosure.leftAnchor, constant: contentPadding),
			titleLabel.rightAnchor.constraint(equalTo: enclosure.rightAnchor, constant: -contentPadding),

			descriptionLabel.leftAnchor.constraint(equalTo: enclosure.leftAnchor, constant: contentPadding),
			descriptionLabel.rightAnchor.constraint(equalTo: enclosure.rightAnchor, constant: -contentPadding),

			optionStackView.leftAnchor.constraint(equalTo: enclosure.leftAnchor, constant: contentPadding),
			optionStackView.rightAnchor.constraint(equalTo: enclosure.rightAnchor, constant: -contentPadding)
		])
	}

	func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		self.headerLabel.applyThemeCollection(collection)
		self.titleLabel.applyThemeCollection(collection)
		self.descriptionLabel.applyThemeCollection(collection)

		self.headerContainer.backgroundColor = collection.navigationBarColors.backgroundColor
		self.headerLabel.textColor = collection.navigationBarColors.secondaryLabelColor

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
