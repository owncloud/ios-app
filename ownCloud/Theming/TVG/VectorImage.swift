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
	var image : TVGImage
	private var rasteredImages : [String:UIImage] = [:]
	private var lastSeenIdentifier : String?

	init(with tvgImage: TVGImage) {
		self.image = tvgImage
	}

	func rasteredImage(fitInSize: CGSize, with variables: [String:String], cacheFor identifier: String? = nil) -> UIImage? {
		var uiImage : UIImage?
		let sizeString = NSStringFromCGSize(fitInSize)

		if identifier != nil {
			OCSynchronized(self) {
				if identifier != lastSeenIdentifier {
					flushRasteredImages()
					lastSeenIdentifier = identifier
				}

				uiImage = rasteredImages[sizeString]

				if uiImage == nil {
					uiImage = image.image(fitInSize: fitInSize, with: variables)

					if uiImage == nil {
						rasteredImages[sizeString] = uiImage
					}
				}
			}
		} else {
			uiImage = image.image(fitInSize: fitInSize, with: variables)
		}

		return uiImage
	}

	func flushRasteredImages() {
		OCSynchronized(self) {
			rasteredImages.removeAll()
		}
	}
}
