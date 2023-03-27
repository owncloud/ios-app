//
//  NSObject+ThemeCSS.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 19.03.23.
//  Copyright © 2023 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2023, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import UIKit
import ownCloudSDK

public protocol ThemeCSSAutoSelector {
	var cssAutoSelectors: [ThemeCSSSelector] { get }
}

public protocol ThemeCSSChangeObserver {
	func cssSelectorsChanged()
}

extension NSObject {
	private struct AssociatedKeys {
		static var cssSelectors = "_cssSelectors"
	}

	public var activeThemeCSS: ThemeCSS {
		return Theme.shared.activeCollection.css
	}

	public func getThemeCSSColor(_ property: ThemeCSSProperty, selectors: [ThemeCSSSelector]? = nil, state stateSelectors: [ThemeCSSSelector]? = nil) -> UIColor? {
		return activeThemeCSS.getColor(property, selectors: selectors, state: stateSelectors, for: self)
	}

	public var cssSelectors: [ThemeCSSSelector]? {
		set {
			objc_setAssociatedObject(self, &AssociatedKeys.cssSelectors, newValue, .OBJC_ASSOCIATION_RETAIN)

			if let changeObserver = self as? ThemeCSSChangeObserver {
				changeObserver.cssSelectorsChanged()
			}
		}

		get {
			var effectiveSelectors: [ThemeCSSSelector] = objc_getAssociatedObject(self, &AssociatedKeys.cssSelectors) as? [ThemeCSSSelector] ?? []

			if let autoSelector = self as? ThemeCSSAutoSelector {
				effectiveSelectors.insert(contentsOf: autoSelector.cssAutoSelectors, at: (effectiveSelectors.count > 0) ? (effectiveSelectors.count-1) : 0)
			}

			if let viewController = self as? UIViewController, viewController.parent == nil, viewController.presentingViewController != nil {
				effectiveSelectors.insert(.modal, at: 0)
			}

			return effectiveSelectors
		}
	}

	public var cssSelector: ThemeCSSSelector? {
		get {
			return cssSelectors?.first
		}
		set {
			if let newValue {
				cssSelectors = [newValue]
			} else {
				cssSelectors = nil
			}
		}
	}

	private var _parentCSSObject: NSObject? {
		if let view = self as? UIView {
			if let viewController = view.next as? UIViewController, viewController.view == self {
				return viewController
			}

			return view.superview
		}

		if let viewController = self as? UIViewController {
			return viewController.view.superview // viewController.parent?.view
		}

		return nil
	}

	public var cascadingStyleSelectors: [ThemeCSSSelector] {
		var obj: NSObject? = self
		var cascadingStyleSelectors: [ThemeCSSSelector] = [.all]

		while obj != nil {
			if let styleSelectors = obj?.cssSelectors {
				for addSelector in styleSelectors.reversed() {
					if !cascadingStyleSelectors.contains(addSelector) {
						cascadingStyleSelectors.insert(addSelector, at: 1)
					}
				}
			}

			obj = obj?._parentCSSObject
		}

		return cascadingStyleSelectors
	}

	@objc public var cssDescription: String {
		let selectors = (cascadingStyleSelectors.compactMap({ selector in
			return selector.rawValue as NSString
		}) as NSArray).componentsJoined(by: ".")

		let properties: [ThemeCSSProperty] = [
			.stroke, .fill, .cornerRadius
		]

		var records = ""

		for property in properties {
			records += "- \(property.rawValue): "
			if let record = Theme.shared.activeCollection.css.get(property, for: self) {
				records += "\((record.selectors.compactMap({ selector in selector.rawValue }) as NSArray).componentsJoined(by: ".")) -> \(record.value != nil ? record.value! : "-")"
			} else {
				records += "-"
			}
			records += "\n"
		}

		return "Selectors: \(selectors)\nMatching:\n\(records)"
	}
}
