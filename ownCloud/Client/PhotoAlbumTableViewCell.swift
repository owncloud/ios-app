//
//  PhotoAlbumTableViewCell.swift
//  ownCloud
//
//  Created by Michael Neuwert on 27.02.2019.
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
import Photos

class PhotoAlbumTableViewCell: ThemeTableViewCell {
	static let identifier = "PhotoAlbumTableViewCell"
	static let cellHeight : CGFloat = 80.0

	fileprivate let margin: CGFloat = 4.0
	static let thumbnailHeight = (cellHeight * 0.9).rounded(.towardZero)

	private static var thumbnailSize: CGSize = {
		let scale = UIScreen.main.scale
		let thumbnailHeight = PhotoAlbumTableViewCell.thumbnailHeight
		let thumbnailSize = CGSize(width: thumbnailHeight * scale, height: thumbnailHeight * scale)
		return thumbnailSize
	}()

	var thumbnailImageView = UIImageView()
	var titleLabel = UILabel()
	var countLabel = UILabel()

	weak var imageCachingManager: PHCachingImageManager?
	var thumbnailRequestID: PHImageRequestID?

	var thumbnailAsset: PHAsset? {
		didSet {
			if let asset = thumbnailAsset {
				let size = PhotoAlbumTableViewCell.thumbnailSize
				let requestOptions = imageRequestOptions(for: asset)
				imageCachingManager?.startCachingImages(for: [asset], targetSize: size, contentMode: .aspectFill, options: requestOptions)
				thumbnailRequestID = imageCachingManager?.requestImage(for: asset,
													  targetSize: size,
													  contentMode: .aspectFill,
													  options: requestOptions) {[weak self] (image, _) in
														self?.thumbnailImageView.image = image
				}
			} else {
				if self.thumbnailRequestID != nil {
					imageCachingManager?.cancelImageRequest(self.thumbnailRequestID!)
					thumbnailRequestID = nil
				}
			}
		}
	}

	override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		setupSubviews()
	}

	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		setupSubviews()
	}

	fileprivate func setupSubviews() {
		self.accessoryType = .disclosureIndicator
		self.selectionStyle = .none
		self.countLabel.textAlignment = .right

		self.contentView.addSubview(thumbnailImageView)
		self.contentView.addSubview(titleLabel)
		self.contentView.addSubview(countLabel)

		self.thumbnailImageView.translatesAutoresizingMaskIntoConstraints = false
		self.titleLabel.translatesAutoresizingMaskIntoConstraints = false
		self.countLabel.translatesAutoresizingMaskIntoConstraints = false

		self.thumbnailImageView.contentMode = .scaleAspectFill
		self.thumbnailImageView.clipsToBounds = true

		self.thumbnailImageView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: margin).isActive = true
		self.thumbnailImageView.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: margin).isActive = true
		self.thumbnailImageView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -margin).isActive = true
		self.thumbnailImageView.widthAnchor.constraint(equalTo: self.thumbnailImageView.heightAnchor).isActive = true

		self.titleLabel.leadingAnchor.constraint(equalTo: self.thumbnailImageView.trailingAnchor, constant: margin * 2.0).isActive = true
		self.titleLabel.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor).isActive = true

		self.countLabel.leadingAnchor.constraint(equalTo: self.titleLabel.trailingAnchor).isActive = true
		self.countLabel.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -margin).isActive = true
		self.countLabel.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor).isActive = true

		self.titleLabel.setContentCompressionResistancePriority(UILayoutPriority.defaultLow, for: NSLayoutConstraint.Axis.horizontal)
		self.countLabel.setContentCompressionResistancePriority(UILayoutPriority.defaultHigh, for: NSLayoutConstraint.Axis.horizontal)

		if #available(iOS 13.4, *) {
			PointerEffect.install(on: self, effectStyle: .hover)
		}
	}

	// MARK: - Theme support
	override func applyThemeCollectionToCellContents(theme: Theme, collection: ThemeCollection) {
		let itemState = ThemeItemState(selected: self.isSelected)

		self.titleLabel.applyThemeCollection(collection, itemStyle: .title, itemState: itemState)
		self.countLabel.applyThemeCollection(collection, itemStyle: .message, itemState: itemState)
	}

	override func prepareForReuse() {
		self.titleLabel.text = nil
		self.countLabel.text = nil
		self.thumbnailImageView.image = nil
		self.thumbnailAsset = nil
	}

	private func cropRect(for asset:PHAsset) -> CGRect {
		let cropSideLength : CGFloat = min(CGFloat(asset.pixelWidth), CGFloat(asset.pixelHeight))
		let square = CGRect(x: 0, y: 0, width: cropSideLength, height: cropSideLength)
		let transform = CGAffineTransform(scaleX: 1.0 / CGFloat(asset.pixelWidth), y: 1.0 / CGFloat(asset.pixelHeight))
		let cropRect = square.applying(transform)

		return cropRect
	}

	private func imageRequestOptions(for thumbnailAsset:PHAsset) -> PHImageRequestOptions {
		let options = PHImageRequestOptions()
		options.deliveryMode = PHImageRequestOptionsDeliveryMode.fastFormat
		options.isSynchronous = false
		options.isNetworkAccessAllowed = true
		options.resizeMode = .exact
		options.normalizedCropRect = cropRect(for: thumbnailAsset)

		return options
	}
}
