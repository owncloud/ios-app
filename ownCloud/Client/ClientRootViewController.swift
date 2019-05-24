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

class ClientRootViewController: UITabBarController, UINavigationControllerDelegate {

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

	var alertQueue : OCAsyncSequentialQueue = OCAsyncSequentialQueue()

	init(bookmark inBookmark: OCBookmark) {
		bookmark = inBookmark

		super.init(nibName: nil, bundle: nil)

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

			connectionShortDescription = connectionShortDescription != nil ? (connectionShortDescription! + ". ") : ""

			switch connectionStatus {
				case .online:
					summary = nil

				case .offline:
					summary?.message = "\(connectionShortDescription!)Contents from cache.".localized

				case .unavailable:
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

		if core?.delegate === self {
			core?.delegate = nil
		}

		Theme.shared.unregister(client: self)

		OCCoreManager.shared.returnCore(for: bookmark, completionHandler: nil)
	}

	// MARK: - Startup
	func afterCoreStart(_ completionHandler: @escaping (() -> Void)) {
		OCCoreManager.shared.requestCore(for: bookmark, setup: { (core, _) in
			self.core = core
			core?.delegate = self
		}, completionHandler: { (core, error) in
			if error == nil {
				self.coreReady()
			}

			// Start showing connection status with a delay of 1 second, so "Offline" doesn't flash briefly
			OnMainThread(after: 1.0) { [weak self] () in
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

		filesNavigationController = ThemeNavigationController()
		filesNavigationController?.delegate = self
		filesNavigationController?.navigationBar.isTranslucent = false
		filesNavigationController?.tabBarItem.title = "Browse".localized
		filesNavigationController?.tabBarItem.image = Theme.shared.image(for: "folder", size: folderButtonsSize)

		Theme.shared.add(tvgResourceFor: "status-flash")

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

	func closeClient(completion: (() -> Void)? = nil) {
		self.dismiss(animated: true, completion: {
			completion?()
		})
	}

	func coreReady() {
		OnMainThread {
			if let core = self.core {
				let query = OCQuery(forPath: "/")
//				let query = OCQuery(condition: OCQueryCondition.require([
//					.where(.name, contains: "i"),
//					.where(.type, isEqualTo: OCItemType.file.rawValue),
//					.where(.size, isGreaterThan: 220000)
//				]).sorted(by: .size, ascending: true), inputFilter:nil)

				let queryViewController = ClientQueryViewController(core: core, query: query)
				// Because we have nested UINavigationControllers (first one from ServerListTableViewController and each item UITabBarController needs it own UINavigationController), we have to fake the UINavigationController logic. Here we insert the emptyViewController, because in the UI should appear a "Back" button if the root of the queryViewController is shown. Therefore we put at first the emptyViewController inside and at the same time the queryViewController. Now, the back button is shown and if the users push the "Back" button the ServerListTableViewController is shown. This logic can be found in navigationController(_: UINavigationController, willShow: UIViewController, animated: Bool) below.
				self.filesNavigationController?.setViewControllers([self.emptyViewController, queryViewController], animated: false)

				let emptyViewController = self.emptyViewController
				self.filesNavigationController?.popLastHandler = { [weak self] (viewController) in
					if viewController == emptyViewController {
						OnMainThread {
							self?.closeClient()
						}
					}

					return (viewController != emptyViewController)
				}
				self.activityViewController?.core = core
				self.libraryViewController?.core = core
				self.libraryViewController?.setupQueries()
			}
		}
	}

	func navigationController(_: UINavigationController, willShow: UIViewController, animated: Bool) {
		// if the emptyViewController will show, because the push button in ClientQueryViewController was triggered, push immediately to the ServerListTableViewController, because emptyViewController is only a helper for showing the "Back" button in ClientQueryViewController
		if willShow.isEqual(emptyViewController) {
			self.closeClient()
		}
	}

	override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
		super.traitCollectionDidChange(previousTraitCollection)
		progressBarHeightConstraint?.constant = -1 * (self.tabBar.bounds.height)
		self.progressBar?.setNeedsLayout()
//		self.view.setNeedsLayout()
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
	func core(_ core: OCCore, handleError error: Error?, issue: OCIssue?) {
		alertQueue.async { (queueCompletionHandler) in
			var presentIssue : OCIssue? = issue
			var queueCompletionHandlerScheduled : Bool = false

			if error != nil {
				if let nsError : NSError = error as NSError? {
					if nsError.isOCError(withCode: .authorizationFailed) {
						let alertController = UIAlertController(title: "Authorization failed".localized,
											message: "The server declined access with the credentials stored for this connection.".localized,
											preferredStyle: .alert)

						alertController.addAction(UIAlertAction(title: "Ignore".localized, style: .destructive, handler: { (_) in
							queueCompletionHandler()
						}))

						alertController.addAction(UIAlertAction(title: "Edit".localized, style: .default, handler: { (_) in
							let editBookmark = self.bookmark

							queueCompletionHandler()

							if let navigationController = self.navigationController {
								self.closeClient(completion: {
									if let serverListTableViewController = navigationController.topViewController as? ServerListTableViewController {
										serverListTableViewController.showBookmarkUI(edit: editBookmark)
									}
								})
							}
						}))

						self.present(alertController, animated: true, completion: nil)
						queueCompletionHandlerScheduled = true

						return
					}
				}
			}

			if issue == nil, let error = error {
				presentIssue = OCIssue(forError: error, level: .error, issueHandler: nil)
			}

			if presentIssue != nil {
				var presentViewController : UIViewController?

				if presentIssue?.type == .multipleChoice {
					presentViewController = UIAlertController(with: presentIssue!, completion: queueCompletionHandler)
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

				if presentViewController != nil {
					var hostViewController : UIViewController = self

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
