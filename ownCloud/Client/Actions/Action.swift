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

typealias ActionCompletionHandler = ((Action, Error?) -> Void)
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

	class func cardViewController(for item: OCItem, with context: ActionContext, progressHandler: ActionProgressHandler? = nil, completionHandler: ((Action, Error?) -> Void)? = nil) -> UIViewController? {
		guard let core = context.core else { return nil }

		let tableViewController = MoreStaticTableViewController(style: .plain)
		let header = MoreViewHeader(for: item, with: core)
		let moreViewController = MoreViewController(item: item, core: core, header: header, viewController: tableViewController)

		if core.connectionStatus == .online, core.connection.capabilities?.sharingAPIEnabled == 1 {
			OnMainThread {
				if item.isSharedWithUser || item.isShared {

					let progressView = UIActivityIndicatorView(style: Theme.shared.activeCollection.activityIndicatorViewStyle)
					progressView.startAnimating()

					let row = StaticTableViewRow(rowWithAction: nil, title: "Searching Shares...".localized, alignment: .left, accessoryView: progressView, identifier: "share-searching")
					self.updateSharingSection(sectionIdentifier: "share-section", rows: [row], tableViewController: tableViewController)

					core.unifiedShares(for: item, completionHandler: { (shares) in
						OnMainThread {
							let shareRows = self.shareRows(shares: shares, item: item, presentingController: moreViewController, context: context)
							self.updateSharingSection(sectionIdentifier: "share-section", rows: shareRows, tableViewController: tableViewController)
							moreViewController.preferredContentSize = tableViewController.tableView.contentSize
						}
					})
				} else if item.isShareable {
					var shareRows : [StaticTableViewRow] = []
					shareRows.append(self.shareAsGroupRow(item: item, presentingController: moreViewController, context: context))
					if let publicLinkRow = self.shareAsPublicLinkRow(item: item, presentingController: moreViewController, context: context) {
						shareRows.append(publicLinkRow)
					}
					tableViewController.insertSection(StaticTableViewSection(headerTitle: nil, footerTitle: nil, identifier: "share-section", rows: shareRows), at: 0, animated: true)
					moreViewController.preferredContentSize = tableViewController.tableView.contentSize
				}
			}
		}

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
			completionHandler(self, error)
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
		}, title: actionExtension.name, style: actionExtension.category == .destructive ? .destructive : .plain, image: self.icon, alignment: .left, identifier: actionExtension.identifier.rawValue)
	}

	func provideContextualAction() -> UIContextualAction? {
		return UIContextualAction(style: actionExtension.category == .destructive ? .destructive : .normal, title: self.actionExtension.name, handler: { (_ action, _ view, _ uiCompletionHandler) in
			uiCompletionHandler(false)
			self.willRun()
			self.run()
		})
	}

	func provideAlertAction() -> UIAlertAction? {
		let alertAction = UIAlertAction(title: self.actionExtension.name, style: actionExtension.category == .destructive ? .destructive : .default, handler: { (_ alertAction) in
			self.willRun()
			self.run()
		})

		let image = self.icon
		if alertAction.responds(to: NSSelectorFromString("setImage:")) {
			alertAction.setValue(image, forKey: "image")
		}
		if alertAction.responds(to: NSSelectorFromString("_setTitleTextAlignment:")) {
			alertAction.setValue(CATextLayerAlignmentMode.left, forKey: "titleTextAlignment")
		}

		return alertAction
	}

	// MARK: - Action metadata
	class func iconForLocation(_ location: OCExtensionLocationIdentifier) -> UIImage? {
		return nil
	}

	var icon : UIImage? {
		if let locationIdentifier = context.location?.identifier {
			return type(of: self).iconForLocation(locationIdentifier)
		}

		return nil
	}

	var position : ActionPosition {
		return type(of: self).applicablePosition(forContext: context)
	}

}

// MARK: - Sharing

extension Action {

	class func shareRows(shares: [OCShare], item: OCItem, presentingController: UIViewController, context: ActionContext) -> [StaticTableViewRow] {
		var shareRows: [StaticTableViewRow] = []

		if shares.count > 0 {
			var userTitle = ""
			var linkTitle = ""
			var hasUserGroupSharing = false
			var hasLinkSharing = false

			if item.isSharedWithUser == false {
				// find Shares by me
				let privateShares = shares.filter { (OCShare) -> Bool in
					if OCShare.type != .link {
						return true
					}
					return false
				}

				if privateShares.count > 0 {
					var title = "Recipient".localized
					if privateShares.count > 1 {
						title = "Recipients".localized
					}
					userTitle = "\(privateShares.count) \(title)"
					hasUserGroupSharing = true
				}
			} else {
				// find shares by others
				for share in shares {
					if let ownerName = share.itemOwner?.displayName {
						userTitle = String(format: "Shared by %@".localized, ownerName)
						hasUserGroupSharing = true
						break
					}
				}
			}

			// find Public link shares
			let linkShares = shares.filter { (OCShare) -> Bool in
				if OCShare.type == .link {
					return true
				}
				return false
			}
			if linkShares.count > 0 {
				var title = "Public Link".localized
				if linkShares.count > 1 {
					title = "Public Links".localized
				}
				linkTitle.append("\(linkShares.count) \(title)")
				hasLinkSharing = true
			}

			if hasUserGroupSharing {
				let addGroupRow = StaticTableViewRow(rowWithAction: { (_, _) in
					presentingController.dismiss(animated: true)

					if let viewController = context.viewController, let core = context.core {
						let sharingViewController = GroupSharingTableViewController(core: core, item: item)
						sharingViewController.shares = shares
						let navigationController = ThemeNavigationController(rootViewController: sharingViewController)
						viewController.present(navigationController, animated: true, completion: nil)
					}
				}, title: userTitle, subtitle: nil, image: UIImage(named: "group"), alignment: .left, accessoryType: .disclosureIndicator)
				shareRows.append(addGroupRow)
			} else {
				shareRows.append(self.shareAsGroupRow(item: item, presentingController: presentingController, context: context))
			}

			if hasLinkSharing {
				let addGroupRow = StaticTableViewRow(rowWithAction: { (_, _) in
					presentingController.dismiss(animated: true)

					if let viewController = context.viewController, let core = context.core {
						let sharingViewController = PublicLinkTableViewController(core: core, item: item)
						sharingViewController.shares = shares
						let navigationController = ThemeNavigationController(rootViewController: sharingViewController)
						viewController.present(navigationController, animated: true, completion: nil)
					}
				}, title: linkTitle, subtitle: nil, image: UIImage(named: "link"), alignment: .left, accessoryType: .disclosureIndicator)
				shareRows.append(addGroupRow)
			} else if let publicLinkRow = self.shareAsPublicLinkRow(item: item, presentingController: presentingController, context: context) {
				shareRows.append(publicLinkRow)
			}
		} else if item.isShareable {
			shareRows.append(self.shareAsGroupRow(item: item, presentingController: presentingController, context: context))
			if let publicLinkRow = self.shareAsPublicLinkRow(item: item, presentingController: presentingController, context: context) {
				shareRows.append(publicLinkRow)
			}
		}

		return shareRows
	}

	class func updateSharingSection(sectionIdentifier: String, rows: [StaticTableViewRow], tableViewController: MoreStaticTableViewController) {
		if let section = tableViewController.sectionForIdentifier(sectionIdentifier) {
			tableViewController.removeSection(section)
		}
		if rows.count > 0 {
			tableViewController.insertSection(MoreStaticTableViewSection(identifier: "share-section", rows: rows), at: 0, animated: false)
		}
	}

	class func shareAsGroupRow(item : OCItem, presentingController: UIViewController, context: ActionContext) -> StaticTableViewRow {
		var title = "Share this file".localized
		if item.type == .collection {
			title = "Share this folder".localized
		}

		let addGroupRow = StaticTableViewRow(buttonWithAction: { (_, _) in
			presentingController.dismiss(animated: true)

			if let viewController = context.viewController, let core = context.core {
				let sharingViewController = GroupSharingTableViewController(core: core, item: item)
				let navigationController = ThemeNavigationController(rootViewController: sharingViewController)

				viewController.present(navigationController, animated: true, completion: nil)
			}
		}, title: title, style: .plain, image: UIImage(named: "group"), alignment: .left, identifier: "share-add-group")

		return addGroupRow
	}

	class func shareAsPublicLinkRow(item : OCItem, presentingController: UIViewController, context: ActionContext) -> StaticTableViewRow? {
		if let core = context.core, core.connection.capabilities?.publicSharingEnabled == true, !item.sharedByPublicLink, item.isShareable {
			let addGroupRow = StaticTableViewRow(buttonWithAction: { (_, _) in
				presentingController.dismiss(animated: true)

				if let viewController = context.viewController {
					let sharingViewController = PublicLinkTableViewController(core: core, item: item)
					let navigationController = ThemeNavigationController(rootViewController: sharingViewController)

					viewController.present(navigationController, animated: true, completion: nil)
				}
			}, title: "Create Public Link".localized, style: .plain, image: UIImage(named: "link"), alignment: .left, identifier: "share-add-group")

			return addGroupRow
		}

		return nil
	}
}
