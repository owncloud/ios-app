//
//  VectorImage.swift
//  ownCloud
//
//  Created by Felix Schwarz on 12.04.18.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
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

class VectorImage: NSObject {
	var tvgImage : TVGImage
	private var cachedImages : [String:UIImage] = [:]
	private var lastSeenIdentifier : String?

	init(with tvgImage: TVGImage) {
		self.tvgImage = tvgImage
	}

	func image(fittingSize: CGSize, with variables: [String:String], cacheFor identifier: String? = nil) -> UIImage? {
		var uiImage : UIImage?
		let sizeString = NSStringFromCGSize(fittingSize)

		if identifier != nil {
			OCSynchronized(self) {
				if identifier != lastSeenIdentifier {
					flushCache()
					lastSeenIdentifier = identifier
				}

				uiImage = cachedImages[sizeString]

				if uiImage == nil {
					uiImage = tvgImage.image(fitInSize: fittingSize, with: variables)

					if uiImage == nil {
						cachedImages[sizeString] = uiImage
					}
				}
			}
		} else {
			uiImage = tvgImage.image(fitInSize: fittingSize, with: variables)
		}

		return uiImage
	}

	func flushCache() {
		OCSynchronized(self) {
			cachedImages.removeAll()
		}
	}
}
