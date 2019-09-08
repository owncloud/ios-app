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

		core.handle(event, sender: self)
	}

	@discardableResult func setThumbnailImage(using core:OCCore, from item:OCItem, with size:CGSize, progressHandler:((_ progress:Progress) -> Void)? = nil) -> Progress? {
		if item.thumbnailAvailability != .none {
			let displayThumbnail = { (thumbnail: OCItemThumbnail?) in
				_ = thumbnail?.requestImage(for: size, scale: 0, withCompletionHandler: { (thumbnail, error, _, image) in
					if error == nil, image != nil, item.itemVersionIdentifier == thumbnail?.itemVersionIdentifier {
						OnMainThread {
							self.image = image
						}
					}
				})
			}

			if let thumbnail = item.thumbnail {
				displayThumbnail(thumbnail)
			} else {
				let activeThumbnailRequestProgress = core.retrieveThumbnail(for: item, maximumSize: size, scale: 0, retrieveHandler: { (_, _, _, thumbnail, _, progress) in
					item.thumbnail = thumbnail
					displayThumbnail(thumbnail)

					// No thumbnail returned by the core, try QuickLook thumbnailing on iOS 13
					#if canImport(QuickLookThumbnailing)
					if thumbnail == nil, #available(iOS 13, *) {
						core.provideDirectURL(for: item, allowFileURL: true, completionHandler: { (_, url, _) in
							if let url = url {
								let thumbnailRequest = QLThumbnailGenerator.Request(fileAt: url, size: size, scale: UIScreen.main.scale, representationTypes: .all)
								QLThumbnailGenerator.shared.generateRepresentations(for: thumbnailRequest) { (representation, _, _) in
									if let representation = representation {
										self.cacheThumbnail(image: representation.uiImage, size:size, for: item, in: core)
										OnMainThread {
											self.image = representation.uiImage
										}
									}
								}
							}
						})
					}
					#endif

					if progress != nil {
						progressHandler?(progress!)
					}
				})
				return activeThumbnailRequestProgress
			}
		}

		return nil
	}
}
