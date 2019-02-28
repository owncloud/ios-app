//
//  PhotoAlbumTableViewCell.swift
//  ownCloud
//
//  Created by Michael Neuwert on 27.02.2019.
//  Copyright © 2019 ownCloud GmbH. All rights reserved.
//

import UIKit

class PhotoAlbumTableViewCell: ThemeTableViewCell {
	static let identifier = "PhotoAlbumTableViewCell"
	static let cellHeight : CGFloat = 80.0
	fileprivate let thumbnailHeight = (cellHeight * 0.9).rounded(.towardZero)

	override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
		super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
		setupSubviews()
	}

	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		setupSubviews()
	}

	fileprivate func setupSubviews() {
		self.accessoryType = .disclosureIndicator
		self.selectionStyle = .none

		self.imageView?.contentMode = .scaleAspectFill
		self.imageView?.clipsToBounds = true

		imageView?.translatesAutoresizingMaskIntoConstraints = false
		imageView?.widthAnchor.constraint(equalToConstant: thumbnailHeight).isActive = true
		imageView?.heightAnchor.constraint(equalToConstant: thumbnailHeight).isActive = true
	}

	override func prepareForReuse() {
		self.textLabel?.text = nil
		self.detailTextLabel?.text = nil
		self.imageView?.image = nil
	}
}
