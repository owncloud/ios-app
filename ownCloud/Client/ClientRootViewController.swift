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

class ClientRootViewController: UITabBarController {
	var bookmark : OCBookmark
	weak var core : OCCore?
	var filesNavigationController : ThemeNavigationController?
	var progressBar : CollapsibleProgressBar?
	var progressSummarizer : ProgressSummarizer?

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
		let openProgress = Progress()

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

		openProgress.localizedDescription = "Connecting…".localized
		progressSummarizer?.startTracking(progress: openProgress)

		core = OCCoreManager.shared.requestCore(for: bookmark, completionHandler: { (core, error) in
			if error == nil {
				self.coreReady()
			}

			openProgress.localizedDescription = "Connected.".localized
			openProgress.completedUnitCount = 1
			openProgress.totalUnitCount = 1

			// Start showing connection status with a delay of 1 second, so "Offline" doesn't flash briefly
			OnMainThread(after: 1.0) { [weak self] () in
				self?.connectionStatusObservation = core?.observe(\OCCore.connectionStatus, options: [.initial], changeHandler: { [weak self] (_, _) in
					self?.updateConnectionStatusSummary()
				})
			}

			self.progressSummarizer?.stopTracking(progress: openProgress)
		})
		core?.delegate = self
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

		OCCoreManager.shared.returnCore(for: bookmark, completionHandler: nil)
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		filesNavigationController = ThemeNavigationController()
		filesNavigationController?.navigationBar.isTranslucent = false
		filesNavigationController?.tabBarItem.title = "Browse".localized
		filesNavigationController?.tabBarItem.image = Theme.shared.image(for: "folder", size: CGSize(width: 25, height: 25))

		progressBar = CollapsibleProgressBar(frame: CGRect.zero)
		progressBar?.translatesAutoresizingMaskIntoConstraints = false

		self.view.addSubview(progressBar!)

		progressBar?.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
		progressBar?.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
		progressBar?.bottomAnchor.constraint(equalTo: self.tabBar.topAnchor).isActive = true

		self.tabBar.applyThemeCollection(Theme.shared.activeCollection)

		self.viewControllers = [filesNavigationController] as? [UIViewController]
	}

	func logoutBarButtonItem() -> UIBarButtonItem {
		let barButton = UIBarButtonItem(title: "Disconnect".localized, style: .plain, target: self, action: #selector(logout(_:)))
		barButton.accessibilityIdentifier = "disconnect-button"
		return barButton
	}

	@objc func logout(_: Any) {
		self.closeClient()
	}

	func closeClient(completion: (() -> Void)? = nil) {
		self.presentingViewController?.dismiss(animated: true, completion: completion)
	}

	func coreReady() {
		OnMainThread {
			let queryViewController = ClientQueryViewController(core: self.core!, query: OCQuery(forPath: "/"))

			queryViewController.navigationItem.leftBarButtonItem = self.logoutBarButtonItem()

			self.filesNavigationController?.pushViewController(queryViewController, animated: false)
		}
	}
}

extension ClientRootViewController : OCCoreDelegate {
	func core(_ core: OCCore!, handleError error: Error!, issue: OCIssue!) {
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
							let presentingViewController = self.presentingViewController
							let editBookmark = self.bookmark

							queueCompletionHandler()

							self.closeClient(completion: {
								if presentingViewController != nil,
								   let serverListNavigationController = presentingViewController as? UINavigationController,
								   let serverListTableViewController = serverListNavigationController.topViewController as? ServerListTableViewController {
									serverListTableViewController.showBookmarkUI(edit: editBookmark)
								}
							})
						}))

						self.present(alertController, animated: true, completion: nil)
						queueCompletionHandlerScheduled = true

						return
					}
				}
			}

			if issue == nil && error != nil {
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
