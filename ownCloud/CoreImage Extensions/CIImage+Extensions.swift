//
//  CIImage+Extensions.swift
//  ownCloud
//
//  Created by Michael Neuwert on 17.07.2019.
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

import CoreImage

extension CIImage {

	enum OutputImageFormat { case HEIF, JPEG}

	func convert(targetURL:URL, outputFormat:OutputImageFormat) -> Bool {
		// Conversion to JPEG required
		let colorSpace = CGColorSpaceCreateDeviceRGB()
		var ciContext = CIContext()
		var imageData : Data?

		func cleanUpCoreImageRessources() {
			// Release memory consuming resources
			imageData = nil
			ciContext.clearCaches()
		}

		switch outputFormat {
		case .JPEG:
			imageData = ciContext.jpegRepresentation(of: self, colorSpace: colorSpace)
		case .HEIF:
			imageData = ciContext.heifRepresentation(of: self, format: CIFormat.RGBA8, colorSpace: colorSpace)
		}

		if imageData != nil {
			do {
				// First write an image to a file stored in temporary directory
				try imageData!.write(to: targetURL)
				cleanUpCoreImageRessources()
				return true
			} catch {
				cleanUpCoreImageRessources()
			}
		}

		return false
	}
}
