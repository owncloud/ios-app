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
		sidebarViewController = AppSidebarViewController(context: rootContext!, controllerConfiguration: controllerConfiguration)
		leftNavigationController = ThemeNavigationController(rootViewController: sidebarViewController!)

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
	var sidebarViewController: AppSidebarViewController?
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

public extension AppRootViewController {
	static func addIcons() {
		Theme.shared.add(tvgResourceFor: "owncloud-logo")
		Theme.shared.add(tvgResourceFor: "folder")
		Theme.shared.add(tvgResourceFor: "owncloud-logo")
		Theme.shared.add(tvgResourceFor: "status-flash")
	}
}
