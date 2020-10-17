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

	enum ImageExportError : Error {
		case missingRepresentation
	}

	enum OutputImageFormat { case HEIF, JPEG}

	func convert(targetURL:URL, outputFormat:OutputImageFormat) -> Error? {

		// Conversion to JPEG required
		let colorSpace = CGColorSpaceCreateDeviceRGB()
		let ciContext = CIContext()
		var imageData : Data?
		var outError: Error?

		func cleanUpCoreImageRessources() {
			// Release memory consuming resources
			imageData = nil
			ciContext.clearCaches()
		}

		defer {
			cleanUpCoreImageRessources()
		}

		switch outputFormat {
		case .JPEG:
			imageData = ciContext.jpegRepresentation(of: self, colorSpace: colorSpace)
		case .HEIF:
			imageData = ciContext.heifRepresentation(of: self, format: CIFormat.RGBA8, colorSpace: colorSpace)
		}

		if imageData != nil {
			do {
				try imageData!.write(to: targetURL)
			} catch let error as NSError {
				outError = error
			}
		} else {
			outError = ImageExportError.missingRepresentation
		}

		return outError

	}
}
