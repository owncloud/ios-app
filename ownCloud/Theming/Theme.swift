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

enum ThemeEvent {
	case initial
	case update
}

protocol Themeable : class {
	func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent)
}

typealias ThemeApplier = (_ theme : Theme, _ ThemeCollection: ThemeCollection, _ event: ThemeEvent) -> Void
typealias ThemeApplierToken = Int

class Theme: NSObject {
	private var clients : [Themeable] = []

	private var appliers : [ThemeApplierToken : ThemeApplier] = [:]
	private var applierSerial : ThemeApplierToken = 0

	private var images : [String : ThemeImage] = [:]

	private var _activeCollection : ThemeCollection = ThemeCollection.defaultCollection

	// MARK: - Properties
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
	static var shared : Theme = {
		let sharedInstance = Theme()

		return (sharedInstance)
	}()

	// MARK: - Client register / unregister
	func register(client: Themeable, applyImmediately: Bool = true) {
		OCSynchronized(self) {
			clients.append(client)
		}

		if applyImmediately {
			client.applyThemeCollection(theme: self, collection: self.activeCollection, event: .initial)
		}
	}

	func unregister(client : Themeable) {
		OCSynchronized(self) {
			if let clientIndex = clients.index(where: { (themable) -> Bool in
				return themable === client
			}) {
				clients.remove(at: clientIndex)
			}
		}
	}

	// MARK: - Images
	func add(imageFor identifier: String, _ themeImageCreationBlock: (() -> ThemeImage)) {
		OCSynchronized(self) {
			if images[identifier] == nil {
				self.add(image: themeImageCreationBlock())
			}
		}
	}

	func add(image: ThemeImage) {
		OCSynchronized(self) {
			clients.insert(image, at: 0)

			if image.identifier != nil {
				images[image.identifier!] = image
			}
		}
	}

	func themeImage(for identifier: String) -> ThemeImage? {
		var image : ThemeImage? = nil

		OCSynchronized(self) {
			image = images[identifier]
		}

		return image
	}

	func image(for identifier: String) -> UIImage? {
		var image : UIImage? = nil

		OCSynchronized(self) {
			if let themeImage = images[identifier] {
				image = themeImage.image(for: self)
			}
		}

		return image
	}

	func remove(image: ThemeImage) {
		OCSynchronized(self) {
			if image.identifier != nil {
				images.removeValue(forKey: image.identifier!)
			}

			self.unregister(client: image)
		}
	}

	// MARK: - Applier register / unregister
	func add(applier: @escaping ThemeApplier, applyImmediately: Bool = true) -> ThemeApplierToken {
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

	func get(applierForToken: ThemeApplierToken?) -> ThemeApplier? {
		var applier : ThemeApplier?

		if applierForToken != nil {
			OCSynchronized(self) {
				applier = appliers[applierForToken!]
			}
		}

		return applier
	}

	func remove(applierForToken: ThemeApplierToken?) {
		if applierForToken != nil {
			OCSynchronized(self) {
				appliers.removeValue(forKey: applierForToken!)
			}
		}
	}

	// MARK: - Theme client notification
	func applyThemeCollection(_ collection: ThemeCollection) {
		OCSynchronized(self) {
			// Apply theme to clients
			for client in clients {
				client.applyThemeCollection(theme: self, collection: collection, event: .update)
			}

			// Apply theme via appliers
			for (_, applier) in appliers {
				applier(self, collection, .update)
			}
		}
	}
}
