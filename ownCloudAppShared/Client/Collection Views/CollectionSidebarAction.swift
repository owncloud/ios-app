//
//  CollectionSidebarAction.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 23.11.22.
//  Copyright © 2022 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2022, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import UIKit
import ownCloudSDK

public extension OCActionRunOptionKey {
	static let clientContext = OCActionRunOptionKey(rawValue: "clientContext")
}

public extension OCActionPropertyKey {
	static let supportsDrop = OCActionPropertyKey(rawValue: "supportsDrop")
	static let buttonLabel = OCActionPropertyKey(rawValue: "buttonLabel")
	static let selectable = OCActionPropertyKey(rawValue: "selectable")
}

extension OCAction {
	var supportsDrop: Bool {
		get {
			return properties[.supportsDrop] as? Bool ?? false
		}

		set {
			properties[.supportsDrop] = newValue
		}
	}

	var selectable: Bool {
		get {
			return properties[.selectable] as? Bool ?? true
		}

		set {
			properties[.selectable] = newValue
		}
	}

	var buttonLabel: String? {
		get {
			return properties[.buttonLabel] as? String
		}

		set {
			properties[.buttonLabel] = newValue
		}
	}
}

open class CollectionSidebarAction: OCAction {
	open override var dataItemVersion: OCDataItemVersion {
		return "\(dataItemReference)\(title)\(badgeCount ?? 0)" as NSObject
	}

	public typealias ViewControllerProvider = (_ context: ClientContext?, _ action: CollectionSidebarAction) -> UIViewController?

	var cacheViewControllers: Bool = false
	var clearCachedViewControllerOnConnectionClose: Bool = true
	var viewControllerProvider: ViewControllerProvider?
	var viewControllersByRootViewController: NSMapTable<UIViewController, UIViewController> = NSMapTable.weakToStrongObjects()

	public var badgeCount: Int?

	public init(with title: String, icon: UIImage?, identifier: OCDataItemReference? = nil, viewControllerProvider: @escaping ViewControllerProvider, cacheViewControllers: Bool = true, clearCachedViewControllerOnConnectionClose: Bool = true) {
		self.viewControllerProvider = viewControllerProvider
		self.cacheViewControllers = cacheViewControllers
		self.clearCachedViewControllerOnConnectionClose = clearCachedViewControllerOnConnectionClose
		super.init()
		if let identifier = identifier as? String {
			self.identifier = identifier
		}
		self.title = title
		self.icon = icon
	}

	open override func run(options: [OCActionRunOptionKey : Any]? = nil, completionHandler: ((Error?) -> Void)? = nil) {
		_ = openItem(from: nil, with: options?[.clientContext] as? ClientContext, animated: true, pushViewController: true, completion: { success in
			completionHandler?(nil)
		})
	}

	public func openItem(from viewController: UIViewController?, with context: ClientContext?, animated: Bool, pushViewController: Bool, completion: ((Bool) -> Void)?) -> UIViewController? {
		var viewController: UIViewController?

		if let clientContext = context {
			if cacheViewControllers, let rootViewController = clientContext.rootViewController {
				viewController = viewControllersByRootViewController.object(forKey: rootViewController)
			}

			if viewController == nil {
				viewController = viewControllerProvider?(clientContext, self)

				if cacheViewControllers, let rootViewController = clientContext.rootViewController {
					viewControllersByRootViewController.setObject(viewController, forKey: rootViewController)

					if let bookmarkUUID = context?.accountConnection?.bookmark.uuid, clearCachedViewControllerOnConnectionClose {
						// Clear from cache if connection is closed (otherwise navigation revocation won't work after a disconnect/reconnect)
						NavigationRevocationAction(triggeredBy: [.connectionClosed(bookmarkUUID: bookmarkUUID)], action: { [weak rootViewController, weak self] event, action in
							if let self, let rootViewController {
								self.viewControllersByRootViewController.removeObject(forKey: rootViewController)
							}
						}).register(for: viewController, globally: true)
					}
				}
			}

			if viewController != nil {
				viewController = clientContext.pushViewControllerToNavigation(context: clientContext, provider: { context in
					return viewController
				}, push: pushViewController, animated: animated)

				completion?(true)

				return viewController
			}
		}

		completion?(false)

		return nil
	}

	open var childrenDataSource: OCDataSource?

	open override func hasChildren(using source: OCDataSource) -> Bool {
		return childrenDataSource != nil
	}

	open override func dataSourceForChildren(using source: OCDataSource) -> OCDataSource? {
		return childrenDataSource
	}
}
