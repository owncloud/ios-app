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
					self.activityImageView.image = UIImage(named: "person_circle")?.tinted(with: UIColor.white)
				case .settings:
					self.activityImageView.image = UIImage(named: "gear")?.tinted(with: UIColor.white)
				case .passcode:
					self.activityImageView.image = UIImage(named: "shield_lock")?.tinted(with: UIColor.white)
				}
			}
		}
	}

	var titleLabel = UILabel()
	var descriptionLabel = UILabel()
	var activityView = UIActivityIndicatorView(style: .whiteLarge)
	var statusImageView = UIImageView()
	var activityImageView = UIImageView()

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
		activityImageView.translatesAutoresizingMaskIntoConstraints = false

		titleLabel.font = .systemFont(ofSize: 15, weight: .semibold)
		descriptionLabel.font = .systemFont(ofSize: 12)
		descriptionLabel.textColor = .gray

		self.contentView.addSubview(titleLabel)
		self.contentView.addSubview(descriptionLabel)
		self.contentView.addSubview(activityView)
		self.contentView.addSubview(statusImageView)
		self.contentView.addSubview(activityImageView)

		activityView.setContentHuggingPriority(.required, for: .horizontal)

		NSLayoutConstraint.activate([

			activityImageView.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor),
			activityImageView.widthAnchor.constraint(equalToConstant: 30),
			activityImageView.heightAnchor.constraint(equalTo: activityImageView.widthAnchor),
			activityImageView.leftAnchor.constraint(equalTo: self.contentView.leftAnchor, constant: 10),

			titleLabel.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 20),
			titleLabel.bottomAnchor.constraint(equalTo: descriptionLabel.topAnchor, constant: -5),
			descriptionLabel.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -20),

			titleLabel.leftAnchor.constraint(equalTo: self.activityImageView.rightAnchor, constant: 20),
			descriptionLabel.leftAnchor.constraint(equalTo: self.activityImageView.rightAnchor, constant: 20),

			titleLabel.rightAnchor.constraint(equalTo: activityView.leftAnchor, constant: -10),
			descriptionLabel.rightAnchor.constraint(equalTo: activityView.leftAnchor, constant: -10),

			activityView.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor),
			activityView.widthAnchor.constraint(equalToConstant: 50),
			activityView.rightAnchor.constraint(equalTo: self.contentView.rightAnchor),

			statusImageView.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor),
			statusImageView.widthAnchor.constraint(equalToConstant: 20),
			statusImageView.heightAnchor.constraint(equalTo: statusImageView.widthAnchor),
			statusImageView.rightAnchor.constraint(equalTo: self.contentView.rightAnchor, constant: -15)
		])
	}

	// MARK: - Themeing

	override func applyThemeCollectionToCellContents(theme: Theme, collection: ThemeCollection) {
		let itemState = ThemeItemState(selected: self.isSelected)

		self.titleLabel.applyThemeCollection(collection, itemStyle: .message, itemState: itemState)
		self.descriptionLabel.applyThemeCollection(collection, itemStyle: .title, itemState: itemState)
	}
}
