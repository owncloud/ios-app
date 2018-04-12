//
//  TVGImage.swift
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
import PocketSVG

class TVGImage: NSObject {
	var imageString : String?
	var defaultValues : [String:String]?

	init(with data: Data) {
		do {
			let tvgObject : Any = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.init(rawValue: 0))

			if let tvgDict : Dictionary = tvgObject as? [String: Any] {
				imageString = tvgDict["image"] as? String
				defaultValues = tvgDict["defaults"] as? [String:String]
			}
		} catch {
			Log.error("Error parsing TVG image: \(error)")
		}

		super.init()
	}

	func svgString(with variables: [String:String]? = nil) -> String? {
		var compiledString : String? = imageString

		if imageString != nil {
			var compiledValues : [String:String]?

			if (defaultValues != nil) || (variables != nil) {
				if defaultValues != nil {
					if variables != nil {
						compiledValues = [:]
						compiledValues?.merge(defaultValues!) { (_, new) in new }
						compiledValues?.merge(variables!) { (_, new) in new }
					} else {
						compiledValues = defaultValues!
					}
				} else {
					if variables != nil {
						compiledValues = variables!
					}
				}
			}

			if compiledValues != nil {
				for (searchString, replacementString) in compiledValues! {
					compiledString = compiledString?.replacingOccurrences(of: "{{" + searchString + "}}", with: replacementString)
				}
			}
		}

		return compiledString
	}

	func image(fitInSize: CGSize, with variables: [String:String]? = nil) -> UIImage? {
		var image : UIImage?

		guard let svgString : String = self.svgString(with: variables) else {
			return nil
		}

		guard let bezierPaths = SVGBezierPath.paths(fromSVGString: svgString) as? [SVGBezierPath] else {
			return nil
		}

		let fittingSize : CGSize = SVGAdjustCGRectForContentsGravity(SVGBoundingRectForPaths(bezierPaths), fitInSize, kCAGravityResizeAspect).size

		image = UIImage.imageWithSize(size: fittingSize, scale: UIScreen.main.scale) { (rect) in
			if let graphicsContext = UIGraphicsGetCurrentContext() {
				SVGDrawPaths(bezierPaths, graphicsContext, rect, nil, nil)
			}
		}

		return image
	}
}
