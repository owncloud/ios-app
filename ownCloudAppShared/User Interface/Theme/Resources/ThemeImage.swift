//
//  ThemeImage.swift
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

enum ThemeImageType {
	case image
	case template
}

typealias ThemeImageRenderer = (_ image: ThemeImage, _ theme : Theme, _ ThemeCollection: ThemeCollection) -> UIImage?

class ThemeImage : Themeable {
	var type : ThemeImageType = .image

	var renderer : ThemeImageRenderer?

	var identifier : String?

	// MARK: - Init
	init(templateImageNamed: String, identifier: String? = nil, _ renderer: @escaping ThemeImageRenderer) {
		self.type = .template
		self.sourceImageName = templateImageNamed
		self.renderer = renderer
		self.identifier = identifier
	}

	// MARK: - Source Image
	var sourceImageName : String?

	internal var _sourceImage : UIImage?
	var sourceImage : UIImage? {
		set(image) {
			_sourceImage = image
		}
		get {
			if (_sourceImage == nil) && (sourceImageName != nil) {
				_sourceImage = UIImage(named: sourceImageName!)
			}

			return _sourceImage
		}
	}

	// MARK: - Image
	internal var _image : UIImage?
	func image(for theme: Theme) -> UIImage? {
		if _image == nil {
			switch type {
				case .image:
					_image = self.sourceImage

				case .template:
					if renderer != nil {
						_image = renderer!(self, theme, theme.activeCollection)
					} else {
						_image = self.sourceImage
					}
			}
		}

		return _image
	}

	// MARK: - Themeable
	func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		_image = nil
	}
}
