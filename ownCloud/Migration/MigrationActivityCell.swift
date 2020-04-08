//
//  MigrationActivityCell.swift
//  ownCloud
//
//  Created by Michael Neuwert on 31.03.20.
//  Copyright © 2020 ownCloud GmbH. All rights reserved.
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

class MigrationActivityCell: ThemeTableViewCell {

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
					// TODO: Indicate with an appropriate icon, that the activity has finished successfully
					activityView.stopAnimating()
				case .failed:
					// TODO: Indicate with an appropriate icon, that the activity has failed
					activityView.stopAnimating()
				}
			}
		}
	}

	var titleLabel = UILabel()
	var descriptionLabel = UILabel()
	var activityView = UIActivityIndicatorView(style: .whiteLarge)

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

		titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
		descriptionLabel.font = .systemFont(ofSize: 14)
		descriptionLabel.textColor = .gray

		self.contentView.addSubview(titleLabel)
		self.contentView.addSubview(descriptionLabel)
		self.contentView.addSubview(activityView)

		activityView.setContentHuggingPriority(.required, for: .horizontal)

		NSLayoutConstraint.activate([
			titleLabel.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 20),
			titleLabel.bottomAnchor.constraint(equalTo: descriptionLabel.topAnchor, constant: -5),
			descriptionLabel.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -20),

			titleLabel.leftAnchor.constraint(equalTo: self.contentView.leftAnchor, constant: 20),
			descriptionLabel.leftAnchor.constraint(equalTo: self.contentView.leftAnchor, constant: 20),

			titleLabel.rightAnchor.constraint(equalTo: activityView.leftAnchor, constant: -20),
			descriptionLabel.rightAnchor.constraint(equalTo: activityView.leftAnchor, constant: -20),

			activityView.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor),
			activityView.widthAnchor.constraint(equalToConstant: 50),
			activityView.rightAnchor.constraint(equalTo: self.contentView.rightAnchor)
		])
	}

	// MARK: - Themeing

	override func applyThemeCollectionToCellContents(theme: Theme, collection: ThemeCollection) {
		let itemState = ThemeItemState(selected: self.isSelected)

		self.titleLabel.applyThemeCollection(collection, itemStyle: .message, itemState: itemState)
		self.descriptionLabel.applyThemeCollection(collection, itemStyle: .title, itemState: itemState)
	}
}
