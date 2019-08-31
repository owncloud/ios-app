//
//  UIImageView+Thumbnails.swift
//  ownCloud
//
//  Created by Michael Neuwert on 31.08.2019.
//  Copyright © 2019 ownCloud GmbH. All rights reserved.
//

import UIKit
import ownCloudSDK
import QuickLookThumbnailing

extension UIImageView {
	@discardableResult func setThumbnailImage(using core:OCCore, from item:OCItem, with size:CGSize, progressHandler:((_ progress:Progress) -> Void)? = nil) -> Progress? {
		if #available(iOS 13, *) {
			core.provideDirectURL(for: item, allowFileURL: true, completionHandler: { (_, url, _) in
				if let url = url {
					let thumbnailRequest = QLThumbnailGenerator.Request(fileAt: url, size: size, scale: UIScreen.main.scale, representationTypes: .all)
					QLThumbnailGenerator.shared.generateRepresentations(for: thumbnailRequest) { (representation, _, _) in
						if let representation = representation {
							OnMainThread {
								self.image = representation.uiImage
							}
						}
					}
				}
			})
		} else {
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
						displayThumbnail(thumbnail)

						if progress != nil {
							progressHandler?(progress!)
						}
					})
					return activeThumbnailRequestProgress
				}
			}
		}

		return nil
	}
}
