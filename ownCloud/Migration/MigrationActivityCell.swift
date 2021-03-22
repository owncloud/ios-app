//
//  MigrationActivityCell.swift
//  ownCloud
//
//  Created by Michael Neuwert on 31.03.20.
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
import ownCloudAppShared

class MigrationActivityCell: ThemeTableViewCell {

	static let verticalMargin: CGFloat = 20.0
	static let horizontalMargin: CGFloat = 10.0
	static let horizontalSpace: CGFloat = 15.0
	static let verticalSpace: CGFloat = 5.0

	static let identifier = "migration-activity-cell"

	var activity : MigrationActivity? {
		didSet {
			if let activity = self.activity {
				titleLabel.text = activity.title
				descriptionLabel.text = activity.description

				switch activity.state {
				case .initiated:
					activityView.startAnimating()
				case .finished:
					self.statusImageView.isHidden = false
					self.statusImageView.image = UIImage(named: "checkmark_circle")?.tinted(with: UIColor.systemGreen)
					activityView.stopAnimating()
				case .failed:
					self.statusImageView.isHidden = false
					self.statusImageView.image = UIImage(named: "multiply_circle")?.tinted(with: UIColor.systemRed)
					activityView.stopAnimating()
				}

				switch activity.type {
				case .account:
					self.activityTypeImageView.image = UIImage(named: "person_circle")?.withRenderingMode(.alwaysTemplate)
				case .settings:
					self.activityTypeImageView.image = UIImage(named: "gear")?.withRenderingMode(.alwaysTemplate)
				case .passcode:
					self.activityTypeImageView.image = UIImage(named: "lock_shield")?.withRenderingMode(.alwaysTemplate)
				}
			}
		}
	}

	var titleLabel = UILabel()
	var descriptionLabel = UILabel()
	var activityView = UIActivityIndicatorView(style: .white)
	var statusImageView = UIImageView()
	var activityTypeImageView = UIImageView()

	override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		prepareViewAndConstraints()
	}

	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}

	func prepareViewAndConstraints() {

		self.accessoryType = .none

		activityView.hidesWhenStopped = true

		titleLabel.translatesAutoresizingMaskIntoConstraints = false
		descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
		activityView.translatesAutoresizingMaskIntoConstraints = false

		statusImageView.translatesAutoresizingMaskIntoConstraints = false
		statusImageView.isHidden = true
		statusImageView.contentMode = .scaleAspectFit

		activityTypeImageView.translatesAutoresizingMaskIntoConstraints = false
		activityTypeImageView.contentMode = .scaleAspectFit

		titleLabel.font = UIFont.preferredFont(forTextStyle: .callout)
		titleLabel.adjustsFontForContentSizeCategory = true
		titleLabel.lineBreakMode = .byTruncatingMiddle

		descriptionLabel.font = UIFont.preferredFont(forTextStyle: .footnote)
		descriptionLabel.adjustsFontForContentSizeCategory = true

		self.contentView.addSubview(titleLabel)
		self.contentView.addSubview(descriptionLabel)
		self.contentView.addSubview(activityView)
		self.contentView.addSubview(statusImageView)
		self.contentView.addSubview(activityTypeImageView)

		NSLayoutConstraint.activate([

			activityTypeImageView.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor),
			activityTypeImageView.widthAnchor.constraint(equalToConstant: 35.0),
			activityTypeImageView.heightAnchor.constraint(equalTo: activityTypeImageView.widthAnchor),
			activityTypeImageView.leftAnchor.constraint(equalTo: self.contentView.leftAnchor, constant: MigrationActivityCell.horizontalMargin),

			titleLabel.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: MigrationActivityCell.verticalMargin),
			titleLabel.bottomAnchor.constraint(equalTo: descriptionLabel.topAnchor, constant: -MigrationActivityCell.verticalSpace),
			descriptionLabel.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -MigrationActivityCell.verticalMargin),

			titleLabel.leftAnchor.constraint(equalTo: self.activityTypeImageView.rightAnchor, constant: MigrationActivityCell.horizontalSpace),
			descriptionLabel.leftAnchor.constraint(equalTo: self.activityTypeImageView.rightAnchor, constant: MigrationActivityCell.horizontalSpace),

			titleLabel.rightAnchor.constraint(equalTo: activityView.leftAnchor, constant: -MigrationActivityCell.horizontalSpace),
			descriptionLabel.rightAnchor.constraint(equalTo: activityView.leftAnchor, constant: -MigrationActivityCell.horizontalSpace),

			activityView.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor),
			activityView.widthAnchor.constraint(equalToConstant: 30.0),
			activityView.rightAnchor.constraint(equalTo: self.contentView.rightAnchor, constant: -MigrationActivityCell.horizontalMargin),

			statusImageView.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor),
			statusImageView.widthAnchor.constraint(equalToConstant: 20.0),
			statusImageView.heightAnchor.constraint(equalTo: statusImageView.widthAnchor),
			statusImageView.rightAnchor.constraint(equalTo: self.contentView.rightAnchor, constant: -MigrationActivityCell.horizontalMargin)
		])
	}

	// MARK: - Themeing

	override func applyThemeCollectionToCellContents(theme: Theme, collection: ThemeCollection) {
		let itemState = ThemeItemState(selected: self.isSelected)

		self.titleLabel.applyThemeCollection(collection, itemStyle: .title, itemState: itemState)
		self.descriptionLabel.applyThemeCollection(collection, itemStyle: .message, itemState: itemState)
		activityTypeImageView.tintColor = collection.tableRowColors.symbolColor
	}
}
