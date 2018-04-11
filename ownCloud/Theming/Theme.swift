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
	var clients : [Themeable] = []
	var clientBlocks : [Int : ThemeApplier] = [:]
	var clientSerial : Int = 0
	var _activeCollection : ThemeCollection = ThemeCollection.defaultCollection

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

	// MARK: - Applier register / unregister
	func add(applier: @escaping ThemeApplier, applyImmediately: Bool = true) -> ThemeApplierToken {
		var token : ThemeApplierToken = -1

		OCSynchronized(self) {
			token = clientSerial
			clientBlocks[token] = applier
			clientSerial += 1
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
				applier = clientBlocks[applierForToken!]
			}
		}

		return applier
	}

	func remove(applierForToken: ThemeApplierToken?) {
		if applierForToken != nil {
			OCSynchronized(self) {
				clientBlocks.removeValue(forKey: applierForToken!)
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
			for (_, applier) in clientBlocks {
				applier(self, collection, .update)
			}
		}
	}
}
