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
	var headerLogoView : VectorImageView?
	var headerLabel : UILabel?

	var contentContainerView : UIView?

	var contentViewController : UIViewController? {
		willSet {
			contentViewController?.willMove(toParentViewController: nil)
		}

		didSet {
			if contentContainerView != nil, contentViewController?.view != nil {
				contentContainerView?.addSubview(contentViewController!.view!)
				contentViewController!.view!.translatesAutoresizingMaskIntoConstraints = false

				if let stepViewController = contentViewController as? StaticLoginStepViewController, stepViewController.centerVertically {

					NSLayoutConstraint.activate([
						contentViewController!.view!.topAnchor.constraint(greaterThanOrEqualTo: contentContainerView!.safeAreaLayoutGuide.topAnchor),
						contentViewController!.view!.heightAnchor.constraint(equalToConstant: stepViewController.tableView.contentSize.height),
						contentViewController!.view!.centerYAnchor.constraint(equalTo: contentContainerView!.safeAreaLayoutGuide.centerYAnchor),
						contentViewController!.view!.bottomAnchor.constraint(lessThanOrEqualTo: contentContainerView!.safeAreaLayoutGuide.bottomAnchor),
						contentViewController!.view!.leftAnchor.constraint(equalTo: contentContainerView!.safeAreaLayoutGuide.leftAnchor),
						contentViewController!.view!.rightAnchor.constraint(equalTo: contentContainerView!.safeAreaLayoutGuide.rightAnchor)
					])
				} else {
					NSLayoutConstraint.activate([
						contentViewController!.view!.topAnchor.constraint(equalTo: contentContainerView!.safeAreaLayoutGuide.topAnchor),
						contentViewController!.view!.bottomAnchor.constraint(equalTo: contentContainerView!.safeAreaLayoutGuide.bottomAnchor),
						contentViewController!.view!.leftAnchor.constraint(equalTo: contentContainerView!.safeAreaLayoutGuide.leftAnchor, constant: 20),
						contentViewController!.view!.rightAnchor.constraint(equalTo: contentContainerView!.safeAreaLayoutGuide.rightAnchor, constant: -20)
					])
				}

				// Animate transition
				if oldValue != nil {
					contentViewController?.view.alpha = 0.0

					UIView.animate(withDuration: 0.25, animations: {
						oldValue?.view.alpha = 0.0
						self.contentViewController?.view.alpha = 1.0
					}, completion: { (_) in
						oldValue?.view?.removeFromSuperview()
						oldValue?.removeFromParentViewController()

						oldValue?.view.alpha = 1.0

						self.contentViewController?.didMove(toParentViewController: self)
					})
				} else {
					self.contentViewController?.didMove(toParentViewController: self)
				}
			}
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

		headerLogoView = VectorImageView()
		headerLogoView?.translatesAutoresizingMaskIntoConstraints = false
		headerContainerView?.addSubview(headerLogoView!)

		headerLabel = UILabel()
		headerLabel?.translatesAutoresizingMaskIntoConstraints = false
		headerLabel?.font = UIFont.systemFont(ofSize: UIFont.systemFontSize * 2.5, weight: .semibold)
		headerLabel?.textAlignment = .center
		headerContainerView?.addSubview(headerLabel!)

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
				headerLogoView!.heightAnchor.constraint(equalToConstant: 96),

				// Logo and label position
				headerLogoView!.topAnchor.constraint(equalTo: rootView.safeAreaLayoutGuide.topAnchor, constant: headerVerticalSpacing),
				headerLogoView!.centerXAnchor.constraint(equalTo: rootView.centerXAnchor),

				headerLogoView!.bottomAnchor.constraint(equalTo: headerLabel!.topAnchor, constant: -20),

				headerLabel!.bottomAnchor.constraint(equalTo: headerContainerView!.bottomAnchor, constant: -headerVerticalSpacing),
				headerLabel!.leftAnchor.constraint(equalTo: headerContainerView!.safeAreaLayoutGuide.leftAnchor, constant: 10),
				headerLabel!.rightAnchor.constraint(equalTo: headerContainerView!.safeAreaLayoutGuide.rightAnchor, constant: -20),

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

		self.headerLabel?.applyThemeCollection(collection)
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		Theme.shared.add(tvgResourceFor: "owncloud-logo")

		headerLabel?.text = loginBundle.organizationName

		Theme.shared.add(tvgResourceFor: loginBundle.organizationLogoName!)
		headerLogoView?._vectorImage = Theme.shared.tvgImage(for: loginBundle.organizationLogoName!)

		backgroundImageView?.image = UIImage(named: loginBundle.organizationBackgroundName!)
		backgroundImageView?.contentMode = .scaleAspectFill

		contentContainerView?.backgroundColor = UIColor(white: 0.0, alpha: 0.5)

		if contentViewController == nil {
			showFirstScreen()
		}
	}

	func showFirstScreen() {
		var firstViewController : UIViewController?

		if OCBookmarkManager.shared.bookmarks.count > 0 {
			// Login selection view
		} else {
			// Setup flow
			if loginBundle.profiles.count > 1 {
				// Profile setup selector
				firstViewController = buildProfileSetupSelector()
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

	func buildProfileSetupSelector() -> StaticLoginStepViewController {
		let selectorViewController : StaticLoginStepViewController = StaticLoginStepViewController(loginViewController: self)
		let profileSection = StaticTableViewSection(headerTitle: "")
		let headerView = StaticLoginStepViewController.buildHeader(title: "Welcome!", message: "Please pick a profile to begin setup:")

		profileSection.headerView = headerView

		for profile in loginBundle.profiles {
			profileSection.add(row: StaticTableViewRow(rowWithAction: { (row, _) in
				if let stepViewController = row.viewController as? StaticLoginStepViewController {
					if let setupViewController = stepViewController.loginViewController?.buildSetupViewController(for: profile) {
						stepViewController.navigationController?.pushViewController(setupViewController, animated: true)
					}
				}
			}, title: profile.name!, accessoryType: .disclosureIndicator, identifier: profile.identifier))
		}

		selectorViewController.addSection(profileSection)

		return (selectorViewController)
	}

	func buildSetupViewController(for profile: StaticLoginProfile) -> StaticLoginSetupViewController {
		return StaticLoginSetupViewController(loginViewController: self, profile: profile)
	}
}
