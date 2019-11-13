//
//  UIImageView+Thumbnails.swift
//  ownCloud
//
//  Created by Michael Neuwert on 31.08.2019.
//  Copyright © 2019 ownCloud GmbH. All rights reserved.
//

import UIKit
import ownCloudSDK

#if canImport(QuickLookThumbnailing)
import QuickLookThumbnailing
#endif

extension UIImageView {

	private func cacheThumbnail(image: UIImage, size:CGSize, for item:OCItem, in core:OCCore) {

		guard let itemVersionIdentifier = item.itemVersionIdentifier else { return }

		let specID = item.mimeType != nil ? item.mimeType! : "_none_"
		let event = OCEvent(type: .retrieveThumbnail,
							userInfo: [OCEventUserInfoKey(rawValue: "specID") : NSString(string: specID), OCEventUserInfoKey.itemVersionIdentifier : itemVersionIdentifier],
							ephermalUserInfo: nil,
							result: nil)

		let thumbnail = OCItemThumbnail()
		thumbnail.itemVersionIdentifier = item.itemVersionIdentifier
		thumbnail.maximumSizeInPixels = size
		thumbnail.mimeType = "image/jpeg"
		thumbnail.data = image.jpegData(compressionQuality: 1.0)
		thumbnail.specID = specID

		event.result = thumbnail
		item.thumbnail = thumbnail

		core.handle(event, sender: self)
	}

	@discardableResult func setThumbnailImage(using core:OCCore, from item:OCItem, with size:CGSize, avoidNetworkRequests:Bool = false, progressHandler:((_ progress:Progress) -> Void)? = nil) -> Progress? {

		weak var weakCore = core

		func requestSystemThumbnailIfPossible() {
			#if canImport(QuickLookThumbnailing)
			if  #available(iOS 13, *) {

				var types : QLThumbnailGenerator.Request.RepresentationTypes?
				types = [.icon, .lowQualityThumbnail, .thumbnail]

				if let itemURL = weakCore?.localURL(for: item) {
					let thumbnailRequest = QLThumbnailGenerator.Request(fileAt: itemURL,
																		size: size,
																		scale: UIScreen.main.scale,
																		representationTypes:types!)
					QLThumbnailGenerator.shared.generateBestRepresentation(for: thumbnailRequest) { (representation, error) in
						if let representation = representation, error == nil {
							self.cacheThumbnail(image: representation.uiImage, size:size, for: item, in: core)
							OnMainThread {
								self.image = representation.uiImage
							}
						}
					}
				}
			}
			#endif
		}

		let displayThumbnail = { (thumbnail: OCItemThumbnail?) in
			_ = thumbnail?.requestImage(for: size, scale: 0, withCompletionHandler: { (thumbnail, error, _, image) in
				if error == nil, image != nil, item.itemVersionIdentifier == thumbnail?.itemVersionIdentifier {
					OnMainThread {
						self.image = image
					}
				}
			})
		}

		if item.thumbnailAvailability == .available {
			if let thumbnail = item.thumbnail {
				displayThumbnail(thumbnail)
			}
			return nil
		}

		if item.thumbnailAvailability != .none {

			let activeThumbnailRequestProgress = weakCore?.retrieveThumbnail(for: item, maximumSize: size, scale: 0, retrieveHandler: { (_, _, _, thumbnail, _, progress) in

				// Did we get valid thumbnail?
				if thumbnail != nil {
					item.thumbnail = thumbnail
					displayThumbnail(thumbnail)
				} else {
					// No thumbnail returned by the core, try QuickLook thumbnailing on iOS 13
					requestSystemThumbnailIfPossible()
				}

				if progress != nil {
					progressHandler?(progress!)
				}
			})
			return activeThumbnailRequestProgress
		}

		return nil
	}
}
