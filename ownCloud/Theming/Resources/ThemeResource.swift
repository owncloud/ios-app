//
//  ThemeResource.swift
//  ownCloud
//
//  Created by Felix Schwarz on 12.04.18.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

import UIKit

typealias ThemeResourceIdentifier = String

class ThemeResource : NSObject {
	var identifier : ThemeResourceIdentifier?

	private var _sourceResource : Any?
	var sourceResource : Any? {
		set(resource) {
			OCSynchronized(self) {
				_sourceResource = resource
			}
		}

		get {
			OCSynchronized(self) {
				if _sourceResource == nil {
					_sourceResource = self.load()
				}
			}

			return _sourceResource
		}
	}

	/// Synchronous way to retrieve the resource, with all computations applied
	private var _resource : Any?
	func resource(for theme: Theme) -> Any? {
		var result : Any?

		OCSynchronized(self) {
			if _resource == nil {
				_resource = applyThemeToResource(theme: theme, collection: theme.activeCollection, source: self.sourceResource)
			}

			result = _resource
		}

		return result
	}

	/// Asynchronous way to retrieve the resource on the main thread, with all computations applied. If the resource is already available, the completion handler will be called immediately (on the thread it was called from).
	func asyncResource(for theme: Theme, _ completion: @escaping ((_ resource : Any?) -> Void)) {
		OCSynchronized(self) {
			if _resource != nil {
				completion(_resource)
			} else {
				DispatchQueue.global(qos: .userInteractive).async {
					let requestedResource : Any? = self.resource(for: theme)

					DispatchQueue.main.async {
						completion(requestedResource)
					}
				}
			}
		}
	}

	/// Received a memory warning from the OS => free as much memory as possible
	func didReceiveMemoryWarning() {
		OCSynchronized(self) {
			_sourceResource = nil
			_resource = nil
		}
	}

	/// Called when the resource has not yet been loaded into memory. Implementations are expected to load the resource and return it (subclass this)
	func load() -> Any? {
		return nil
	}

	/// Called when no themed version of the resource has yet been created (subclass this)
	func applyThemeToResource(theme: Theme, collection: ThemeCollection, source: Any?) -> Any? {
		return source
	}
}

extension ThemeResource : Themeable {
	func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		OCSynchronized(self) {
			_resource = nil
		}
	}
}
