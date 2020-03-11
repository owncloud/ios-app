//
//  UIImage+Extension.swift
//  ownCloud
//
//  Created by Felix Schwarz on 11.04.18.
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

extension UIImage {
	static public func imageWithSize(size: CGSize, scale: CGFloat, _  renderBlock: ((_ contentRect: CGRect) -> Void)?) -> UIImage? {
		var image : UIImage?

		UIGraphicsBeginImageContextWithOptions(size, false, scale)

		if renderBlock != nil {
			renderBlock?(CGRect(x: 0, y: 0, width: size.width, height: size.height))
		}

		image = UIGraphicsGetImageFromCurrentImageContext()

		UIGraphicsEndImageContext()

		return image
	}

	public func tinted(with color: UIColor, operation: CGBlendMode = CGBlendMode.sourceAtop) -> UIImage? {
		return UIImage.imageWithSize(size: self.size, scale: self.scale, { (contentRect) in
			self.draw(at: CGPoint.zero, blendMode: .normal, alpha: 1.0)

			color.setFill()

			UIRectFillUsingBlendMode(contentRect, operation)
		})
	}

	public func paddedTo(width: CGFloat? = nil, height : CGFloat? = nil) -> UIImage? {
		let origSize = size
		let newSize : CGSize = CGSize(width: width ?? origSize.width, height: height ?? origSize.height)
		var image : UIImage? = UIImage.imageWithSize(size: newSize, scale: scale, { (contentRect) in
			self.draw(at: CGPoint(x: Int((contentRect.size.width - origSize.width) / 2), y: Int((contentRect.size.height - origSize.height) / 2)))
		})

		if image != nil, image?.renderingMode != self.renderingMode {
			image = image?.withRenderingMode(self.renderingMode)
		}

		return image
	}
}
