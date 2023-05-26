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
import ownCloudApp

extension ThemeCSSSelector {
	static let logo = ThemeCSSSelector(rawValue: "logo")
}

public class ClientSidebarViewController: CollectionSidebarViewController, NavigationRevocationHandler {
	public var accountsSectionSubscription: OCDataSourceSubscription?
	public var accountsControllerSectionSource: OCDataSourceMapped?
	public var controllerConfiguration: AccountController.Configuration

	public init(context inContext: ClientContext, controllerConfiguration: AccountController.Configuration) {
		self.controllerConfiguration = controllerConfiguration

		super.init(context: inContext, sections: nil, navigationPusher: { sideBarViewController, viewController, animated in
			// Push new view controller to detail view controller
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
	var combinedSectionsDatasource: OCDataSourceComposition?

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
			if let accountController = accountController as? AccountController {
				accountController.destroy() // needs to be called since AccountController keeps a reference to itself otherwise
			}
		}, queue: .main)

		// Combined data source
		if let accountsControllerSectionSource, let sidebarLinksDataSource = sidebarLinksDataSource {
			combinedSectionsDatasource = OCDataSourceComposition(sources: [ accountsControllerSectionSource, sidebarLinksDataSource ])
		}

		// Set up Collection View
		sectionsDataSource = combinedSectionsDatasource ?? accountsControllerSectionSource
		navigationItem.largeTitleDisplayMode = .never
		navigationItem.titleView = self.buildNavigationLogoView()

		// Add 10pt space at the top so that the first section's account doesn't "stick" to the top
		collectionView.contentInset.top += 10
	}

	deinit {
		accountsControllerSectionSource?.source = nil // Clear all AccountController instances from the controller and make OCDataSourceMapped call the destroyer
	}

	// MARK: - NavigationRevocationHandler
	public func handleRevocation(event: NavigationRevocationEvent, context: ClientContext?, for viewController: UIViewController) {
		if let history = sidebarContext.browserController?.history {
			// Log.debug("Revoke view controller: \(viewController) \(viewController.navigationItem.titleLabelText)")
			var hasHistoryItem = false

			// A view controller may appear more than once in history, so if a view controller is to be removed,
			// make sure that all history items for it are removed
			while let historyItem = history.item(for: viewController) {
				history.remove(item: historyItem, completion: nil)
				hasHistoryItem = true
			}

			// Dismiss view controllers that are being presented but are not part of the sidebar browser controller's history
			if !hasHistoryItem {
				if viewController.presentingViewController != nil {
					dismissDeep(viewController: viewController)
				}
			}
		}
	}

	func dismissDeep(viewController: UIViewController) {
		if viewController.presentingViewController != nil {
			var dismissStartViewController: UIViewController? = viewController

			while let deeperViewController = dismissStartViewController?.presentedViewController {
				dismissStartViewController = deeperViewController
			}

			dismissStartViewController?.dismiss(animated: true, completion: { [weak self] in
				self?.dismissDeep(viewController: viewController)
			})
		}
	}

	// MARK: - Selected Bookmark
	private var focusedBookmarkNavigationRevocationAction: NavigationRevocationAction?

	@objc public dynamic var focusedBookmark: OCBookmark? {
		didSet {
			Log.debug("New focusedBookmark:: \(focusedBookmark?.displayName ?? "-")")
		}
	}

	public override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		super.collectionView(collectionView, didSelectItemAt: indexPath)

		var newFocusedBookmark: OCBookmark?

		if let accountControllerSection = self.sectionOfCurrentSelection as? AccountControllerSection {
			newFocusedBookmark = accountControllerSection.accountController.connection?.bookmark

			if let newFocusedBookmarkUUID = newFocusedBookmark?.uuid {
				focusedBookmarkNavigationRevocationAction = NavigationRevocationAction(triggeredBy: [.connectionClosed(bookmarkUUID: newFocusedBookmarkUUID)], action: { [weak self] event, action in
					if self?.focusedBookmark?.uuid == newFocusedBookmarkUUID {
						self?.focusedBookmark = nil
					}
				})
				focusedBookmarkNavigationRevocationAction?.register(globally: true)
			}
		}

		focusedBookmark = newFocusedBookmark
	}

	public var sidebarLinksDataSource: OCDataSourceArray? {
		if let sidebarLinks = Branding.shared.sidebarLinks {
			let actions = sidebarLinks.compactMap { link in

				var image: UIImage?
				if let symbol = link.symbol, let anImage = OCSymbol.icon(forSymbolName: symbol) {
					image = anImage
				} else if let imageName = link.image, let anImage = UIImage(named: imageName) {
					image = anImage.withRenderingMode(.alwaysTemplate).scaledImageFitting(in: CGSize(width: 30, height: 30))
				}

				let action = OCAction(title: link.title, icon: image, action: { [weak self] _, _, completion in
					if let self = self {
						self.openURL(link.url)
					}
					completion(nil)
				})
				action.automaticDeselection = true

				return action
			}

			let linksDataSource = OCDataSourceArray(items: actions)

			let linksSection = CollectionViewSection(identifier: "links-section", dataSource: linksDataSource, cellStyle: CollectionViewCellStyle(with: .sideBar), cellLayout: .list(appearance: .sidebar), clientContext: clientContext)

			if let title = Branding.shared.sidebarLinksTitle {
				linksSection.boundarySupplementaryItems = [
					.mediumTitle(title, pinned: true)
				]
			}
			return OCDataSourceArray(items: [ linksSection ])
		}

		return nil
	}
}

// MARK: - Branding
extension ClientSidebarViewController {
	func buildNavigationLogoView() -> ThemeCSSView {
		let logoImage = UIImage(named: "branding-login-logo")
		let logoImageView = UIImageView(image: logoImage)
		logoImageView.cssSelector = .icon
		logoImageView.contentMode = .scaleAspectFit
		logoImageView.translatesAutoresizingMaskIntoConstraints = false
		if let logoImage = logoImage {
			// Keep aspect ratio + scale logo to 90% of available height
			logoImageView.widthAnchor.constraint(equalTo: logoImageView.heightAnchor, multiplier: (logoImage.size.width / logoImage.size.height) * 0.9).isActive = true
		}

		let logoLabel = ThemeCSSLabel()
		logoLabel.translatesAutoresizingMaskIntoConstraints = false
		logoLabel.text = VendorServices.shared.appName
		logoLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
		logoLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
		logoLabel.setContentCompressionResistancePriority(.required, for: .vertical)

		let logoContainer = ThemeCSSView(withSelectors: [.logo])
		logoContainer.translatesAutoresizingMaskIntoConstraints = false
		logoContainer.addSubview(logoImageView)
		logoContainer.addSubview(logoLabel)
		logoContainer.setContentHuggingPriority(.required, for: .horizontal)
		logoContainer.setContentHuggingPriority(.required, for: .vertical)

		let logoWrapperView = ThemeCSSView()
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
			if !VendorServices.shared.isBranded, let logoColor = collection.css.getColor(.stroke, for: logoImageView) {
				logoImageView.image = logoImageView.image?.tinted(with: logoColor)
			}
		})

		return logoWrapperView
	}
}
