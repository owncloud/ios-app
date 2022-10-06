//
//  ClientContext.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 25.04.22.
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

// ClientContext:
// - used to encapsulate and pass around all important API / UI objects to all parts of the UI
// - allow customization for specific purposes through primitive "inheritance"
// - can be passed around "strongly" while storing OCCore reference "weakly" (structural barrier to accidential retains)

public protocol OpenItemAction : AnyObject {
	@discardableResult func open(item: OCDataItem, context: ClientContext, animated: Bool, pushViewController: Bool) -> UIViewController?
}

public protocol ViewItemAction : AnyObject {
	@discardableResult func provideViewer(for item: OCDataItem, context: ClientContext) -> UIViewController?
}

public protocol MoreItemAction : AnyObject {
	@discardableResult func moreOptions(for item: OCDataItem, at location: OCExtensionLocationIdentifier, context: ClientContext, sender: AnyObject?) -> Bool
}

public protocol ActionProgressHandlerProvider : AnyObject {
	func makeActionProgressHandler() -> ActionProgressHandler
}

public protocol RevealItemAction : AnyObject {
	@discardableResult func reveal(item: OCDataItem, context: ClientContext, sender: AnyObject?) -> Bool
}

public protocol ContextMenuProvider : AnyObject {
	func composeContextMenuElements(for viewController: UIViewController, item: OCDataItem, location: OCExtensionLocationIdentifier, context: ClientContext, sender: AnyObject?) -> [UIMenuElement]?
}

@objc public protocol SwipeActionsProvider : AnyObject {
	@objc optional func provideLeadingSwipeActions(for viewController: UIViewController, item: OCDataItem, context: ClientContext?) -> UISwipeActionsConfiguration?
	@objc optional func provideTrailingSwipeActions(for viewController: UIViewController, item: OCDataItem, context: ClientContext?) -> UISwipeActionsConfiguration?
}

public protocol InlineMessageCenter : AnyObject {
	func hasInlineMessage(for item: OCItem) -> Bool
	func showInlineMessageFor(item: OCItem)
}

//extension ClientContext {
//	public enum DropSessionStage : CaseIterable {
//		case begin
//		case updated
//		case end
//	}
//}

@objc public protocol DropTargetsProvider : AnyObject {
	func canProvideDropTargets(for dropSession: UIDropSession, target view: UIView) -> Bool
	func provideDropTargets(for dropSession: UIDropSession, target view: UIView) -> [OCDataItem & OCDataItemVersioning]?
	@objc optional func cleanupDropTargets(for: UIDropSession, target view: UIView)
}

public enum ClientItemInteraction {
	case selection
	case multiselection
	case contextMenu
	case leadingSwipe
	case trailingSwipe
	case drag
	case acceptDrop
}

public class ClientContext: NSObject {
	public typealias PermissionHandler = (_ context: ClientContext?, _ dataItemRecord: OCDataItemRecord?, _ checkInteraction: ClientItemInteraction) -> Bool

	public weak var parent: ClientContext?

	// MARK: - Core
	public weak var core: OCCore?

	// MARK: - Drive
	public var drive: OCDrive?
	public weak var query: OCQuery?

	// MARK: - Items
	public var rootItem : OCDataItem?

	// MARK: - UI objects
	public weak var rootViewController: UIViewController?
	public weak var navigationController: UINavigationController? // Navigation controller to push to
	public weak var originatingViewController: UIViewController? // Originating view controller for f.ex. actions

	public weak var progressSummarizer: ProgressSummarizer?
	public weak var actionProgressHandlerProvider: ActionProgressHandlerProvider?

	// MARK: - UI item handling
	public weak var openItemHandler: OpenItemAction?
	public weak var viewItemHandler: ViewItemAction?
	public weak var moreItemHandler: MoreItemAction?
	public weak var revealItemHandler: RevealItemAction?
	public weak var contextMenuProvider: ContextMenuProvider?
	public weak var swipeActionsProvider: SwipeActionsProvider?
	public weak var inlineMessageCenter: InlineMessageCenter?
	public weak var dropTargetsProvider: DropTargetsProvider?

	// MARK: - Permissions
	public var permissionHandlers : [PermissionHandler]?
	public var permissions : [ClientItemInteraction]?

	// MARK: - Display options
	@objc public dynamic var sortDescriptor: SortDescriptor?
	/*
	public var sortMethod : SortMethod? {
		didSet {
			notifyObservers(ofChanged: .sortMethod)
		}
	}
	public var sortDirection: SortDirection? {
		didSet {
			notifyObservers(ofChanged: .sortDirection)
		}
	}
	*/

	// MARK: - Post Initialization Modifier
	// allows postponing of a client context passed into another object until the object it is passed into is initialized and can be referenced
	public typealias PostInitializationModifier = (_ owner: Any?, _ context: ClientContext) -> Void
	public var postInitializationModifier: PostInitializationModifier?

	public init(with inParent: ClientContext? = nil, core inCore: OCCore? = nil, drive inDrive: OCDrive? = nil, rootViewController inRootViewController : UIViewController? = nil, originatingViewController inOriginatingViewController: UIViewController? = nil, navigationController inNavigationController: UINavigationController? = nil, progressSummarizer inProgressSummarizer: ProgressSummarizer? = nil, modifier: ((_ context: ClientContext) -> Void)? = nil) {
		super.init()

		parent = inParent

		core = inCore ?? inParent?.core

		drive = inDrive ?? inParent?.drive
		query = inParent?.query

		rootViewController = inRootViewController ?? inParent?.rootViewController
		navigationController = inNavigationController ?? inParent?.navigationController
		originatingViewController = inOriginatingViewController ?? inParent?.originatingViewController

		progressSummarizer = inProgressSummarizer ?? inParent?.progressSummarizer
		actionProgressHandlerProvider = inParent?.actionProgressHandlerProvider

		openItemHandler = inParent?.openItemHandler
		viewItemHandler = inParent?.viewItemHandler
		moreItemHandler = inParent?.moreItemHandler
		revealItemHandler = inParent?.revealItemHandler
		contextMenuProvider = inParent?.contextMenuProvider
		swipeActionsProvider = inParent?.swipeActionsProvider
		inlineMessageCenter = inParent?.inlineMessageCenter
		dropTargetsProvider = inParent?.dropTargetsProvider

		sortDescriptor = inParent?.sortDescriptor

		permissions = inParent?.permissions
		permissionHandlers = inParent?.permissionHandlers

		modifier?(self)
	}

	public func postInitialize(owner: Any?) {
		postInitializationModifier?(owner, self)
		postInitializationModifier = nil
	}

	// MARK: - Change observation
	// (for properties that aren't KVO-observable)
	public enum Property : CaseIterable {
		case sortMethod
		case sortDirection
	}
	public typealias PropertyChangeHandler = (_ context: ClientContext, _ property: Property) -> Void
	public typealias PropertyObserverUUID = UUID
	struct PropertyObserver {
		var properties: [Property]
		var changeHandler: PropertyChangeHandler
		var uuid: PropertyObserverUUID
	}
	var propertyObservers : [PropertyObserver] = []
	public func addObserver(for properties: [Property], initial: Bool = false, with handler: @escaping PropertyChangeHandler) -> PropertyObserverUUID {
		let observer = PropertyObserver(properties: properties, changeHandler: handler, uuid: UUID())

		if initial {
			for property in properties {
				observer.changeHandler(self, property)
			}
		}

		propertyObservers.append(observer)

		return observer.uuid
	}
	public func removeObserver(with uuid: PropertyObserverUUID?) {
		if let uuid = uuid {
			propertyObservers.removeAll(where: { observer in (observer.uuid == uuid) })
		}
	}
	public func notifyObservers(ofChanged property: Property) {
		for observer in propertyObservers {
			if observer.properties.contains(property) {
				observer.changeHandler(self, property)
			}
		}
	}

	// MARK: - Permissions
	public func hasPermission(for interaction: ClientItemInteraction) -> Bool {
		if let permissions = permissions {
			if !permissions.contains(interaction) {
				return false
			}
		}

		return true
	}

	public func add(permissionHandler: @escaping PermissionHandler) {
		if permissionHandlers == nil {
			permissionHandlers = []
		}

		permissionHandlers?.append(permissionHandler)
	}

	public func validate(interaction: ClientItemInteraction, for record: OCDataItemRecord) -> Bool {
		if let permissions = permissions {
			if !permissions.contains(interaction) {
				return false
			}
		}

		if let permissionHandlers = permissionHandlers {
			var allowed = true

			for permissionHandler in permissionHandlers {
				if !permissionHandler(self, record, interaction) {
					allowed = false
					break
				}
			}

			return allowed
		}

		return true
	}
}