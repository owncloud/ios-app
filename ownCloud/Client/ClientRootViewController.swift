//
//  ClientViewController.swift
//  ownCloud
//
//  Created by Felix Schwarz on 05.04.18.
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

protocol ClientRootViewControllerAuthenticationDelegate : class {
	func handleAuthError(for clientViewController: ClientRootViewController, error: NSError, editBookmark: OCBookmark?)
}

class ClientRootViewController: UITabBarController {

	// MARK: - Constants
	let folderButtonsSize: CGSize = CGSize(width: 25.0, height: 25.0)

	// MARK: - Instance variables.
	let bookmark : OCBookmark
	weak var core : OCCore?
	var filesNavigationController : ThemeNavigationController?
	let emptyViewController = UIViewController()
	var activityNavigationController : ThemeNavigationController?
	var activityViewController : ClientActivityViewController?
	var libraryNavigationController : ThemeNavigationController?
	var libraryViewController : LibraryTableViewController?
	var progressBar : CollapsibleProgressBar?
	var progressBarHeightConstraint: NSLayoutConstraint?
	var progressSummarizer : ProgressSummarizer?
	var toolbar : UIToolbar?

	var notificationPresenter : NotificationMessagePresenter?
	var cardMessagePresenter : CardIssueMessagePresenter?

	var pasteboardChangedCounter = 0

	weak var authDelegate : ClientRootViewControllerAuthenticationDelegate?

	var skipAuthorizationFailure : Bool = false

	var connectionStatusObservation : NSKeyValueObservation?
	var connectionStatusSummary : ProgressSummary? {
		willSet {
			if newValue != nil {
				progressSummarizer?.pushPrioritySummary(summary: newValue!)
			}
		}

		didSet {
			if oldValue != nil {
				progressSummarizer?.popPrioritySummary(summary: oldValue!)
			}
		}
	}

	var messageSelector : MessageSelector?

	var alertQueue : OCAsyncSequentialQueue = OCAsyncSequentialQueue()

	init(bookmark inBookmark: OCBookmark) {
		bookmark = inBookmark

		super.init(nibName: nil, bundle: nil)

		notificationPresenter = NotificationMessagePresenter(forBookmarkUUID: bookmark.uuid)
		cardMessagePresenter = CardIssueMessagePresenter(with: bookmark.uuid as OCBookmarkUUID, limitToSingleCard: true, presenter: { [weak self] (viewController) in
			self?.presentAlertAsCard(viewController: viewController, withHandle: false, dismissable: true)
		})

		progressSummarizer = ProgressSummarizer.shared(forBookmark: inBookmark)
		if progressSummarizer != nil {
			progressSummarizer?.addObserver(self) { [weak self] (summarizer, summary) in
				var useSummary : ProgressSummary = summary
				let prioritySummary : ProgressSummary? = summarizer.prioritySummary

				if (summary.progress == 1) && (summarizer.fallbackSummary != nil) {
					useSummary = summarizer.fallbackSummary ?? summary
				}

				if prioritySummary != nil {
					useSummary = prioritySummary!
				}

				self?.progressBar?.update(with: useSummary.message, progress: Float(useSummary.progress))

				self?.progressBar?.autoCollapse = ((summarizer.fallbackSummary == nil) || (useSummary.progressCount == 0)) && (prioritySummary == nil)
			}
		}

		self.delegate = self
	}

	func updateConnectionStatusSummary() {
		var summary : ProgressSummary? = ProgressSummary(indeterminate: true, progress: 1.0, message: nil, progressCount: 1)

		if let connectionStatus = core?.connectionStatus {
			var connectionShortDescription = core?.connectionStatusShortDescription

			connectionShortDescription = connectionShortDescription != nil ? (connectionShortDescription!.hasSuffix(".") ? connectionShortDescription! + " " : connectionShortDescription! + ". ") : ""

			switch connectionStatus {
				case .online:
					summary = nil

				case .connecting:
					summary?.message = "Connecting…".localized

				case .offline, .unavailable:
					summary?.message = "\(connectionShortDescription!)Contents from cache.".localized
			}
		}

		self.connectionStatusSummary = summary
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	deinit {
		connectionStatusObservation = nil

		if let statusSummary = connectionStatusSummary {
			ProgressSummarizer.shared(forBookmark: bookmark).popPrioritySummary(summary: statusSummary)
		}
		ProgressSummarizer.shared(forBookmark: bookmark).removeObserver(self)
		ProgressSummarizer.shared(forBookmark: bookmark).reset()

		if core?.delegate === self {
			core?.delegate = nil
		}

		Theme.shared.unregister(client: self)

		// Remove message presenters
		if let notificationPresenter = self.notificationPresenter {
			core?.messageQueue.remove(presenter: notificationPresenter)
		}

		if let cardMessagePresenter = self.cardMessagePresenter {
			core?.messageQueue.remove(presenter: cardMessagePresenter)
		}

		OCCoreManager.shared.returnCore(for: bookmark, completionHandler: nil)
	}

	// MARK: - Startup
	func afterCoreStart(_ lastVisibleItemId: String?, completionHandler: @escaping (() -> Void)) {
		OCCoreManager.shared.requestCore(for: bookmark, setup: { (core, _) in
			self.core = core
			core?.delegate = self

			// Add message presenters
			if let notificationPresenter = self.notificationPresenter {
				core?.messageQueue.add(presenter: notificationPresenter)
			}

			if let cardMessagePresenter = self.cardMessagePresenter {
				core?.messageQueue.add(presenter: cardMessagePresenter)
			}

			// Remove skip available offline when user opens the bookmark
			core?.vault.keyValueStore?.storeObject(nil, forKey: .coreSkipAvailableOfflineKey)
		}, completionHandler: { (core, error) in
			if error == nil {
				self.coreReady(lastVisibleItemId)
			}

			// Start showing connection status
			OnMainThread { [weak self] () in
				self?.connectionStatusObservation = core?.observe(\OCCore.connectionStatus, options: [.initial], changeHandler: { [weak self] (_, _) in
					self?.updateConnectionStatusSummary()
				})
			}

			OnMainThread {
				completionHandler()
			}
		})
	}

	var pushTransition : PushTransitionDelegate?

	override func viewDidLoad() {
		super.viewDidLoad()

		self.view.backgroundColor = Theme.shared.activeCollection.tableBackgroundColor
		self.navigationController?.setNavigationBarHidden(true, animated: true)

		self.tabBar.isTranslucent = false

		// Add tab bar icons
		Theme.shared.add(tvgResourceFor: "folder")
		Theme.shared.add(tvgResourceFor: "owncloud-logo")
		Theme.shared.add(tvgResourceFor: "status-flash")

		filesNavigationController = ThemeNavigationController()
		filesNavigationController?.navigationBar.isTranslucent = false
		filesNavigationController?.tabBarItem.title = "Browse".localized
		filesNavigationController?.tabBarItem.image = Theme.shared.image(for: "folder", size: folderButtonsSize)

		activityViewController = ClientActivityViewController()
		activityNavigationController = ThemeNavigationController(rootViewController: activityViewController!)
		activityNavigationController?.tabBarItem.title = "Status".localized
		activityNavigationController?.tabBarItem.image = Theme.shared.image(for: "status-flash", size: CGSize(width: 25, height: 25))

		libraryViewController = LibraryTableViewController(style: .grouped)
		libraryNavigationController = ThemeNavigationController(rootViewController: libraryViewController!)
		libraryNavigationController?.tabBarItem.title = "Quick Access".localized
		libraryNavigationController?.tabBarItem.image = Theme.shared.image(for: "owncloud-logo", size: CGSize(width: 25, height: 25))

		progressBar = CollapsibleProgressBar(frame: CGRect.zero)
		progressBar?.translatesAutoresizingMaskIntoConstraints = false

		self.view.addSubview(progressBar!)

		progressBar?.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
		progressBar?.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
		progressBarHeightConstraint = NSLayoutConstraint(item: progressBar!, attribute: .bottom, relatedBy: .equal, toItem: self.view, attribute: .bottom, multiplier: 1.0, constant: -1 * (self.tabBar.bounds.height))
		progressBarHeightConstraint?.isActive = true

		toolbar = UIToolbar(frame: .zero)
		toolbar?.translatesAutoresizingMaskIntoConstraints = false
		toolbar?.insetsLayoutMarginsFromSafeArea = true
		toolbar?.isTranslucent = false

		self.view.addSubview(toolbar!)

		toolbar?.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
		toolbar?.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
		toolbar?.topAnchor.constraint(equalTo: self.tabBar.topAnchor).isActive = true
		toolbar?.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor).isActive = true

		toolbar?.isHidden = true

		Theme.shared.register(client: self, applyImmediately: true)

		if let filesNavigationController = filesNavigationController,
		   let activityNavigationController = activityNavigationController, let libraryNavigationController = libraryNavigationController {
			self.viewControllers = [ filesNavigationController, libraryNavigationController, activityNavigationController ]
		}
	}

	var closeClientCompletionHandler : (() -> Void)?

	func closeClient(completion: (() -> Void)? = nil) {
		OCBookmarkManager.lastBookmarkSelectedForConnection = nil

		self.dismiss(animated: true, completion: {
			if completion != nil {
				OnMainThread { // Work-around to make sure the self.presentingViewController is ready to present something new. Immediately after .dismiss returns, it isn't, so we wait one runloop-cycle for it to complete
					completion?()
				}
			}
		})
	}

	func coreReady(_ lastVisibleItemId: String?) {
		OnMainThread {
			if let core = self.core {
				if let localItemId = lastVisibleItemId {
					self.createFileListStack(for: localItemId)
				} else {
					let query = OCQuery(forPath: "/")
					let queryViewController = ClientQueryViewController(core: core, query: query, rootViewController: self)
					// Because we have nested UINavigationControllers (first one from ServerListTableViewController and each item UITabBarController needs it own UINavigationController), we have to fake the UINavigationController logic. Here we insert the emptyViewController, because in the UI should appear a "Back" button if the root of the queryViewController is shown. Therefore we put at first the emptyViewController inside and at the same time the queryViewController. Now, the back button is shown and if the users push the "Back" button the ServerListTableViewController is shown. This logic can be found in navigationController(_: UINavigationController, willShow: UIViewController, animated: Bool) below.
					self.filesNavigationController?.setViewControllers([self.emptyViewController, queryViewController], animated: false)
				}

				let emptyViewController = self.emptyViewController
				emptyViewController.navigationItem.title = "Accounts".localized

				self.filesNavigationController?.popLastHandler = { [weak self] (viewController) in
					if viewController == emptyViewController {
						OnMainThread {
							self?.closeClient()
							if #available(iOS 13.0, *) {
								// Prevent re-opening of items on next launch in case user has returned to the bookmark list
								self?.view.window?.windowScene?.userActivity = nil
							}
						}
					}

					return (viewController != emptyViewController)
				}

				let bookmarkUUID = core.bookmark.uuid

				self.activityViewController?.core = core
				self.libraryViewController?.core = core

				self.messageSelector = MessageSelector(from: core.messageQueue, filter: { (message) in
					return (message.bookmarkUUID == bookmarkUUID) && !message.resolved
				}, provideGroupedSelection: true, provideSyncRecordIDs: true, handler: { [weak self] (messages, groups, syncRecordIDs) in
					self?.updateMessageSelectionWith(messages: messages, groups: groups, syncRecordIDs: syncRecordIDs)
				})

				self.activityViewController?.messageSelector = self.messageSelector

				self.connectionInitializedObservation = core.observe(\OCCore.connection.connectionInitializationPhaseCompleted, options: [.initial], changeHandler: { [weak self] (core, _) in
					if core.connection.connectionInitializationPhaseCompleted {
						self?.connectionInitialized()
					}
				})
			}
		}
	}

	private var connectionInitializedObservation : NSKeyValueObservation?

	func connectionInitialized() {
		OCSynchronized(self) {
			if connectionInitializedObservation == nil {
				return
			}

			connectionInitializedObservation = nil
		}

		OnMainThread {
			self.libraryViewController?.setupQueries()
		}
	}

	override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
		super.traitCollectionDidChange(previousTraitCollection)
		progressBarHeightConstraint?.constant = -1 * (self.tabBar.bounds.height)
		self.progressBar?.setNeedsLayout()
//		self.view.setNeedsLayout()
	}

	func updateMessageSelectionWith(messages: [OCMessage]?, groups : [MessageGroup]?, syncRecordIDs : Set<OCSyncRecordID>?) {
		OnMainThread {
			self.activityViewController?.handleMessagesUpdates(messages: messages, groups: groups)

			if syncRecordIDs != self.syncRecordIDsWithMessages {
				self.syncRecordIDsWithMessages = syncRecordIDs
			}
		}
	}

	var syncRecordIDsWithMessages : Set<OCSyncRecordID>? {
		didSet {
			NotificationCenter.default.post(name: .ClientSyncRecordIDsWithMessagesChanged, object: self.core)
		}
	}

	func createFileListStack(for itemLocalID: String) {
		if let core = core {
			// retrieve the item for the item id
			core.retrieveItemFromDatabase(forLocalID: itemLocalID, completionHandler: { (error, _, item) in
				OnMainThread {
					let query = OCQuery(forPath: "/")
					let queryViewController = ClientQueryViewController(core: core, query: query, rootViewController: self)

					if error == nil, let item = item, item.isRoot == false {
						// get all parent items for the item and rebuild all underlaying ClientQueryViewController for this items in the navigation stack
						let parentItems = core.retrieveParentItems(for: item)

						var subController = queryViewController
						var newViewControllersStack : [UIViewController] = []
						for item in parentItems {
							if let controller = self.open(item: item, in: subController) {
								subController = controller
								newViewControllersStack.append(controller)
							}
						}

						newViewControllersStack.insert(self.emptyViewController, at: 0)
						self.filesNavigationController?.setViewControllers(newViewControllersStack, animated: false)

						// open the controller for the item
						subController.open(item: item, animated: false)
					} else {
						// Fallback, if item no longer exists show root folder
						self.filesNavigationController?.setViewControllers([self.emptyViewController, queryViewController], animated: false)
					}
				}
		})
		}
	}

	func open(item: OCItem, in controller: ClientQueryViewController) -> ClientQueryViewController? {
		if let subController = controller.open(item: item, animated: false, pushViewController: false) {
			return subController
		}

		return nil
	}
}

extension ClientRootViewController : Themeable {
	func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		self.tabBar.applyThemeCollection(collection)

		self.toolbar?.applyThemeCollection(Theme.shared.activeCollection)

		self.view.backgroundColor = collection.tableBackgroundColor
	}
}

extension ClientRootViewController : OCCoreDelegate {
	func core(_ core: OCCore, handleError error: Error?, issue inIssue: OCIssue?) {
		var issue = inIssue
		var isAuthFailure : Bool = false
		var authFailureMessage : String?
		var authFailureTitle : String = "Authorization failed".localized
		var authFailureHasEditOption : Bool = true
		var authFailureIgnoreLabel = "Ignore".localized
		var authFailureIgnoreStyle = UIAlertAction.Style.destructive
		let editBookmark = self.bookmark
		var nsError = error as NSError?

		if nsError == nil, let issueNSError = issue?.error as NSError? {
			// Turn issues that are just converted authorization errors back into errors and discard the issue
			if issueNSError.isOCError(withCode: .authorizationFailed) ||
			   issueNSError.isOCError(withCode: .authorizationNoMethodData) ||
			   issueNSError.isOCError(withCode: .authorizationMissingData) {
				nsError = issueNSError
				issue = nil
			}
		}

		if let nsError = nsError {
			if nsError.isOCError(withCode: .authorizationFailed) {
				if let underlyingError = nsError.userInfo[NSUnderlyingErrorKey] as? NSError, underlyingError.isDAVException, underlyingError.davExceptionMessage == "User disabled" {
					authFailureHasEditOption = false
					authFailureIgnoreStyle = .cancel
					authFailureIgnoreLabel = "Continue offline".localized
					authFailureMessage = "The account has been disabled."
				} else {
					if bookmark.isTokenBased == true {
						authFailureTitle = "Access denied".localized
						authFailureMessage = "The connection's access token has expired or become invalid. Sign in again to re-gain access.".localized

						if let localizedDescription = nsError.userInfo[NSLocalizedDescriptionKey] {
							authFailureMessage = "\(authFailureMessage!)\n\n(\(localizedDescription))"
						}
					} else {
						authFailureMessage = "The server declined access with the credentials stored for this connection.".localized
					}
				}

				isAuthFailure = true
			}

			if nsError.isOCError(withCode: .authorizationNoMethodData) || nsError.isOCError(withCode: .authorizationMissingData) {
				authFailureMessage = "No authentication data has been found for this connection.".localized

				isAuthFailure = true
			}

			if isAuthFailure {
				// Make sure only the first auth failure will actually lead to an alert
				// (otherwise alerts could keep getting enqueued while the first alert is being shown,
				// and then be presented even though they're no longer relevant). It's ok to only show
				// an alert for the first auth failure, because the options are "Ignore" (=> no longer show them)
				// and "Edit" (=> log out, go to bookmark editing)
				var doSkip = false

				OCSynchronized(self) {
					doSkip = skipAuthorizationFailure  // Keep in mind OCSynchronized() contents is running as a block, so "return" in here wouldn't have the desired effect
					skipAuthorizationFailure = true
				}

				if doSkip {
					return
				}
			}
		}

		alertQueue.async { [weak self] (queueCompletionHandler) in
			var presentIssue : OCIssue? = issue
			var queueCompletionHandlerScheduled : Bool = false

			if isAuthFailure {
				let alertController = ThemedAlertController(title: authFailureTitle,
									message: authFailureMessage,
									preferredStyle: .alert)

				alertController.addAction(UIAlertAction(title: authFailureIgnoreLabel, style: authFailureIgnoreStyle, handler: { (_) in
					queueCompletionHandler()
				}))

				if authFailureHasEditOption {
					alertController.addAction(UIAlertAction(title: "Sign in".localized, style: .default, handler: { (_) in
						queueCompletionHandler()

						if let authDelegate = self?.authDelegate, let self = self, let nsError = nsError {
							authDelegate.handleAuthError(for: self, error: nsError, editBookmark: editBookmark)
						}
					}))
				}

				self?.present(alertController, animated: true, completion: nil)
				queueCompletionHandlerScheduled = true

				return
			}

			if issue == nil, let error = error {
				presentIssue = OCIssue(forError: error, level: .error, issueHandler: nil)
			}

			if presentIssue != nil {
				var presentViewController : UIViewController?

				if presentIssue?.type == .multipleChoice {
					presentViewController = ThemedAlertController(with: presentIssue!, completion: queueCompletionHandler)
				} else {
					presentViewController = ConnectionIssueViewController(displayIssues: presentIssue?.prepareForDisplay(), completion: { (response) in
 						switch response {
							case .cancel:
								presentIssue?.reject()

							case .approve:
								presentIssue?.approve()

							case .dismiss: break
						}
						queueCompletionHandler()
					})
				}

				if presentViewController != nil, let startViewController = self {
					var hostViewController : UIViewController = startViewController

					while hostViewController.presentedViewController != nil,
					      hostViewController.presentedViewController?.isBeingDismissed == false {
						hostViewController = hostViewController.presentedViewController!
					}

					queueCompletionHandlerScheduled = true

					hostViewController.present(presentViewController!, animated: true, completion: nil)
				}
			}

			if !queueCompletionHandlerScheduled {
				queueCompletionHandler()
			}
		}
	}

	func presentAlertAsCard(viewController: UIViewController, withHandle: Bool = false, dismissable: Bool = true) {
		alertQueue.async { [weak self] (queueCompletionHandler) in
			if let startViewController = self {
				var hostViewController : UIViewController = startViewController

				while hostViewController.presentedViewController != nil,
				      hostViewController.presentedViewController?.isBeingDismissed == false {
					hostViewController = hostViewController.presentedViewController!
				}

				hostViewController.present(asCard: viewController, animated: true, withHandle: withHandle, dismissable: dismissable, completion: {
					queueCompletionHandler()
				})
			} else {
				queueCompletionHandler()
			}
		}
	}
}

extension ClientRootViewController: UITabBarControllerDelegate {
	func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
		if tabBarController.selectedViewController == viewController {
			if let navigationController = viewController as? ThemeNavigationController {
				let navigationStack = navigationController.viewControllers

				if navigationStack.count > 1 {
					navigationController.popToViewController(navigationStack[1], animated: true)
					return false
				}
			}
		}

		return true
	}
}

extension NSNotification.Name {
	static let ClientSyncRecordIDsWithMessagesChanged = NSNotification.Name(rawValue: "client-sync-record-ids-with-messages-changed")
}
