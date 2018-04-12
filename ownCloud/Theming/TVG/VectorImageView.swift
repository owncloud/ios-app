//
//  VectorImageView.swift
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

class VectorImageView: UIView {
	var vectorImage : TVGImage?

	override var bounds: CGRect {
		set(viewBounds) {
			super.bounds = viewBounds

			self.updateLayerWithRasteredImage(viewBounds: viewBounds)
		}

		get {
			return super.bounds
		}
	}

	func updateLayerWithRasteredImage(viewBounds: CGRect) {
		let themeCollection = Theme.shared.activeCollection

		if let rasterImage = vectorImage?.image(fitInSize: viewBounds.size, with: themeCollection.iconColors, cacheFor: themeCollection.identifier) {
			self.layer.contents = rasterImage.cgImage
			self.layer.contentsGravity = kCAGravityResizeAspect
		}
	}
}
