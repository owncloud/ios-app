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

public class VectorImageView: UIView, Themeable {
	internal var _vectorImage : TVGImage?
	public var vectorImage : TVGImage? {
		get {
			return _vectorImage
		}

		set(newVectorImage) {
			_vectorImage = newVectorImage
			self.updateLayerWithRasteredImage()
		}
	}

	public override var bounds: CGRect {
		set(viewBounds) {
			super.bounds = viewBounds

			self.updateLayerWithRasteredImage(viewBounds: viewBounds)
		}

		get {
			return super.bounds
		}
	}

	init() {
		super.init(frame: CGRect.zero)
	}

	required public init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		Theme.shared.register(client: self)
	}

	override public init(frame: CGRect) {
		super.init(frame: frame)
		Theme.shared.register(client: self)
	}

	deinit {
		Theme.shared.unregister(client: self)
	}

	public func updateLayerWithRasteredImage(viewBounds bounds: CGRect? = nil, themeCollection: ThemeCollection = Theme.shared.activeCollection) {
		var viewBounds = bounds

		if viewBounds == nil {
			viewBounds = self.bounds
		}

		if let rasterImage = _vectorImage?.image(fitInSize: viewBounds!.size, with: themeCollection.iconColors, cacheFor: themeCollection.identifier) {
			self.layer.contents = rasterImage.cgImage
			self.layer.contentsGravity = CALayerContentsGravity.resizeAspect
		}
	}

	public func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		updateLayerWithRasteredImage(viewBounds: self.bounds, themeCollection: collection)
	}
}
