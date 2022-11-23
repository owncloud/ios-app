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
import ownCloudAppShared

open class AppRootViewController: UIViewController {
	var clientContext: ClientContext
	var controllerConfiguration: AccountController.Configuration

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
