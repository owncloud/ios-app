//
//  Action.swift
//  ownCloud
//
//  Created by Pablo Carrascal on 30/10/2018.
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
import ownCloudApp

public enum ActionCategory {
	case normal
	case destructive
	case informal
	case edit
	case save
}

public enum ActionPosition : Int {
	case none = -1

	case first = 100
	case nearFirst = 150
	case beforeMiddle = 200
	case middle = 300
	case afterMiddle = 400
	case last = 500

	static public func between(_ position1: ActionPosition, and position2: ActionPosition) -> ActionPosition {
		return ActionPosition(rawValue: ((position1.rawValue + position2.rawValue)/2))!
	}

	public func shift(by offset: Int) -> ActionPosition {
		return ActionPosition(rawValue: self.rawValue + offset)!
	}
}

public typealias ActionCompletionHandler = ((Action, Error?) -> Void)
public typealias ActionProgressHandler = ((Progress, Bool) -> Void)
public typealias ActionWillRunHandler = ((@escaping () -> Void) -> Void)

public extension OCExtensionType {
	static let action: OCExtensionType  =  OCExtensionType("app.action")
}

public extension OCExtensionLocationIdentifier {
	static let tableRow: OCExtensionLocationIdentifier = OCExtensionLocationIdentifier("tableRow") //!< Present as table row action
	static let moreItem: OCExtensionLocationIdentifier = OCExtensionLocationIdentifier("moreDetailItem") //!< Present in "more" card view for a single item in detail view
	static let moreDetailItem: OCExtensionLocationIdentifier = OCExtensionLocationIdentifier("moreItem") //!< Present in "more" card view for a single item
	static let moreFolder: OCExtensionLocationIdentifier = OCExtensionLocationIdentifier("moreFolder") //!< Present in "more" options for a whole folder
	static let toolbar: OCExtensionLocationIdentifier = OCExtensionLocationIdentifier("toolbar") //!< Present in a toolbar
	static let folderAction: OCExtensionLocationIdentifier = OCExtensionLocationIdentifier("folderAction") //!< Present in the alert sheet when the folder action bar button is pressed
	static let keyboardShortcut: OCExtensionLocationIdentifier = OCExtensionLocationIdentifier("keyboardShortcut") //!< Currently used for UIKeyCommand
	static let contextMenuItem: OCExtensionLocationIdentifier = OCExtensionLocationIdentifier("contextMenuItem") //!< Used in UIMenu
	static let contextMenuSharingItem: OCExtensionLocationIdentifier = OCExtensionLocationIdentifier("contextMenuSharingItem") //!< Used in UIMenu
}

public class ActionExtension: OCExtension {
	// MARK: - Custom Instance Properties.
	public var name: String
	public var category: ActionCategory
	public var keyCommand: String?
	public var keyModifierFlags: UIKeyModifierFlags?

	// MARK: - Init & Deinit
	public init(name: String, category: ActionCategory = .normal, identifier: OCExtensionIdentifier, locations: [OCExtensionLocationIdentifier]?, features: [String : Any]?, objectProvider: OCExtensionObjectProvider?, customMatcher: OCExtensionCustomContextMatcher?, keyCommand: String?, keyModifierFlags: UIKeyModifierFlags?) {

		self.name = name
		self.category = category
		self.keyCommand = keyCommand
		self.keyModifierFlags = keyModifierFlags

		super.init(identifier: identifier, type: .action, locations: locations, features: features, objectProvider: objectProvider, customMatcher: customMatcher)
	}
}

extension Array where Element: OCItem {
	var sharedWithUser : [OCItem] {
		return self.filter({ (item) -> Bool in return item.isSharedWithUser })
	}
	var isShared : [OCItem] {
		return self.filter({ (item) -> Bool in return item.isShared })
	}
}

public class ActionContext: OCExtensionContext {
	// MARK: - Custom Instance Properties.
	weak public var viewController: UIViewController?
	weak public var core: OCCore?
	weak public var query: OCQuery?
	weak public var sender: AnyObject?

	private var rootItems: Int = 0
	private var moveableItems: Int = 0
	private var deleteableItems: Int = 0
	private var cachedSharedItems = [OCItem]()
	private var cachedParentFolders = [OCLocalID : OCItem]()
	private var itemStorage: [OCItem]

	public var items: [OCItem] {
		get {
			return itemStorage
		}
	}

	public var itemsSharedWithUser: [OCItem] {
		return cachedSharedItems
	}

	public var containsRoot: Bool {
		return rootItems > 0
	}

	public var allItemsDeleteable: Bool {
		return items.count == deleteableItems
	}

	public var allItemsMoveable: Bool {
		return items.count == moveableItems
	}

	public var allItemsShared: Bool {
		return self.items.count == self.cachedSharedItems.count
	}

	public var containsShareRoot : Bool {

		guard self.itemsSharedWithUser.count > 0 else { return false }

		for sharedItem in self.itemsSharedWithUser {

			if isShareRoot(item: sharedItem) {
				return true
			}
		}

		return false
	}

	// MARK: - Init & Deinit.
	public init(viewController: UIViewController, core: OCCore, query: OCQuery? = nil, items: [OCItem], location: OCExtensionLocation, sender: AnyObject? = nil, requirements: [String : Any]? = nil, preferences: [String : Any]? = nil) {

		itemStorage = items

		super.init()

		self.viewController = viewController
		self.sender = sender
		self.core = core
		self.location = location

		self.query = query
		self.requirements = requirements
		self.preferences = preferences

		updateCaches()
	}

	public func replace(items:[OCItem]) {
		self.itemStorage = items
		updateCaches()
	}

	public func removeAllItems() {
		self.itemStorage.removeAll()
		updateCaches()
	}

	public func remove(item:OCItem) {
		guard self.itemStorage.contains(item) else {
			return
		}
		self.itemStorage.removeAll(where: {$0.localID == item.localID})

		if item.isSharedWithUser {
			self.cachedSharedItems.removeAll(where: { $0.localID == item.localID })
		}

		if item.isRoot, rootItems > 0 {
			rootItems -= 1
		}

		if item.permissions.contains(.delete), deleteableItems > 0 {
			deleteableItems -= 1
		}

		if item.permissions.contains(.move), deleteableItems > 0 {
			moveableItems -= 1
		}
	}

	public func add(item:OCItem) {

		guard !self.itemStorage.contains(item) else {
			return
		}

		self.itemStorage.append(item)

		if item.isSharedWithUser {
			self.cachedSharedItems.append(item)
		}

		if item.isRoot {
			rootItems += 1
		}

		if item.permissions.contains(.delete) {
			deleteableItems += 1
		}

		if item.permissions.contains(.move) {
			moveableItems += 1
		}
	}

	public func parent(for item:OCItem) -> OCItem? {
		var parent: OCItem?
		guard let localID = item.parentLocalID as OCLocalID? else { return nil }

		parent = cachedParentFolders[localID]

		if parent != nil {
			return parent
		}

		if parent == nil, let core = self.core {
			parent = item.parentItem(from: core)
			self.cachedParentFolders[localID] = parent
		}

		return parent
	}

	public func isShareRoot(item:OCItem) -> Bool {
		guard item.isSharedWithUser else { return false }

		guard let parent = parent(for: item) else { return true }

		return !parent.isSharedWithUser
	}

	private func updateCaches() {
		cachedSharedItems = itemStorage.sharedWithUser
		rootItems = itemStorage.filter({ $0.isRoot }).count
		deleteableItems = itemStorage.filter({$0.permissions.contains(.delete)}).count
		moveableItems = itemStorage.filter({$0.permissions.contains(.move)}).count
	}
}

open class Action : NSObject {
	// MARK: - Extension metadata
	class open var identifier : OCExtensionIdentifier? { return nil }
	class open var category : ActionCategory? { return .normal }
	class open var name : String? { return nil }
	class open var keyCommand : String? { return nil }
	class open var keyModifierFlags : UIKeyModifierFlags? { return nil }
	class open var locations : [OCExtensionLocationIdentifier]? { return nil }
	class open var features : [String : Any]? { return nil }

	// MARK: - Extension creation
	class open var actionExtension : ActionExtension {
		let objectProvider : OCExtensionObjectProvider = { (_ rawExtension, _ context, _ error) -> Any? in
			if let actionExtension = rawExtension as? ActionExtension,
				let actionContext   = context as? ActionContext {
				return self.init(for: actionExtension, with: actionContext)
			}

			return nil
		}

		let customMatcher : OCExtensionCustomContextMatcher  = { (context, priority) -> OCExtensionPriority in

			// Make sure we have valid context and extension was not filtered out due to location mismatch
			guard let actionContext = context as? ActionContext, priority != .noMatch else {
				return priority
			}

			if self.applicablePosition(forContext: actionContext) == .none {
				// Exclude actions whose applicablePosition returns .none
				return .noMatch
			}

			return priority

			// Additional filtering (f.ex. via OCClassSettings, Settings) goes here
		}

		return ActionExtension(name: name!, category: category!, identifier: identifier!, locations: locations, features: features, objectProvider: objectProvider, customMatcher: customMatcher, keyCommand: keyCommand, keyModifierFlags: keyModifierFlags)
	}

	// MARK: - Extension matching
	class open func applicablePosition(forContext: ActionContext) -> ActionPosition {
		return .middle
	}

	// MARK: - Finding actions
	class open func sortedApplicableActions(for context: ActionContext) -> [Action] {
		var sortedActions : [Action] = []

		if let matches = try? OCExtensionManager.shared.provideExtensions(for: context) {
			for match in matches {
				if let action = match.extension.provideObject(for: context) as? Action {
					sortedActions.append(action)
				}
			}
		}

		sortedActions.sort { (action1, action2) -> Bool in
			return action1.position.rawValue < action2.position.rawValue
		}

		return sortedActions
	}

	// MARK: - Action metadata
	open var context : ActionContext
	open var actionExtension: ActionExtension
	weak open var core : OCCore?

	// MARK: - Action creation
	required public init(for actionExtension: ActionExtension, with context: ActionContext) {
		self.actionExtension = actionExtension
		self.context = context
		self.core = context.core!

		super.init()
	}

	// MARK: - Execution metadata
	open var progressHandler : ActionProgressHandler?     // to be filled before calling run(), provideStaticRow(), provideContextualAction(), etc. if desired
	open var completionHandler : ActionCompletionHandler? // to be filled before calling run(), provideStaticRow(), provideContextualAction(), etc. if desired
	open var actionWillRunHandler: ActionWillRunHandler? // to be filled before calling run(), provideStaticRow(), provideContextualAction(), etc. if desired

	// MARK: - Action implementation
	@objc open func perform() {
		self.willRun({
			OnMainThread {
				self.run()
			}
		})
	}

	open func willRun(_ donePreparing: @escaping () -> Void) {

		if Thread.isMainThread == false {
			Log.warning("The Run method of the action \(Action.identifier!.rawValue) is not called inside the main thread")
		}

		if actionWillRunHandler != nil {
			actionWillRunHandler!(donePreparing)
		} else {
			donePreparing()
		}
	}

	@objc open func run() {
		completed()
	}

	open func completed(with error: Error? = nil) {
		if let completionHandler = completionHandler {
			completionHandler(self, error)
		}
	}

	open func publish(progress: Progress) {
		if let progressHandler = progressHandler {
			progressHandler(progress, true)
		}
	}

	open func unpublish(progress: Progress) {
		if let progressHandler = progressHandler {
			progressHandler(progress, false)
		}
	}

	// MARK: - Licensing
	class open var licenseRequirements : LicenseRequirements? { return nil }

	public var isLicensed : Bool {
		guard let core = self.core else {
			return false
		}

		if let licenseRequirements = type(of:self).licenseRequirements, !licenseRequirements.isUnlocked(for: core) {
			return false
		}

		return true
	}

	// MARK: - Action UI elements
	public static let staticRowImageWidth : CGFloat = 32
	private let proLabel = "ᴾᴿᴼ" // "🅿🆁🅾"

	open func provideStaticRow() -> StaticTableViewRow? {
		var name = actionExtension.name

		if !isLicensed {
			name += " " + proLabel
		}

		return StaticTableViewRow(buttonWithAction: { (_ row, _ sender) in
			self.perform()
		}, title: name, style: actionExtension.category == .destructive ? .destructive : .plain, image: nil, imageWidth: nil, alignment: .left, identifier: actionExtension.identifier.rawValue, accessoryView: UIImageView(image: self.icon))
	}

	open func provideContextualAction() -> UIContextualAction? {
		return UIContextualAction(style: actionExtension.category == .destructive ? .destructive : .normal, title: self.actionExtension.name, handler: { (_ action, _ view, _ uiCompletionHandler) in
			uiCompletionHandler(false)
			self.perform()
		})
	}

	@available(iOS 13.0, *)
	open func provideUIMenuAction() -> UIAction? {
		var attribute = UIMenuElement.Attributes(rawValue: 0)
		if actionExtension.category == .destructive {
			attribute = .destructive
		}
		return UIAction(title: self.actionExtension.name, image: self.icon, attributes: attribute) { _ in
			self.perform()
		}
	}

	open func provideAlertAction() -> UIAlertAction? {
		var name = actionExtension.name

		if !isLicensed {
			name += " " + proLabel
		}

		let alertAction = UIAlertAction(title: name, style: actionExtension.category == .destructive ? .destructive : .default, handler: { (_ alertAction) in
			self.perform()
		})

		if let image = self.icon?.paddedTo(width: 36, height: nil) {
			if alertAction.responds(to: NSSelectorFromString("setImage:")) {
				alertAction.setValue(image, forKey: "image")
			}
			if alertAction.responds(to: NSSelectorFromString("_setTitleTextAlignment:")) {
				alertAction.setValue(CATextLayerAlignmentMode.left, forKey: "titleTextAlignment")
			}
		}

		return alertAction
	}

	// MARK: - Action metadata
	class open func iconForLocation(_ location: OCExtensionLocationIdentifier) -> UIImage? {
		return nil
	}

	open var icon : UIImage? {
		if let locationIdentifier = context.location?.identifier {
			return type(of: self).iconForLocation(locationIdentifier)
		}

		return nil
	}

	open var position : ActionPosition {
		return type(of: self).applicablePosition(forContext: context)
	}

}

extension OCClassSettingsIdentifier {
	static let action = OCClassSettingsIdentifier("action")
}

extension Action : OCClassSettingsSupport {
	public static let classSettingsIdentifier : OCClassSettingsIdentifier = .action

	public static func defaultSettings(forIdentifier identifier: OCClassSettingsIdentifier) -> [OCClassSettingsKey : Any]? {
		return nil
	}

	static func enabledKey() -> OCClassSettingsKey? {
		guard let identifier = Self.identifier?.rawValue else { return nil }
		return OCClassSettingsKey(identifier + ".enabled")
	}

	static var enabled : Bool {
		if let key = Self.enabledKey() {
			if let value = Self.classSetting(forOCClassSettingsKey: key) as? Bool {
				return value
			}
		}
		return true
	}

	public static func classSettingsMetadata() -> [OCClassSettingsKey : [OCClassSettingsMetadataKey : Any]]? {
		guard let enabledKey = Self.enabledKey() else { return nil }
		return [
			enabledKey : [
				.type 		: OCClassSettingsMetadataType.boolean,
				.description	: "Controls whether action can be accessed in the app UI.",
				.category	: "Actions",
				.status		: OCClassSettingsKeyStatus.advanced
			]
		]
	}
}
