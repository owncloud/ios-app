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
	func showReveal(at path: IndexPath) -> Bool
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

public enum ClientItemInteraction {
	case selection
	case contextMenu
	case leadingSwipe
	case trailingSwipe
}

public class ClientContext: NSObject {
	public typealias PermissionHandler = (_ context: ClientContext?, _ dataItemRecord: OCDataItemRecord?, _ checkInteraction: ClientItemInteraction) -> Bool

	public weak var parent: ClientContext?

	// MARK: - Core
	public weak var core: OCCore?

	// MARK: - Drive
	public var drive: OCDrive?
	public weak var query: OCQuery?

	// MARK: - Item
	public var initialRootItem : OCItem?

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

	public var permissionHandler : PermissionHandler?
	public var permissions : [ClientItemInteraction]?

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

		permissions = inParent?.permissions
		permissionHandler = inParent?.permissionHandler

		modifier?(self)
	}

	public func postInitialize(owner: Any?) {
		postInitializationModifier?(owner, self)
		postInitializationModifier = nil
	}

	public func validate(permission: ClientItemInteraction, for record: OCDataItemRecord) -> Bool {
		if let permissions = permissions {
			if !permissions.contains(permission) {
				return false
			}
		}

		if let permissionHandler = permissionHandler {
			return permissionHandler(self, record, permission)
		}

		return true
	}
}
