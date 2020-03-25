//
//  MessageCell.swift
//  ownCloud
//
//  Created by Felix Schwarz on 25.03.20.
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

class MessageCell: ThemeTableViewCell {

	weak var delegate: ClientItemCellDelegate?

	var titleLabel : UILabel = UILabel()
	var descriptionLabel : UILabel = UILabel()

	weak var core : OCCore?

	override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		prepareViewAndConstraints()
	}

	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}

	func prepareViewAndConstraints() {
		titleLabel.numberOfLines = 0
		titleLabel.translatesAutoresizingMaskIntoConstraints = false
		descriptionLabel.translatesAutoresizingMaskIntoConstraints = false

		titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
		descriptionLabel.font = .systemFont(ofSize: 14)
		descriptionLabel.textColor = .gray

		self.contentView.addSubview(titleLabel)
		self.contentView.addSubview(descriptionLabel)

		titleLabel.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
		descriptionLabel.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)

		NSLayoutConstraint.activate([
			titleLabel.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 20),
			titleLabel.bottomAnchor.constraint(equalTo: descriptionLabel.topAnchor, constant: -5),
			descriptionLabel.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -20),

			titleLabel.leftAnchor.constraint(equalTo: self.contentView.leftAnchor, constant: 20),
			descriptionLabel.leftAnchor.constraint(equalTo: self.contentView.leftAnchor, constant: 20),

			titleLabel.rightAnchor.constraint(equalTo: self.contentView.rightAnchor, constant: -20),
			descriptionLabel.rightAnchor.constraint(equalTo: self.contentView.rightAnchor, constant: -20)
		])
	}

	// MARK: - Present item
	var message : OCMessage? {
		didSet {
			if let newMessage = message {
				updateWith(newMessage)
			}
		}
	}

	func updateWith(_ message: OCMessage) {
		titleLabel.text = message.syncIssue?.localizedTitle
		descriptionLabel.text = message.syncIssue?.localizedDescription

		self.accessoryType = .none
	}

	// MARK: - Themeing
	override func applyThemeCollectionToCellContents(theme: Theme, collection: ThemeCollection) {
		let itemState = ThemeItemState(selected: self.isSelected)

		self.titleLabel.applyThemeCollection(collection, itemStyle: .title, itemState: itemState)
		self.descriptionLabel.applyThemeCollection(collection, itemStyle: .message, itemState: itemState)
	}
}
