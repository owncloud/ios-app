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

public class TVGImage: NSObject {
	var imageString : String?
	var defaultValues : [String:String]?
	var viewBox : CGRect?
	var bezierPathsByIdentifier : [String:[SVGBezierPath]] = [:]
	var bezierPathsBoundsByIdentifier : [String:CGRect] = [:]

	public init?(with data: Data) {
		do {
			let tvgObject : Any = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions(rawValue: 0))

			if let tvgDict : Dictionary = tvgObject as? [String: Any] {
				imageString = tvgDict["image"] as? String
				defaultValues = tvgDict["defaults"] as? [String:String]

				if (tvgDict["viewBox"] as? String) != nil {
					viewBox = NSCoder.cgRect(for: (tvgDict["viewBox"] as? String)!)
				}
			}
		} catch {
			Log.error("Error parsing TVG image: \(error)")

			return nil
		}

		super.init()
	}

	public convenience init?(named name: String) {
		guard let resourceURL = Bundle.main.url(forResource: name, withExtension: "tvg") else {
			return nil
		}

		guard let data = try? Data(contentsOf: resourceURL) else {
			Log.error("Error reading TVG image \(name)")
			return nil
		}

		self.init(with: data)
	}

	public func svgString(with variables: [String:String]? = nil) -> String? {
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

	public func svgBezierPaths(with variables: [String:String]? = nil, cacheFor identifier: String? = nil) -> (CGRect, [SVGBezierPath])? {
		var svgBezierPaths : [SVGBezierPath]?
		var pathBoundingRect : CGRect?

		// Generate SVG Bezier Paths
		if identifier != nil {
			OCSynchronized(self) {
				svgBezierPaths = bezierPathsByIdentifier[identifier!]
			}
		}

		if svgBezierPaths == nil {
			guard let svgString : String = self.svgString(with: variables) else {
				return nil
			}

			let bezierPaths : [SVGBezierPath] = SVGBezierPath.paths(fromSVGString: svgString)

			svgBezierPaths = bezierPaths

			if identifier != nil {
				OCSynchronized(self) {
					bezierPathsByIdentifier[identifier!] = bezierPaths
				}
			}
		}

		// Calculate bounding rect
		if svgBezierPaths != nil {
			if identifier != nil {
				OCSynchronized(self) {
					pathBoundingRect = bezierPathsBoundsByIdentifier[identifier!]
				}
			}

			if pathBoundingRect == nil {
				pathBoundingRect = SVGBoundingRectForPaths(svgBezierPaths!)

				if identifier != nil {
					OCSynchronized(self) {
						bezierPathsBoundsByIdentifier[identifier!] = pathBoundingRect
					}
				}
			}
		}

		if (svgBezierPaths == nil) || (pathBoundingRect == nil) {
			return nil
		}

		return (pathBoundingRect!, svgBezierPaths!)
	}

	public func image(fitInSize: CGSize, with variables: [String:String]? = nil, cacheFor identifier: String? = nil) -> UIImage? {
		var image : UIImage?

		if (fitInSize.width <= 0) || (fitInSize.height <= 0) {
			Log.error("Image can't be rendered at size \(fitInSize)")
			return nil
		}

		guard let (pathBoundingRect, bezierPaths) = svgBezierPaths(with: variables, cacheFor: identifier) else {
			return nil
		}

		let fittingSize : CGSize = SVGAdjustCGRectForContentsGravity(CGRect(origin: CGPoint.zero, size: fitInSize), (viewBox != nil) ? viewBox!.size : pathBoundingRect.size, CALayerContentsGravity.resizeAspect.rawValue).size

		image = UIImage.imageWithSize(size: fittingSize, scale: UIScreen.main.scale) { (rect) in
			if let graphicsContext = UIGraphicsGetCurrentContext() {
				var actualRect = rect

				if let viewBox = self.viewBox {
					actualRect.size.width  = pathBoundingRect.size.width * (fittingSize.width / viewBox.size.width)
					actualRect.size.height = pathBoundingRect.size.height * (fittingSize.height / viewBox.size.height)
				}

				SVGDrawPaths(bezierPaths, graphicsContext, actualRect, nil, nil)
			}
		}

		return image
	}

	public func shapeLayers(fitInSize: CGSize, with variables: [String:String]? = nil, cacheFor identifier: String? = nil) -> CALayer? {
		return nil
	}

	public func flushCaches() {
		OCSynchronized(self) {
			bezierPathsByIdentifier.removeAll()
			bezierPathsBoundsByIdentifier.removeAll()
		}
	}
}
