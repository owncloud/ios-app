//
//  ThemeImage.swift
//  ownCloud
//
//  Created by Felix Schwarz on 11.04.18.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

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

	private var _sourceImage : UIImage?
	var sourceImage : UIImage? {
		set(image) {
			_sourceImage = image
		}
		get {
			if (_sourceImage == nil) && (sourceImageName != nil) {
				_sourceImage = UIImage.init(named: sourceImageName!)
			}

			return _sourceImage
		}
	}

	// MARK: - Image
	private var _image : UIImage?
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
