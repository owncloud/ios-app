//
//  ClientSidebarViewController.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 21.11.22.
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

public class ClientSidebarViewController: CollectionSidebarViewController, NavigationRevocationHandler {
	public var accountsSectionSubscription: OCDataSourceSubscription?
	public var accountsControllerSectionSource: OCDataSourceMapped?
	public var controllerConfiguration: AccountController.Configuration

	public init(context inContext: ClientContext, controllerConfiguration: AccountController.Configuration) {
		self.controllerConfiguration = controllerConfiguration

		super.init(context: inContext, sections: nil, navigationPusher: { sideBarViewController, viewController, animated in
			if let contentNavigationController = inContext.navigationController {
				contentNavigationController.setViewControllers([viewController], animated: false)
				sideBarViewController.splitViewController?.showDetailViewController(contentNavigationController, sender: sideBarViewController)
			}
		})
	}

	required public init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	var selectionChangeObservation: NSKeyValueObservation?

	override public func viewDidLoad() {
		super.viewDidLoad()

		// Set up AccountsControllerSource
		accountsControllerSectionSource = OCDataSourceMapped(source: OCBookmarkManager.shared.bookmarksDatasource, creator: { [weak self] (_, bookmarkDataItem) in
			if let bookmark = bookmarkDataItem as? OCBookmark, let self = self, let clientContext = self.clientContext {
				let controller = AccountController(bookmark: bookmark, context: clientContext, configuration: self.controllerConfiguration)

				return AccountControllerSection(with: controller)
			}

			return nil
		}, updater: nil, destroyer: { _, bookmarkItemRef, accountController in
			// Safely disconnect account controller if currently connected
		}, queue: .main)

		// Set up Collection View
		sectionsDataSource = accountsControllerSectionSource
		navigationItem.largeTitleDisplayMode = .never
		navigationItem.titleView = self.buildNavigationLogoView()

//		selectionChangeObservation = collectionView.observe(\.indexPathsForSelectedItems, changeHandler: { [weak self] view, change in
//			Log.debug("New selection: \(self?.collectionView.indexPathsForSelectedItems)")
//		})
	}

	// MARK: - NavigationRevocationHandler
	public func handleRevocation(event: NavigationRevocationEvent, context: ClientContext?, for viewController: UIViewController) {
		_ = sidebarContext.pushViewControllerToNavigation(context: sidebarContext, provider: { context in
			return UIViewController()
		}, push: true, animated: false)
	}
}

// MARK: - Branding
extension ClientSidebarViewController {
	func buildNavigationLogoView() -> ThemeView {
		let logoImage = UIImage(named: "branding-login-logo")
		let logoImageView = UIImageView(image: logoImage)
		logoImageView.contentMode = .scaleAspectFit
		logoImageView.translatesAutoresizingMaskIntoConstraints = false
		if let logoImage = logoImage {
			// Keep aspect ratio + scale logo to 90% of available height
			logoImageView.widthAnchor.constraint(equalTo: logoImageView.heightAnchor, multiplier: (logoImage.size.width / logoImage.size.height) * 0.9).isActive = true
		}

		let logoLabel = UILabel()
		logoLabel.translatesAutoresizingMaskIntoConstraints = false
		logoLabel.text = VendorServices.shared.appName
		logoLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
		logoLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
		logoLabel.setContentCompressionResistancePriority(.required, for: .vertical)

		let logoContainer = UIView()
		logoContainer.translatesAutoresizingMaskIntoConstraints = false
		logoContainer.addSubview(logoImageView)
		logoContainer.addSubview(logoLabel)
		logoContainer.setContentHuggingPriority(.required, for: .horizontal)
		logoContainer.setContentHuggingPriority(.required, for: .vertical)

		let logoWrapperView = ThemeView()
		logoWrapperView.addSubview(logoContainer)

		NSLayoutConstraint.activate([
			logoImageView.topAnchor.constraint(greaterThanOrEqualTo: logoContainer.topAnchor),
			logoImageView.bottomAnchor.constraint(lessThanOrEqualTo: logoContainer.bottomAnchor),
			logoImageView.centerYAnchor.constraint(equalTo: logoContainer.centerYAnchor),
			logoLabel.topAnchor.constraint(greaterThanOrEqualTo: logoContainer.topAnchor),
			logoLabel.bottomAnchor.constraint(lessThanOrEqualTo: logoContainer.bottomAnchor),
			logoLabel.centerYAnchor.constraint(equalTo: logoContainer.centerYAnchor),

			logoImageView.leadingAnchor.constraint(equalTo: logoContainer.leadingAnchor),
			logoLabel.leadingAnchor.constraint(equalToSystemSpacingAfter: logoImageView.trailingAnchor, multiplier: 1),
			logoLabel.trailingAnchor.constraint(equalTo: logoContainer.trailingAnchor),

			logoContainer.topAnchor.constraint(equalTo: logoWrapperView.topAnchor),
			logoContainer.bottomAnchor.constraint(equalTo: logoWrapperView.bottomAnchor),
			logoContainer.centerXAnchor.constraint(equalTo: logoWrapperView.centerXAnchor)
		])

		logoWrapperView.addThemeApplier({ (_, collection, _) in
			logoLabel.applyThemeCollection(collection, itemStyle: .logo)
			if !VendorServices.shared.isBranded {
				logoImageView.image = logoImageView.image?.tinted(with: collection.navigationBarColors.labelColor)
			}
		})

		return logoWrapperView
	}
}
