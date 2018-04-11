//
//  UIImage+Extension.swift
//  ownCloud
//
//  Created by Felix Schwarz on 11.04.18.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

import UIKit

extension UIImage {
	static func imageWithSize(size: CGSize, scale: CGFloat, _  renderBlock: ((_ contentRect: CGRect) -> Void)?) -> UIImage? {
		var image : UIImage?

		UIGraphicsBeginImageContextWithOptions(size, false, scale)

		if renderBlock != nil {
			renderBlock?(CGRect(x: 0, y: 0, width: size.width, height: size.height))
		}

		image = UIGraphicsGetImageFromCurrentImageContext()

		UIGraphicsEndImageContext()

		return image
	}

	func tinted(with color: UIColor, operation: CGBlendMode = CGBlendMode.sourceAtop) -> UIImage? {
		return UIImage.imageWithSize(size: self.size, scale: self.scale, { (contentRect) in
			self.draw(at: CGPoint.zero, blendMode: .normal, alpha: 1.0)

			color.setFill()

			UIRectFillUsingBlendMode(contentRect, operation)
		})
	}
}
