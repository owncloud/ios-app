//
//  ThemeStyle+Extensions.swift
//  ownCloud
//
//  Created by Felix Schwarz on 26.10.18.
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

import Foundation
import ownCloudSDK

@available(iOS 13.0, *)
extension UIUserInterfaceStyle {
	func themeCollectionStyles() -> [ThemeCollectionStyle] {
		if self == .dark {
			return [.dark]
		}

		return [.light, .contrast]
	}
}

extension ThemeStyle {
	public func themeStyleExtension(isDefault: Bool = false, isBranding: Bool = false) -> OCExtension {
		let features : [String:Any] = [
			ThemeStyleFeatureKeys.localizedName : self.localizedName,
			ThemeStyleFeatureKeys.isDefault	    : isDefault,
			ThemeStyleFeatureKeys.isBranding    : isBranding
		]

		return OCExtension(identifier: OCExtensionIdentifier(rawValue: self.identifier), type: .themeStyle, location: OCExtensionLocationIdentifier(rawValue: self.identifier), features: features, objectProvider: { (_, _, _) -> Any? in
			return self
		})
	}

	static public var defaultStyle: ThemeStyle {
		let matchContext = OCExtensionContext(location: OCExtensionLocation(ofType: .themeStyle, identifier: nil),
						      requirements: [ThemeStyleFeatureKeys.isDefault : true], // Match default
						      preferences: [ThemeStyleFeatureKeys.isBranding : true]) // Prefer brandings (=> boosts score of brandings so it outmatches built-in styles)

		if let matches : [OCExtensionMatch] = try? OCExtensionManager.shared.provideExtensions(for: matchContext),
		   matches.count > 0,
		   let styleExtension = matches.first?.extension,
		   let defaultStyle = styleExtension.provideObject(for: matchContext) as? ThemeStyle {
			return defaultStyle
		}

		Log.error("Couldn't get defaultStyle")

		return ThemeStyle.ownCloudDark
	}

	static public var preferredStyle : ThemeStyle {
		set {
			// Store preferred theme style to shared userDefaults
			OCAppIdentity.shared.userDefaults?.setValue(newValue.identifier, forKey: "preferred-theme-style")

			considerAppearanceUpdate(animated: true)
		}

		get {
			var style : ThemeStyle?

			// This setting was previously stored in UserDefaults.standard. If it exists there, make sure to move it over
			// and subsequently remove it, so it can't overwrite changes to the value coming after that.
			if let legacyLocalPreferredThemeStyleIdentifier = UserDefaults.standard.string(forKey: "preferred-theme-style") {
				OCAppIdentity.shared.userDefaults?.setValue(legacyLocalPreferredThemeStyleIdentifier, forKey: "preferred-theme-style")
				UserDefaults.standard.removeObject(forKey: "preferred-theme-style")
			}

			// Retrieve preferred theme style from shared userDefaults
			if let preferredThemeStyleIdentifier = OCAppIdentity.shared.userDefaults?.string(forKey: "preferred-theme-style") {
				style = .forIdentifier(preferredThemeStyleIdentifier)
			}

			if style == nil {
				style = .defaultStyle
			}

			return style!
		}
	}

	static public var displayName : String {
		if #available(iOS 13, *), ThemeStyle.followSystemAppearance {
			return "System".localized
		}

		return ThemeStyle.preferredStyle.localizedName
	}

	@available(iOS 13.0, *)
	static public func userInterfaceStyle() -> UIUserInterfaceStyle? {
		return UITraitCollection.current.userInterfaceStyle
	}

	static public func considerAppearanceUpdate(animated: Bool = false) {
		let rootView : UIView? = UserInterfaceContext.shared.rootView
		var applyStyle : ThemeStyle? = ThemeStyle.preferredStyle

		if #available(iOS 13, *) {
			if self.followSystemAppearance {
				if ThemeStyle.userInterfaceStyle() == .dark {
					if let darkStyleIdentifier = ThemeStyle.preferredStyle.darkStyleIdentifier, let style = ThemeStyle.forIdentifier(darkStyleIdentifier) {
						ThemeStyle.preferredStyle = style
						applyStyle = style
					}
				} else {
					if ThemeStyle.preferredStyle.themeStyle == .dark, let style = ThemeStyle.availableStyles(for: [.contrast])?.first {
						ThemeStyle.preferredStyle = style
						applyStyle = style
					}
				}
			}
		}

		if let applyStyle = applyStyle {
			let themeCollection = ThemeCollection(with: applyStyle)

			if #available(iOS 13, *) {
				if let themeWindowSubviews = rootView?.subviews {
					for view in themeWindowSubviews {
						view.overrideUserInterfaceStyle = themeCollection.interfaceStyle.userInterfaceStyle
					}
				}
			}

			if animated {
				Theme.shared.switchThemeCollection(themeCollection)
			} else {
				Theme.shared.activeCollection = themeCollection
			}
		}
	}

	static public var followSystemAppearance : Bool {
		set {
			OCAppIdentity.shared.userDefaults?.setValue(newValue, forKey: "theme-style-follows-system-appearance")

			considerAppearanceUpdate()
		}

		get {
			var followSystemAppearance : Bool?

			if let themeStyleFollowsSystemAppearance = OCAppIdentity.shared.userDefaults?.object(forKey: "theme-style-follows-system-appearance") as? Bool {
				followSystemAppearance = themeStyleFollowsSystemAppearance
			}

			if followSystemAppearance == nil {
				followSystemAppearance = false
			}

			return followSystemAppearance!
		}

	}

	static public func forIdentifier(_ identifier: ThemeStyleIdentifier) -> ThemeStyle? {
		let matchContext = OCExtensionContext(location: OCExtensionLocation(ofType: .themeStyle, identifier: OCExtensionLocationIdentifier(rawValue: identifier)), requirements: nil, preferences: nil)

		if let matches : [OCExtensionMatch] = try? OCExtensionManager.shared.provideExtensions(for: matchContext),
		   matches.count > 0,
		   let styleExtension = matches.first?.extension,
		   let style = styleExtension.provideObject(for: matchContext) as? ThemeStyle {
			return style
		}

		return nil
	}

	static public var availableStyles : [ThemeStyle]? {
		let matchContext = OCExtensionContext(location: OCExtensionLocation(ofType: .themeStyle, identifier: nil), requirements: nil, preferences: nil)

		if let matches : [OCExtensionMatch] = try? OCExtensionManager.shared.provideExtensions(for: matchContext), matches.count > 0 {
			var styles : [ThemeStyle] = []

			for match in matches {
				if let style = match.extension.provideObject(for: matchContext) as? ThemeStyle {
					styles.append(style)
				}
			}

			return styles
		}

		return nil
	}

	static public func registerDefaultStyles() {
		if VendorServices.shared.isBranded, let brandingURL = VendorServices.shared.brandingURL {
			let themeProvider = ThemeProvider(plist: brandingURL)

			var isDefault = true
			for theme in themeProvider.themes {
				let themeExtension = theme.themeStyleExtension(isDefault: isDefault)
				OCExtensionManager.shared.addExtension(themeExtension)
				isDefault = false
			}
		} else {
			OCExtensionManager.shared.addExtension(ThemeStyle.ownCloudLight.themeStyleExtension())
			OCExtensionManager.shared.addExtension(ThemeStyle.ownCloudDark.themeStyleExtension(isDefault: true))
			OCExtensionManager.shared.addExtension(ThemeStyle.ownCloudClassic.themeStyleExtension())
		}
	}

	static public func availableStyles(for styles: [ThemeCollectionStyle]) -> [ThemeStyle]? {
		let styles = ThemeStyle.availableStyles?.filter { (theme) -> Bool in
			if styles.contains(theme.themeStyle) {
				return true
			}

			return false
		}

		return styles
	}
}

extension OCExtensionType {
	static let themeStyle: OCExtensionType  =  OCExtensionType("app.themeStyle")
}

struct ThemeStyleFeatureKeys {
	static let localizedName: String = "localizedName"
	static let isDefault: String = "isDefault"
	static let isBranding: String = "isBranding"
}
