//
//  PhotoAlbumTableViewCell.swift
//  ownCloud
//
//  Created by Michael Neuwert on 27.02.2019.
//  Copyright © 2019 ownCloud GmbH. All rights reserved.
//

import UIKit
import Photos

extension PHAssetCollection {
	func fetchThumbnailAsset() -> PHAsset? {
		let fetchOptions = PHFetchOptions()
		fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
		fetchOptions.fetchLimit = 1
		let fetchResult = PHAsset.fetchAssets(in: self, options: fetchOptions)
		return fetchResult.firstObject
	}
}

class PhotoAlbumTableViewCell: ThemeTableViewCell {
	static let identifier = "PhotoAlbumTableViewCell"
	static let cellHeight : CGFloat = 80.0
	fileprivate let thumbnailHeight = (cellHeight * 0.9).rounded(.towardZero)
	var thumbnailRequestId : PHImageRequestID?

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
		// Cancel eventually pending thumbnail request
		if thumbnailRequestId != nil {
			PHImageManager.default().cancelImageRequest(thumbnailRequestId!)
			thumbnailRequestId = nil
		}
		self.collection = nil
		self.textLabel?.text = nil
		self.detailTextLabel?.text = nil
		self.imageView?.image = nil
	}

	var collection : PHAssetCollection? {
		didSet {
			if collection != nil {
				self.textLabel?.text = collection!.localizedTitle
				if collection!.estimatedAssetCount != NSNotFound {
					self.detailTextLabel?.text = "\(collection!.estimatedAssetCount)"
				}

				DispatchQueue.global(qos: .background).async { [weak self] in
					if let asset = self?.collection?.fetchThumbnailAsset() {
						self?.getThumbnailImage(from: asset, completion: { (image) in
							OnMainThread {
								self?.imageView?.image = image
								self?.setNeedsLayout()
							}
						})
					}
				}
			}
		}
	}

	fileprivate func getThumbnailImage(from asset:PHAsset, completion:@escaping (_ image:UIImage?) -> Void) {
		let imageManager = PHImageManager.default()

		// Setup request options
		let options = PHImageRequestOptions()
		options.deliveryMode = PHImageRequestOptionsDeliveryMode.fastFormat
		options.isSynchronous = false
		options.isNetworkAccessAllowed = true
		options.resizeMode = .exact
		let cropSideLength : CGFloat = min(CGFloat(asset.pixelWidth), CGFloat(asset.pixelHeight))
		let square = CGRect(x: 0, y: 0, width: cropSideLength, height: cropSideLength)
		let transform = CGAffineTransform(scaleX: 1.0 / CGFloat(asset.pixelWidth), y: 1.0 / CGFloat(asset.pixelHeight))
		let cropRect = square.applying(transform)
		options.normalizedCropRect = cropRect

		// Consider retina scale factor, since target size has to be provided in pixels
		let scale = UIScreen.main.scale
		let thumbnailSize = CGSize(width: thumbnailHeight * scale, height: thumbnailHeight * scale)
		thumbnailRequestId = imageManager.requestImage(for: asset, targetSize: thumbnailSize, contentMode: .aspectFill, options: options) { [weak self] (image, _) in
			self?.thumbnailRequestId = nil
			completion(image)
		}
	}
}
