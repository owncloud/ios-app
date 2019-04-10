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

enum ActionCategory {
	case normal
	case destructive
	case informal
	case edit
	case save
}

enum ActionPosition : Int {
	case none = -1

	case first = 100
	case beforeMiddle = 200
	case middle = 300
	case afterMiddle = 400
	case last = 500

	static func between(_ position1: ActionPosition, and position2: ActionPosition) -> ActionPosition {
		return ActionPosition(rawValue: ((position1.rawValue + position2.rawValue)/2))!
	}

	func shift(by offset: Int) -> ActionPosition {
		return ActionPosition(rawValue: self.rawValue + offset)!
	}
}

typealias ActionCompletionHandler = ((Error?) -> Void)
typealias ActionProgressHandler = ((Progress, Bool) -> Void)
typealias ActionWillRunHandler = () -> Void

extension OCExtensionType {
	static let action: OCExtensionType  =  OCExtensionType("app.action")
}

extension OCExtensionLocationIdentifier {
	static let tableRow: OCExtensionLocationIdentifier = OCExtensionLocationIdentifier("tableRow") //!< Present as table row action
	static let moreItem: OCExtensionLocationIdentifier = OCExtensionLocationIdentifier("moreItem") //!< Present in "more" card view for a single item
	static let moreFolder: OCExtensionLocationIdentifier = OCExtensionLocationIdentifier("moreFolder") //!< Present in "more" options for a whole folder
	static let toolbar: OCExtensionLocationIdentifier = OCExtensionLocationIdentifier("toolbar") //!< Present in a toolbar
	static let plusButton: OCExtensionLocationIdentifier = OCExtensionLocationIdentifier("plusButton") //!< Present in the alert sheet when the plus bar button is pressed
}

class ActionExtension: OCExtension {
	// MARK: - Custom Instance Properties.
	var name: String
	var category: ActionCategory

	// MARK: - Init & Deinit
	init(name: String, category: ActionCategory = .normal, identifier: OCExtensionIdentifier, locations: [OCExtensionLocationIdentifier]?, features: [String : Any]?, objectProvider: OCExtensionObjectProvider?, customMatcher: OCExtensionCustomContextMatcher?) {

		self.name = name
		self.category = category

		super.init(identifier: identifier, type: .action, locations: locations, features: features, objectProvider: objectProvider, customMatcher: customMatcher)
	}
}

class ActionContext: OCExtensionContext {
	// MARK: - Custom Instance Properties.
	weak var viewController: UIViewController?
	weak var core: OCCore?
	weak var query: OCQuery?
	var items: [OCItem]

	// MARK: - Init & Deinit.
	init(viewController: UIViewController, core: OCCore, query: OCQuery? = nil, items: [OCItem], location: OCExtensionLocation, requirements: [String : Any]? = nil, preferences: [String : Any]? = nil) {
		self.items = items

		super.init()

		self.viewController = viewController
		self.core = core
		self.location = location

		self.query = query
		self.requirements = requirements
		self.preferences = preferences
	}
}

class Action : NSObject {
	// MARK: - Extension metadata
	class var identifier : OCExtensionIdentifier? { return nil }
	class var category : ActionCategory? { return .normal }
	class var name : String? { return nil }
	class var locations : [OCExtensionLocationIdentifier]? { return nil }
	class var features : [String : Any]? { return nil }

	// MARK: - Extension creation
	class var actionExtension : ActionExtension {
		let objectProvider : OCExtensionObjectProvider = { (_ rawExtension, _ context, _ error) -> Any? in
			if let actionExtension = rawExtension as? ActionExtension,
				let actionContext   = context as? ActionContext {
				return self.init(for: actionExtension, with: actionContext)
			}

			return nil
		}

		let customMatcher : OCExtensionCustomContextMatcher  = { (context, priority) -> OCExtensionPriority in

			guard let actionContext = context as? ActionContext else {
				return priority
			}

			if self.applicablePosition(forContext: actionContext) == .none {
				// Exclude actions whose applicablePosition returns .none
				return .noMatch
			}

			return priority

			// Additional filtering (f.ex. via OCClassSettings, Settings) goes here
		}

		return ActionExtension(name: name!, category: category!, identifier: identifier!, locations: locations, features: features, objectProvider: objectProvider, customMatcher: customMatcher)
	}

	// MARK: - Extension matching
	class func applicablePosition(forContext: ActionContext) -> ActionPosition {
		return .middle
	}

	// MARK: - Finding actions
	class func sortedApplicableActions(for context: ActionContext) -> [Action] {
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

	// MARK: - Provide Card view controller
	class func cardViewController(for item: OCItem, with context: ActionContext, progressHandler: ActionProgressHandler? = nil, completionHandler: ((Error?) -> Void)? = nil) -> UIViewController {

		let tableViewController = MoreStaticTableViewController(style: .grouped)
		let header = MoreViewHeader(for: item, with: context.core!)
		let moreViewController = MoreViewController(item: item, core: context.core!, header: header, viewController: tableViewController)

		let title = NSAttributedString(string: "Actions".localized, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 20, weight: .heavy)])

		let actions = Action.sortedApplicableActions(for: context)

		actions.forEach({
			$0.actionWillRunHandler = {
				moreViewController.dismiss(animated: true)
			}

			$0.progressHandler = progressHandler

			$0.completionHandler = completionHandler
		})

		let actionsRows: [StaticTableViewRow] = actions.compactMap({return $0.provideStaticRow()})

		tableViewController.addSection(MoreStaticTableViewSection(headerAttributedTitle: title, identifier: "actions-section", rows: actionsRows))

		return moreViewController
	}

	// MARK: - Action metadata
	var context : ActionContext
	var actionExtension: ActionExtension
	weak var core : OCCore?

	// MARK: - Action creation
	required init(for actionExtension: ActionExtension, with context: ActionContext) {
		self.actionExtension = actionExtension
		self.context = context
		self.core = context.core!

		super.init()
	}

	// MARK: - Execution metadata
	var progressHandler : ActionProgressHandler?     // to be filled before calling run(), provideStaticRow(), provideContextualAction(), etc. if desired
	var completionHandler : ActionCompletionHandler? // to be filled before calling run(), provideStaticRow(), provideContextualAction(), etc. if desired
	var actionWillRunHandler: ActionWillRunHandler? // to be filled before calling run(), provideStaticRow(), provideContextualAction(), etc. if desired

	// MARK: - Action implementation
	func willRun() {

		if Thread.isMainThread == false {
			Log.warning("The Run method of the action \(Action.identifier!.rawValue) is not called inside the main thread")
		}

		if actionWillRunHandler != nil {
			actionWillRunHandler!()
		}
	}

	@objc func run() {
		completed()
	}

	func completed(with error: Error? = nil) {
		if let completionHandler = completionHandler {
			completionHandler(error)
		}
	}

	func publish(progress: Progress) {
		if let progressHandler = progressHandler {
			progressHandler(progress, true)
		}
	}

	func unpublish(progress: Progress) {
		if let progressHandler = progressHandler {
			progressHandler(progress, false)
		}
	}

	// MARK: - Action UI elements
	func provideStaticRow() -> StaticTableViewRow? {
		return StaticTableViewRow(buttonWithAction: { (_ row, _ sender) in
			self.willRun()
			self.run()
		}, title: actionExtension.name, style: actionExtension.category == .destructive ? .destructive : .plain, identifier: actionExtension.identifier.rawValue)
	}

	func provideContextualAction() -> UIContextualAction? {
		return UIContextualAction(style: actionExtension.category == .destructive ? .destructive : .normal, title: self.actionExtension.name, handler: { (_ action, _ view, _ uiCompletionHandler) in
			uiCompletionHandler(false)
			self.willRun()
			self.run()
		})
	}

	func provideAlertAction() -> UIAlertAction? {
		return UIAlertAction(title: self.actionExtension.name, style: actionExtension.category == .destructive ? .destructive : .default, handler: { (_ alertAction) in
			self.willRun()
			self.run()
		})
	}

	// MARK: - Action metadata
	class func iconForLocation(_ location: OCExtensionLocationIdentifier) -> UIImage? {
		return nil
	}

	var icon : UIImage? {
		if let locationIdentifier = context.location?.identifier {
			return Action.iconForLocation(locationIdentifier)
		}

		return nil
	}

	var position : ActionPosition {
		return type(of: self).applicablePosition(forContext: context)
	}
}
