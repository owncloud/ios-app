//
//  ThemeTVGResource.swift
//  ownCloud
//
//  Created by Felix Schwarz on 13.04.18.
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

class ThemeTVGResource: ThemeResource {
	var tvgName : String?

	required init(name: String, identifier resIdent: String) {
		super.init()

		tvgName = name
		identifier = resIdent
	}

	/// Called when the resource has not yet been loaded into memory. Implementations are expected to load the resource and return it (subclass this)
	override func load() -> Any? {
		if tvgName != nil {
			return TVGImage(named: tvgName!)
		}

		return nil
	}

	/// Called when the theme changed, in order to flush cached resources (subclass this as needed, releases _resource by default)
	override func flushThemedResources() {
		OCSynchronized(self) {
			(_resource as? VectorImage)?.flushRasteredImages()
		}
	}

	/// Called when no themed version of the resource has yet been created (subclass this)
	override func applyThemeToResource(theme: Theme, collection: ThemeCollection, source: Any?) -> Any? {
		if let image = (source as? TVGImage) {
			return VectorImage(with: image)
		}

		return nil
	}

	func tvgImage() -> TVGImage? {
		if let tvgImage = (self.sourceResource as? TVGImage) {
			return tvgImage
		}

		return nil
	}

	func vectorImage(for theme: Theme) -> VectorImage? {
		return self.resource(for: theme) as? VectorImage
	}
}
