//
//  PhotoUploadCell.swift
//  ownCloud
//
//  Created by Michael Neuwert on 24.02.2019.
//  Copyright © 2019 ownCloud GmbH. All rights reserved.
//

import UIKit

class PhotoSelectionViewCell: UICollectionViewCell {

	static let identifier = "PhotoSelectionViewCell"

	fileprivate let badgeSizeMultiplier: CGFloat = 0.25
	fileprivate let checkmarkMargin: CGFloat = 2.0

	var imageView = UIImageView()
	var livePhotoBadgeImageView = UIImageView()
	var checkmarkBadgeImageView = UIImageView()
	var videoDurationLabel = UILabel()

	var assetIdentifier: String!

	var thumbnailImage: UIImage! {
		didSet {
			imageView.image = thumbnailImage
		}
	}

	var livePhotoBadgeImage: UIImage! {
		didSet {
			livePhotoBadgeImageView.image = livePhotoBadgeImage
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
		livePhotoBadgeImageView.image = nil
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

		livePhotoBadgeImageView.translatesAutoresizingMaskIntoConstraints = false
		self.imageView.addSubview(livePhotoBadgeImageView)

		livePhotoBadgeImageView.leadingAnchor.constraint(equalTo: self.imageView.leadingAnchor).isActive = true
		livePhotoBadgeImageView.topAnchor.constraint(equalTo: self.imageView.topAnchor).isActive = true
		livePhotoBadgeImageView.widthAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: badgeSizeMultiplier).isActive = true
		livePhotoBadgeImageView.heightAnchor.constraint(equalTo: imageView.heightAnchor, multiplier: badgeSizeMultiplier).isActive = true

		videoDurationLabel.translatesAutoresizingMaskIntoConstraints = false
		videoDurationLabel.font = UIFont.systemFont(ofSize: UIFont.smallSystemFontSize, weight: UIFont.Weight.light)
		videoDurationLabel.textColor = UIColor.white
		self.imageView.addSubview(videoDurationLabel)

		videoDurationLabel.leadingAnchor.constraint(equalTo: self.imageView.leadingAnchor).isActive = true
		videoDurationLabel.bottomAnchor.constraint(equalTo: self.imageView.bottomAnchor).isActive = true

		let checkmarkImage =  UIImage(named: "check-mark")
		checkmarkBadgeImageView.image = checkmarkImage
		checkmarkBadgeImageView.isHidden = true
		checkmarkBadgeImageView.translatesAutoresizingMaskIntoConstraints = false
		imageView.addSubview(checkmarkBadgeImageView)

		checkmarkBadgeImageView.rightAnchor.constraint(equalTo: self.imageView.rightAnchor, constant: -checkmarkMargin).isActive = true
		checkmarkBadgeImageView.bottomAnchor.constraint(equalTo: self.imageView.bottomAnchor, constant: -checkmarkMargin).isActive = true

	}

}
