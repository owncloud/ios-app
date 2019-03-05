//
//  PhotoUploadCell.swift
//  ownCloud
//
//  Created by Michael Neuwert on 24.02.2019.
//  Copyright © 2019 ownCloud GmbH. All rights reserved.
//

/*
* Copyright (C) 2018, ownCloud GmbH.
*
* This code is covered by the GNU Public License Version 3.
*
* For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
* You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
*
*/

import UIKit

class PhotoSelectionViewCell: UICollectionViewCell {

	static let identifier = "PhotoSelectionViewCell"

	fileprivate let badgeMargin: CGFloat = 4.0

	var imageView = UIImageView()
	var mediaTypeBadgeImageView = UIImageView()
	var checkmarkBadgeImageView = UIImageView()
	var videoDurationLabel = UILabel()
	
	var assetIdentifier: String!

	var thumbnailImage: UIImage! {
		didSet {
			imageView.image = thumbnailImage
		}
	}

	var mediaBadgeImage: UIImage! {
		didSet {
			mediaTypeBadgeImageView.image = mediaBadgeImage
		}
	}

	override var isSelected: Bool {
		didSet {
			checkmarkBadgeImageView.isHidden = !isSelected
		}
	}

	override func prepareForReuse() {
		super.prepareForReuse()
		imageView.image = nil
		mediaTypeBadgeImageView.image = nil
		videoDurationLabel.text = nil
	}

	override init(frame: CGRect) {
		super.init(frame: frame)
		setupSubviews()
	}

	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		setupSubviews()
	}

	fileprivate func setupSubviews() {
		imageView.contentMode = .scaleAspectFill
		imageView.clipsToBounds = true
		imageView.translatesAutoresizingMaskIntoConstraints = false
		self.contentView.addSubview(imageView)

		imageView.topAnchor.constraint(equalTo: self.contentView.topAnchor).isActive = true
		imageView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor).isActive = true
		imageView.leftAnchor.constraint(equalTo: self.contentView.leftAnchor).isActive = true
		imageView.rightAnchor.constraint(equalTo: self.contentView.rightAnchor).isActive = true

		mediaTypeBadgeImageView.translatesAutoresizingMaskIntoConstraints = false
		self.imageView.addSubview(mediaTypeBadgeImageView)

		mediaTypeBadgeImageView.leadingAnchor.constraint(equalTo: self.imageView.leadingAnchor, constant: badgeMargin).isActive = true
		mediaTypeBadgeImageView.topAnchor.constraint(equalTo: self.imageView.topAnchor, constant: badgeMargin).isActive = true

		videoDurationLabel.translatesAutoresizingMaskIntoConstraints = false
		videoDurationLabel.font = UIFont.systemFont(ofSize: UIFont.smallSystemFontSize, weight: UIFont.Weight.light)
		videoDurationLabel.textColor = UIColor.white
		self.imageView.addSubview(videoDurationLabel)

		videoDurationLabel.leadingAnchor.constraint(equalTo: self.imageView.leadingAnchor, constant: badgeMargin).isActive = true
		videoDurationLabel.bottomAnchor.constraint(equalTo: self.imageView.bottomAnchor).isActive = true

		let checkmarkImage =  UIImage(named: "check-mark")
		checkmarkBadgeImageView.image = checkmarkImage
		checkmarkBadgeImageView.isHidden = true
		checkmarkBadgeImageView.translatesAutoresizingMaskIntoConstraints = false
		imageView.addSubview(checkmarkBadgeImageView)

		checkmarkBadgeImageView.rightAnchor.constraint(equalTo: self.imageView.rightAnchor, constant: -badgeMargin).isActive = true
		checkmarkBadgeImageView.bottomAnchor.constraint(equalTo: self.imageView.bottomAnchor, constant: -badgeMargin).isActive = true

	}

}
