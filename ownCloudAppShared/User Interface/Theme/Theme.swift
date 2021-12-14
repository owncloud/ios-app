//
//  Theme.swift
//  ownCloud
//
//  Created by Felix Schwarz on 10.04.18.
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
import ownCloudSDK

public enum ThemeEvent {
	case initial
	case update
}

public protocol Themeable : class {
	func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent)
}

public typealias ThemeApplier = (_ theme : Theme, _ ThemeCollection: ThemeCollection, _ event: ThemeEvent) -> Void
public typealias ThemeApplierToken = Int

final class WeakThemeable {
	weak var weakClient : Themeable?

	init(_ client: Themeable) {
		weakClient = client
	}
}

public class Theme: NSObject {
	private var weakClients : [WeakThemeable] = []

	private var appliers : [ThemeApplierToken : ThemeApplier] = [:]
	private var applierSerial : ThemeApplierToken = 0

	private var resourcesByIdentifier : [String : ThemeResource] = [:]

	// MARK: - Properties
	internal var _activeCollection : ThemeCollection = ThemeCollection.defaultCollection
	public var activeCollection : ThemeCollection {
		set(newCollection) {
			_activeCollection = newCollection
			self.applyThemeCollection(_activeCollection)
		}
		get {
			return _activeCollection
		}
	}

	// MARK: - Shared instance
	public static var shared : Theme = {
		let sharedInstance = Theme()

		OCExtensionManager.shared.addExtension(OCExtension.license(withIdentifier: "license.PocketSVG", bundleOf: Theme.self, title: "PocketSVG", resourceName: "PocketSVG", fileExtension: "LICENSE"))

		return sharedInstance
	}()

	// MARK: - Client register / unregister
	public func register(client: Themeable, applyImmediately: Bool = true) {
		OCSynchronized(self) {
			weakClients.append(WeakThemeable(client))
		}

		if applyImmediately {
			client.applyThemeCollection(theme: self, collection: self.activeCollection, event: .initial)
		}
	}

	public func unregister(client : Themeable) {
		OCSynchronized(self) {
			if let clientIndex = weakClients.index(where: { (themable) -> Bool in
				if themable.weakClient != nil {
					return themable.weakClient === client
				}
				return false
			}) {
				weakClients.remove(at: clientIndex)
			}
		}
	}

	// MARK: - Resources
	public func add(resourceFor identifier: String, _ resourceCreationBlock: ((_ identifier: String) -> ThemeResource)) {
		OCSynchronized(self) {
			if resourcesByIdentifier[identifier] == nil {
				self.add(resource: resourceCreationBlock(identifier))
			}
		}
	}

	public func add(resource: ThemeResource) {
		OCSynchronized(self) {
			weakClients.insert(WeakThemeable(resource), at: 0)

			if resource.identifier != nil {
				resourcesByIdentifier[resource.identifier!] = resource
			}
		}
	}

	public func resource(for identifier: String) -> ThemeResource? {
		var resource : ThemeResource?

		OCSynchronized(self) {
			resource = resourcesByIdentifier[identifier]
		}

		return resource
	}

	public func image(for identifier: String, size: CGSize? = nil) -> UIImage? {
		var image : UIImage?

		OCSynchronized(self) {
			if let themeResource = resourcesByIdentifier[identifier] {
				if themeResource.isKind(of: ThemeTVGResource.self) {
					if size != nil {
						if let tvgResource : ThemeTVGResource = themeResource as? ThemeTVGResource {
							image = tvgResource.vectorImage(for: self)?.rasteredImage(fitInSize: size!, with: activeCollection.iconColors, cacheFor: self.activeCollection.identifier)
						}
					}
				}
			}
		}

		if image == nil {
			Log.warning("Theme received request for image \(identifier), but none such image is registered")
		}

		return image
	}

	public func tvgImage(for identifier: String) -> TVGImage? {
		var image : TVGImage?

		OCSynchronized(self) {
			if let themeResource = resourcesByIdentifier[identifier] {
				if themeResource.isKind(of: ThemeTVGResource.self) {
					if let tvgResource : ThemeTVGResource = themeResource as? ThemeTVGResource {
						image = tvgResource.tvgImage()
					}
				}
			}
		}

		return image
	}

	public func remove(resource: ThemeResource) {
		OCSynchronized(self) {
			if resource.identifier != nil {
				resourcesByIdentifier.removeValue(forKey: resource.identifier!)
			}

			self.unregister(client: resource)
		}
	}

	// MARK: - Convenience resource methods
	public func add(tvgResourceFor tvgName: String) {
		self.add(resourceFor: tvgName) { (identifier) -> ThemeResource in
			return ThemeTVGResource(name: tvgName, identifier: identifier)
		}
	}

	// MARK: - Applier register / unregister
	public func add(applier: @escaping ThemeApplier, applyImmediately: Bool = true) -> ThemeApplierToken {
		var token : ThemeApplierToken = -1

		OCSynchronized(self) {
			token = applierSerial
			appliers[token] = applier
			applierSerial += 1
		}

		if applyImmediately {
			applier(self, self.activeCollection, .initial)
		}

		return token
	}

	public func get(applierForToken: ThemeApplierToken?) -> ThemeApplier? {
		var applier : ThemeApplier?

		if applierForToken != nil {
			OCSynchronized(self) {
				applier = appliers[applierForToken!]
			}
		}

		return applier
	}

	public func remove(applierForToken: ThemeApplierToken?) {
		if applierForToken != nil {
			OCSynchronized(self) {
				appliers.removeValue(forKey: applierForToken!)
			}
		}
	}

	// MARK: - Theme client notification
	public func applyThemeCollection(_ collection: ThemeCollection) {
		OCSynchronized(self) {
			// Apply theme to clients
			for client in weakClients {
				if client.weakClient != nil {
					client.weakClient?.applyThemeCollection(theme: self, collection: collection, event: .update)
				}
			}

			// Apply theme via appliers
			for (_, applier) in appliers {
				applier(self, collection, .update)
			}

			// Globally change color values for UI elements
			if #available(iOS 13, *) {
			} else {
				UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).backgroundColor = collection.searchBarColors.backgroundColor
				UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).defaultTextAttributes = [NSAttributedString.Key.foregroundColor: collection.searchBarColors.secondaryLabelColor]
				UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).tintColor = collection.searchBarColors.tintColor
			}
			UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).keyboardAppearance = collection.keyboardAppearance
			if #available(iOS 13, *) {
				if VendorServices.shared.isBranded {
					UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = .black
				} else {
					UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = collection.tintColor
				}
			} else {
				UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = .black
			}
			UITextField.appearance().tintColor = collection.searchBarColors.tintColor
		}
	}

	// MARK: - Theme switching
	public func switchThemeCollection(_ collection: ThemeCollection) {
		UIView.animate(withDuration: 0.25) {
			CATransaction.begin()
			CATransaction.setAnimationDuration(0.25)
			self.activeCollection = collection
			CATransaction.commit()
		}
	}
}
