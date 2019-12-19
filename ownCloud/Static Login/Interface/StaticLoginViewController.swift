//
//  StaticLoginViewController.swift
//  ownCloud
//
//  Created by Felix Schwarz on 26.11.18.
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

class StaticLoginViewController: UIViewController, Themeable {
	let loginBundle : StaticLoginBundle

	var backgroundImageView : UIImageView?

	var headerContainerView : UIView?
	var headerLogoView : UIImageView?

	var contentContainerView : UIView?

	var contentViewController : UIViewController? {
		willSet {
			contentViewController?.willMove(toParent: nil)
		}

		didSet {
			if contentContainerView != nil, contentViewController?.view != nil {
				contentContainerView?.addSubview(contentViewController!.view!)
				contentViewController!.view!.translatesAutoresizingMaskIntoConstraints = false

				NSLayoutConstraint.activate([
					contentViewController!.view!.topAnchor.constraint(equalTo: contentContainerView!.safeAreaLayoutGuide.topAnchor),
					contentViewController!.view!.bottomAnchor.constraint(equalTo: contentContainerView!.safeAreaLayoutGuide.bottomAnchor),
					contentViewController!.view!.leftAnchor.constraint(equalTo: contentContainerView!.safeAreaLayoutGuide.leftAnchor, constant: 20),
					contentViewController!.view!.rightAnchor.constraint(equalTo: contentContainerView!.safeAreaLayoutGuide.rightAnchor, constant: -20)
				])

				// Animate transition
				if oldValue != nil {
					contentViewController?.view.alpha = 0.0

					UIView.animate(withDuration: 0.25, animations: {
						oldValue?.view?.alpha = 0.0
						self.contentViewController?.view.alpha = 1.0
					}, completion: { (_) in
						oldValue?.view?.removeFromSuperview()
						oldValue?.removeFromParent()

						oldValue?.view?.alpha = 1.0

						self.contentViewController?.didMove(toParent: self)
					})
				} else {
					self.contentViewController?.didMove(toParent: self)
				}
			}
		}
	}

	var toolbarShown : Bool = false {
		didSet {
			if self.toolbarItems == nil, toolbarShown {
				let settingsBarButtonItem = UIBarButtonItem(title: "Settings".localized, style: UIBarButtonItem.Style.plain, target: self, action: #selector(settings))
				settingsBarButtonItem.accessibilityIdentifier = "settingsBarButtonItem"

				if VendorServices.shared.isBranded {
					self.toolbarItems = [
						UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil),
						settingsBarButtonItem
					]
				} else {
					let feedbackBarButtonItem = UIBarButtonItem(title: "Feedback".localized, style: UIBarButtonItem.Style.plain, target: self, action: #selector(sendFeedback))
					feedbackBarButtonItem.accessibilityIdentifier = "helpBarButtonItem"

					self.toolbarItems = [
						feedbackBarButtonItem,
						UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil),
						settingsBarButtonItem
					]
				}
			}

			self.navigationController?.setToolbarHidden(!toolbarShown, animated: true)
		}
	}
	init(with staticLoginBundle: StaticLoginBundle) {
		loginBundle = staticLoginBundle

		super.init(nibName: nil, bundle: nil)
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func loadView() {
		let rootView = UIView()
		let headerVerticalSpacing : CGFloat = 40

		backgroundImageView = UIImageView()
		backgroundImageView?.translatesAutoresizingMaskIntoConstraints = false
		rootView.addSubview(backgroundImageView!)

		headerContainerView = UIView()
		headerContainerView?.translatesAutoresizingMaskIntoConstraints = false
		rootView.addSubview(headerContainerView!)

		contentContainerView = UIView()
		contentContainerView?.translatesAutoresizingMaskIntoConstraints = false
		rootView.addSubview(contentContainerView!)

		headerLogoView = UIImageView()
		headerLogoView?.translatesAutoresizingMaskIntoConstraints = false
		headerContainerView?.addSubview(headerLogoView!)

		NSLayoutConstraint.activate([
			// Background image view
			backgroundImageView!.topAnchor.constraint(equalTo: rootView.topAnchor),
			backgroundImageView!.bottomAnchor.constraint(equalTo: rootView.bottomAnchor),
			backgroundImageView!.leftAnchor.constraint(equalTo: rootView.leftAnchor),
			backgroundImageView!.rightAnchor.constraint(equalTo: rootView.rightAnchor),

			// Header
				// Logo size
				headerLogoView!.leftAnchor.constraint(equalTo: headerContainerView!.safeAreaLayoutGuide.leftAnchor),
				headerLogoView!.rightAnchor.constraint(equalTo: headerContainerView!.safeAreaLayoutGuide.rightAnchor),
				headerLogoView!.heightAnchor.constraint(equalTo: rootView.heightAnchor, multiplier: 0.25, constant: 0),

				// Logo and label position
				headerLogoView!.topAnchor.constraint(equalTo: rootView.safeAreaLayoutGuide.topAnchor, constant: headerVerticalSpacing),
				headerLogoView!.centerXAnchor.constraint(equalTo: rootView.centerXAnchor),
				headerLogoView!.bottomAnchor.constraint(equalTo: headerContainerView!.bottomAnchor, constant: -20),

				// Header position
				headerContainerView!.topAnchor.constraint(equalTo: rootView.topAnchor),
				headerContainerView!.leftAnchor.constraint(equalTo: rootView.leftAnchor),
				headerContainerView!.rightAnchor.constraint(equalTo: rootView.rightAnchor),

			// Content
				// Content container
				contentContainerView!.topAnchor.constraint(equalTo: headerContainerView!.bottomAnchor),
				contentContainerView!.bottomAnchor.constraint(equalTo: rootView.bottomAnchor),
				contentContainerView!.leftAnchor.constraint(equalTo: rootView.leftAnchor),
				contentContainerView!.rightAnchor.constraint(equalTo: rootView.rightAnchor)
		])

		self.view = rootView

		Theme.shared.register(client: self, applyImmediately: true)
	}

	func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
//		self.view.backgroundColor = collection.tableBackgroundColor
//		self.headerView?.backgroundColor = collection.tableGroupBackgroundColor
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		OCItem.registerIcons()

		if let organizationLogoName = loginBundle.organizationLogoName {
			let image = UIImage(named: organizationLogoName)
			headerLogoView?.image = image
			headerLogoView?.contentMode = .scaleAspectFit
		}

		if let organizationBackgroundName = loginBundle.organizationBackgroundName {
			backgroundImageView?.image = UIImage(named: organizationBackgroundName)
			backgroundImageView?.contentMode = .scaleAspectFill
		}

		contentContainerView?.backgroundColor = UIColor(white: 0.0, alpha: 0.5)
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		if contentViewController == nil {
			showFirstScreen()
		}
	}

	@objc func showFirstScreen() {
		var firstViewController : UIViewController?

		if OCBookmarkManager.shared.bookmarks.count > 0 {
			// Login selection view
			firstViewController = self.buildBookmarkSelector()
		} else {
			// Setup flow
			if loginBundle.profiles.count > 1 {
				// Profile setup selector
				firstViewController = buildProfileSetupSelector(title: "Welcome")
			} else {
				// Single Profile setup
				firstViewController = buildSetupViewController(for: loginBundle.profiles.first!)
			}
		}

		if firstViewController != nil {
			let navigationViewController = ThemeNavigationController(rootViewController: firstViewController!)

			navigationViewController.isNavigationBarHidden = true

			self.contentViewController = navigationViewController
		}
	}

	// MARK: - View controller builders
	func buildProfileSetupSelector(title : String, includeCancelOption: Bool = false) -> StaticLoginStepViewController {
		let selectorViewController : StaticLoginStepViewController = StaticLoginStepViewController(loginViewController: self)
		let profileSection = StaticTableViewSection(headerTitle: "")

		profileSection.addStaticHeader(title: title, message: "Please pick a profile to begin setup:")

		for profile in loginBundle.profiles {
			profileSection.add(row: StaticTableViewRow(rowWithAction: { (row, _) in
				if let stepViewController = row.viewController as? StaticLoginStepViewController {
					if let setupViewController = stepViewController.loginViewController?.buildSetupViewController(for: profile) {
						stepViewController.navigationController?.pushViewController(setupViewController, animated: true)
					}
				}
			}, title: profile.name!, accessoryType: .disclosureIndicator, identifier: profile.identifier))
		}

		if includeCancelOption {
			let (_, cancelButton) = profileSection.addButtonFooter(cancelLabel: "Cancel")

			cancelButton?.addTarget(selectorViewController, action: #selector(selectorViewController.popViewController), for: .touchUpInside)
		}

		selectorViewController.addSection(profileSection)

		return (selectorViewController)
	}

	func buildSetupViewController(for profile: StaticLoginProfile) -> StaticLoginSetupViewController {
		return StaticLoginSetupViewController(loginViewController: self, profile: profile)
	}

	func buildBookmarkSelector() -> ServerListTableViewController {
		let serverList = StaticLoginServerListViewController(style: .grouped)

		serverList.staticLoginViewController = self
		serverList.hasToolbar = false

		return serverList
	}

	func profile(for staticLoginProfileIdentifier: StaticLoginProfileIdentifier) -> StaticLoginProfile? {
		return loginBundle.profiles.first(where: { (profile) -> Bool in
			return (profile.identifier == staticLoginProfileIdentifier)
		})
	}

	func switchToTheme(with styleIdentifier: ThemeStyleIdentifier) {
		if let themeStyle = ThemeStyle.forIdentifier(styleIdentifier) {
			Theme.shared.switchThemeCollection(ThemeCollection(with: themeStyle))
		}
	}

	// MARK: - Actions
	@objc func sendFeedback() {
		VendorServices.shared.sendFeedback(from: self)
	}

	@objc func settings() {
        	let viewController : SettingsViewController = SettingsViewController(style: .grouped)
        	let navigationViewController : ThemeNavigationController = ThemeNavigationController(rootViewController: viewController)

		self.present(navigationViewController, animated: true, completion: nil)
	}

	func openBookmark(_ bookmark: OCBookmark, closeHandler: (() -> Void)? = nil) {
		let clientRootViewController = ClientRootViewController(bookmark: bookmark)
		clientRootViewController.modalPresentationStyle = .overFullScreen

		clientRootViewController.afterCoreStart {
			OCBookmarkManager.lastBookmarkSelectedForConnection = bookmark

			// Set up custom push transition for presentation
			if let navigationController = self.navigationController {
				let transitionDelegate = PushTransitionDelegate()

				clientRootViewController.pushTransition = transitionDelegate // Keep a reference, so it's still around on dismissal
				clientRootViewController.transitioningDelegate = transitionDelegate
				clientRootViewController.modalPresentationStyle = .custom

				navigationController.present(clientRootViewController, animated: true, completion: {
				})
			}
			self.showFirstScreen()
		}
	}
}
