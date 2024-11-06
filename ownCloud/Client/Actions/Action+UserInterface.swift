//
//  Action+UserInterface.swift
//  ownCloud
//
//  Created by Felix Schwarz on 17.07.20.
//  Copyright © 2020 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2020, ownCloud GmbH.
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

extension Action {
	// MARK: - Provide Card view controller

	class public func cardViewController(for item: OCItem, with context: ActionContext, progressHandler: ActionProgressHandler? = nil, completionHandler: ((Action, Error?) -> Void)? = nil) -> UIViewController? {
		guard let core = context.core else { return nil }

		let tableViewController = MoreStaticTableViewController(style: .insetGrouped)
		let header = MoreViewHeader(for: item, with: core)
		let moreViewController = FrameViewController(header: header, viewController: tableViewController)
		let actions = Action.sortedApplicableActions(for: context)

		moreViewController.watermark(
			username: core.bookmark.userName,
			userMail: core.bookmark.user?.emailAddress
		)

		actions.forEach({
			$0.actionWillRunHandler = { [weak moreViewController] (_ donePreparing: @escaping () -> Void) in
				moreViewController?.dismiss(animated: true, completion: donePreparing)
			}

			$0.progressHandler = progressHandler

			$0.completionHandler = completionHandler
		})

		let actionsRows: [StaticTableViewRow] = actions.compactMap({return $0.provideStaticRow()})

		tableViewController.addSection(StaticTableViewSection(headerTitle: nil, identifier: "actions-section", rows: actionsRows))

		return moreViewController
	}
}

// MARK: - Licensing
extension Action {
	public func proceedWithLicensing(from viewController: UIViewController) -> Bool {
		if !isLicensed {
			if let core = core, let requirements = type(of:self).licenseRequirements {
				OnMainThread {
					#if !DISABLE_APPSTORE_LICENSING
					OCLicenseManager.appStoreProvider?.refreshProductsIfNeeded(completionHandler: { (error) in
						OnMainThread {
							if error != nil {
								let alertController = ThemedAlertController(with: OCLocalizedString("Error loading product info from App Store", nil), message: error!.localizedDescription)

								viewController.present(alertController, animated: true)
							} else {
								let offersViewController = LicenseOffersViewController(withFeature: requirements.feature, in: core.licenseEnvironment)

								viewController.present(asCard: FrameViewController(header: offersViewController.cardHeaderView!, viewController: offersViewController), animated: true)
							}
						}
					})
					#endif
				}
			}

			return false
		}

		return true
	}
}

// MARK: - Sharing
private extension Action {
	private class func dismiss(presentingController: UIViewController, andPresent viewController: UIViewController, on hostViewController: UIViewController?) {
		presentingController.dismiss(animated: true)

		guard let hostViewController = hostViewController else { return }

		let navigationController = ThemeNavigationController(rootViewController: viewController)

		hostViewController.present(navigationController, animated: true, completion: nil)
	}
}
