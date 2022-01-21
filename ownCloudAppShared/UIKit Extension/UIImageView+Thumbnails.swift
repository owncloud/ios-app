//
//  UIImageView+Thumbnails.swift
//  ownCloud
//
//  Created by Michael Neuwert on 31.08.2019.
//  Copyright © 2019 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2022, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import UIKit
import ownCloudSDK

public protocol ItemContainer {
	var item : OCItem? { get }
}

public extension UIImageView {
	@discardableResult func setThumbnailImage(using core: OCCore, from requestItem: OCItem, with size: CGSize, itemContainer: ItemContainer? = nil, progressHandler: ((_ progress:Progress) -> Void)? = nil) -> Progress? {
		let displayThumbnail = { (thumbnail: OCItemThumbnail?) in
			_ = thumbnail?.request(for: size, scale: 0, withCompletionHandler: { (_, error, _, image) in
				if error == nil, image != nil, (itemContainer == nil) || ((itemContainer != nil) && itemContainer?.item?.itemVersionIdentifier == thumbnail?.itemVersionIdentifier) {
					OnMainThread {
						self.image = image
					}
				}
			})
		}

		if requestItem.thumbnailAvailability == .available {
			if let thumbnail = requestItem.thumbnail {
				displayThumbnail(thumbnail)
			}
			return nil
		}

		if requestItem.thumbnailAvailability != .none {
			let activeThumbnailRequestProgress = core.retrieveThumbnail(for: requestItem, maximumSize: size, scale: 0, retrieveHandler: { (_, _, _, thumbnail, _, progress) in
				// Did we get valid thumbnail?
				if thumbnail != nil {
					requestItem.thumbnail = thumbnail
					displayThumbnail(thumbnail)
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
