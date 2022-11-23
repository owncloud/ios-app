//
//  AppRootViewController.swift
//  ownCloud
//
//  Created by Felix Schwarz on 15.11.22.
//  Copyright © 2022 ownCloud GmbH. All rights reserved.
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
import ownCloudAppShared

open class AppRootViewController: UIViewController {
	var clientContext: ClientContext
	var controllerConfiguration: AccountController.Configuration

	var focusedBookmarkObservation: NSKeyValueObservation?

	init(with context: ClientContext, controllerConfiguration: AccountController.Configuration = .defaultConfiguration) {
		clientContext = context
		self.controllerConfiguration = controllerConfiguration
		super.init(nibName: nil, bundle: nil)
	}

	required public init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override open func viewDidLoad() {
		super.viewDidLoad()

		// Add icons
		AppRootViewController.addIcons()

		// Create content navigation controller ("right" side of split view)
		contentNavigationController = ThemeNavigationController()
		contentNavigationController?.navigationBar.isTranslucent = false

		rootContext = ClientContext(with: clientContext, rootViewController: self, navigationController: contentNavigationController, modifier: { context in
			context.viewItemHandler = self
			context.moreItemHandler = self
		})

		// Build sidebar
		sidebarViewController = ClientSidebarViewController(context: rootContext!, controllerConfiguration: controllerConfiguration)
		sidebarViewController?.addToolbarItems()

		leftNavigationController = ThemeNavigationController(rootViewController: sidebarViewController!)
		leftNavigationController?.setToolbarHidden(false, animated: false)

		focusedBookmarkObservation = sidebarViewController?.observe(\.focusedBookmark, changeHandler: { [weak self] sidebarViewController, change in
			self?.focusedBookmark = self?.sidebarViewController?.focusedBookmark
		})

		// Build split view controller
		let splitViewController = UISplitViewController(style: .doubleColumn)
		splitViewController.displayModeButtonVisibility = .always
		splitViewController.preferredDisplayMode = .oneBesideSecondary

		splitViewController.setViewController(leftNavigationController, for: .primary)
		splitViewController.setViewController(contentNavigationController, for: .secondary)

		splitViewController.view.translatesAutoresizingMaskIntoConstraints = false

		contentSplitViewController = splitViewController

		// Make split view controller the content
		contentViewController = splitViewController
	}

	// MARK: - View Controllers
	var rootContext: ClientContext?
	var contentSplitViewController: UISplitViewController?

	var leftNavigationController: ThemeNavigationController?
	var sidebarViewController: ClientSidebarViewController?
	var contentNavigationController : ThemeNavigationController?

	// MARK: - Message presentation
	var alertQueue : OCAsyncSequentialQueue = OCAsyncSequentialQueue()

	var notificationPresenter: NotificationMessagePresenter?
	var cardMessagePresenter: CardIssueMessagePresenter?

	@objc dynamic var focusedBookmark: OCBookmark? {
		willSet {
			// Remove message presenters
			if let notificationPresenter {
				OCMessageQueue.global.remove(presenter: notificationPresenter)
			}

			if let cardMessagePresenter {
				OCMessageQueue.global.remove(presenter: cardMessagePresenter)
			}
		}

		didSet {
			if let focusedBookmark {
				// Create message presenters
				notificationPresenter = NotificationMessagePresenter(forBookmarkUUID: focusedBookmark.uuid)
				cardMessagePresenter = CardIssueMessagePresenter(with: focusedBookmark.uuid as OCBookmarkUUID, limitToSingleCard: true, presenter: { [weak self] (viewController) in
					self?.presentAlertAsCard(viewController: viewController, withHandle: false, dismissable: true)
					// Log.debug("Present \(viewController.debugDescription)")
				})

				// Add message presenters
				if let notificationPresenter {
					OCMessageQueue.global.add(presenter: notificationPresenter)
				}

				if let cardMessagePresenter {
					OCMessageQueue.global.add(presenter: cardMessagePresenter)
				}
			}
		}
	}

	// MARK: - Content View Controller handling
	private var contentViewControllerConstraints : [NSLayoutConstraint]? {
		willSet {
			if let contentViewControllerConstraints = contentViewControllerConstraints {
				NSLayoutConstraint.deactivate(contentViewControllerConstraints)
			}
		}
		didSet {
			if let contentViewControllerConstraints = contentViewControllerConstraints {
				NSLayoutConstraint.activate(contentViewControllerConstraints)
			}
		}
	}
	var contentViewController: UIViewController? {
		willSet {
			contentViewController?.willMove(toParent: nil)
			contentViewController?.view.removeFromSuperview()
			contentViewController?.removeFromParent()

			contentViewControllerConstraints = nil
		}
		didSet {
			if let contentViewController = contentViewController, let contentViewControllerView = contentViewController.view {
				addChild(contentViewController)
				view.addSubview(contentViewControllerView)
				contentViewControllerView.translatesAutoresizingMaskIntoConstraints = false
				contentViewControllerConstraints = view.embed(toFillWith: contentViewController.view, enclosingAnchors: view.defaultAnchorSet)
				contentViewController.didMove(toParent: self)
			}
		}
	}

	// MARK: - View Controller Events
	var shownFirstTime = true

	open override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)

		ClientSessionManager.shared.add(delegate: self)

		if AppLockManager.shared.passcode == nil && AppLockSettings.shared.isPasscodeEnforced {
			PasscodeSetupCoordinator(parentViewController: self, action: .setup).start()
		} else if let passcode = AppLockManager.shared.passcode, passcode.count < AppLockSettings.shared.requiredPasscodeDigits {
			PasscodeSetupCoordinator(parentViewController: self, action: .upgrade).start()
		}

		if VendorServices.shared.showBetaWarning, shownFirstTime {
			considerBetaWarning()
		}

		if !shownFirstTime {
			VendorServices.shared.considerReviewPrompt()
		}
	}

	open override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)

		ClientSessionManager.shared.remove(delegate: self)
	}

	// MARK: - Beta warning
	func considerBetaWarning() {
		let lastBetaWarningCommit = OCAppIdentity.shared.userDefaults?.string(forKey: "LastBetaWarningCommit")

		Log.log("Show beta warning: \(String(describing: VendorServices.classSetting(forOCClassSettingsKey: .showBetaWarning) as? Bool))")

		if VendorServices.classSetting(forOCClassSettingsKey: .showBetaWarning) as? Bool == true,
			let lastGitCommit = LastGitCommit(),
			(lastBetaWarningCommit == nil) || (lastBetaWarningCommit != lastGitCommit) {
			// Beta warning has never been shown before - or has last been shown for a different release
			let betaAlert = ThemedAlertController(with: "Beta Warning".localized, message: "\nThis is a BETA release that may - and likely will - still contain bugs.\n\nYOU SHOULD NOT USE THIS BETA VERSION WITH PRODUCTION SYSTEMS, PRODUCTION DATA OR DATA OF VALUE. YOU'RE USING THIS BETA AT YOUR OWN RISK.\n\nPlease let us know about any issues that come up via the \"Send Feedback\" option in the settings.".localized, okLabel: "Agree".localized) {
				OCAppIdentity.shared.userDefaults?.set(lastGitCommit, forKey: "LastBetaWarningCommit")
				OCAppIdentity.shared.userDefaults?.set(NSDate(), forKey: "LastBetaWarningAcceptDate")
			}

			self.present(betaAlert, animated: true, completion: nil)
		}
	}
}

extension AppRootViewController : ClientSessionManagerDelegate {
	var selectedAccountConnection: AccountController? {
		if let accountControllerSection = self.sidebarViewController?.sectionOfCurrentSelection as? AccountControllerSection {
			return accountControllerSection.accountController
		}

		return nil
	}

	func canPresent(bookmark: OCBookmark, message: OCMessage?) -> OCMessagePresentationPriority {
		if let themeWindow = self.viewIfLoaded?.window as? ThemeWindow, themeWindow.themeWindowInForeground {
			if !OCBookmarkManager.isLocked(bookmark: bookmark) {
				if let selectedAccountConnection {
					if selectedAccountConnection.connection?.bookmark.uuid == bookmark.uuid {
						return .high
					} else {
						return .default
					}
				} else if presentedViewController == nil {
					return .high
				}
			}

			return .low
		}

		return .wontPresent
	}

	func present(bookmark: OCBookmark, message: OCMessage?) {
		OnMainThread {
			/*
			if self.presentedViewController == nil {
				self.connect(to: bookmark, lastVisibleItemId: nil, animated: true, present: message)
			} else {
			*/

			if let message = message {
				self.presentInClient(message: message)
			}
		}
	}

	func presentInClient(message: OCMessage) {
		if let cardMessagePresenter {
			OnMainThread { // Wait for next runloop cycle
				OCMessageQueue.global.present(message, with: cardMessagePresenter)
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

extension ClientSidebarViewController {
	// MARK: - Add toolbar items
	func addToolbarItems(addAccount: Bool = true, settings addSettings: Bool = true) {
		var toolbarItems: [UIBarButtonItem] = []

		if addAccount {
			let addAccountBarButtonItem = UIBarButtonItem(systemItem: .add, primaryAction: UIAction(handler: { [weak self] action in
				self?.addBookmark()
			}))

			toolbarItems.append(addAccountBarButtonItem)
		}

		if addSettings {
			let settingsBarButtonItem = UIBarButtonItem(title: "Settings".localized, style: UIBarButtonItem.Style.plain, target: self, action: #selector(settings))
			settingsBarButtonItem.accessibilityIdentifier = "settingsBarButtonItem"

			toolbarItems.append(contentsOf: [
				UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil),
				settingsBarButtonItem
			])
		}

		self.toolbarItems = toolbarItems
	}

	// MARK: - Open settings
	@IBAction func settings() {
		let viewController : SettingsViewController = SettingsViewController(style: .grouped)
		self.present(ThemeNavigationController(rootViewController: viewController), animated: true)
	}

	// MARK: - Add account
	func addBookmark() {
		BookmarkViewController.showBookmarkUI(on: self, attemptLoginOnSuccess: true)
	}
}

// MARK: - Branding
public extension AppRootViewController {
	static func addIcons() {
		Theme.shared.add(tvgResourceFor: "icon-available-offline")
		Theme.shared.add(tvgResourceFor: "status-flash")
		Theme.shared.add(tvgResourceFor: "owncloud-logo")

		OCItem.registerIcons()
	}
}
