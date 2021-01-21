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

		let tableViewController = MoreStaticTableViewController(style: .grouped)
		let header = MoreViewHeader(for: item, with: core)
		let moreViewController = MoreViewController(item: item, core: core, header: header, viewController: tableViewController)

		if core.connectionStatus == .online {
			if core.connection.capabilities?.sharingAPIEnabled == 1 {
				if item.isSharedWithUser || item.isShared {
					let progressView = UIActivityIndicatorView(style: Theme.shared.activeCollection.activityIndicatorViewStyle)
					progressView.startAnimating()

					let row = StaticTableViewRow(rowWithAction: nil, title: "Searching Shares…".localized, alignment: .left, accessoryView: progressView, identifier: "share-searching")
					let placeholderRow = StaticTableViewRow(rowWithAction: nil, title: "", alignment: .left, identifier: "share-empty-searching")
					self.updateSharingSection(sectionIdentifier: "share-section", rows: [placeholderRow, row], tableViewController: tableViewController, contentViewController: moreViewController)

					core.unifiedShares(for: item, completionHandler: { (shares) in
						OnMainThread {
							let shareRows = self.shareRows(shares: shares, item: item, presentingController: moreViewController, context: context)
							self.updateSharingSection(sectionIdentifier: "share-section", rows: shareRows, tableViewController: tableViewController, contentViewController: moreViewController)
						}
					})
				} else {
					var shareRows : [StaticTableViewRow] = []
					if item.isShareable {
						shareRows.append(self.shareAsGroupRow(item: item, presentingController: moreViewController, context: context))
					}
					if let publicLinkRow = self.shareAsPublicLinkRow(item: item, presentingController: moreViewController, context: context) {
						shareRows.append(publicLinkRow)
					}
					if shareRows.count > 0 {
						tableViewController.insertSection(StaticTableViewSection(headerTitle: nil, footerTitle: nil, identifier: "share-section", rows: shareRows), at: 0, animated: false)
					}
				}
			} else {
				if let publicLinkRow = self.shareAsPublicLinkRow(item: item, presentingController: moreViewController, context: context) {
					tableViewController.insertSection(StaticTableViewSection(headerTitle: nil, footerTitle: nil, identifier: "share-section", rows: [publicLinkRow]), at: 0, animated: false)
				}
			}
		}

		let title = NSAttributedString(string: "Actions".localized, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 20, weight: .heavy)])

		let actions = Action.sortedApplicableActions(for: context)

		actions.forEach({
			$0.actionWillRunHandler = { [weak moreViewController] (_ donePreparing: @escaping () -> Void) in
				moreViewController?.dismiss(animated: true, completion: donePreparing)
			}

			$0.progressHandler = progressHandler

			$0.completionHandler = completionHandler
		})

		let actionsRows: [StaticTableViewRow] = actions.compactMap({return $0.provideStaticRow()})

		tableViewController.addSection(MoreStaticTableViewSection(headerAttributedTitle: title, identifier: "actions-section", rows: actionsRows))

		return moreViewController
	}
}

// MARK: - Licensing
extension Action {
	public func proceedWithLicensing(from viewController: UIViewController) -> Bool {
		if !isLicensed {
			if let core = core, let requirements = type(of:self).licenseRequirements {
				OnMainThread {
					OCLicenseManager.appStoreProvider?.refreshProductsIfNeeded(completionHandler: { (error) in
						OnMainThread {
							if error != nil {
								let alertController = ThemedAlertController(with: "Error loading product info from App Store".localized, message: error!.localizedDescription)

								viewController.present(alertController, animated: true)
							} else {
								let offersViewController = LicenseOffersViewController(withFeature: requirements.feature, in: core.licenseEnvironment)

								viewController.present(asCard: MoreViewController(header: offersViewController.cardHeaderView!, viewController: offersViewController), animated: true)
							}
						}
					})
				}
			}

			return false
		}

		return true
	}
}

// MARK: - Sharing
private extension Action {

	class func shareRows(shares: [OCShare], item: OCItem, presentingController: UIViewController, context: ActionContext) -> [StaticTableViewRow] {
		var shareRows: [StaticTableViewRow] = []

		var userTitle = ""
		var linkTitle = ""
		var hasUserGroupSharing = false
		var hasLinkSharing = false

		if item.isSharedWithUser {
			// find shares by others
			if let itemOwner = item.owner, itemOwner.isRemote, let ownerName = itemOwner.displayName ?? itemOwner.userName {
				// - remote shares
				userTitle = String(format: "Shared by %@".localized, ownerName)
				hasUserGroupSharing = true
			} else {
				// - local shares
				for share in shares {
					if let ownerName = share.itemOwner?.displayName {
						userTitle = String(format: "Shared by %@".localized, ownerName)
						hasUserGroupSharing = true
						break
					}
				}
			}
		} else {
			// find Shares by me
			let privateShares = shares.filter { (share) -> Bool in
				return share.type != .link
			}

			if privateShares.count > 0 {
				let title = ((privateShares.count > 1) ? "Recipients" : "Recipient").localized

				userTitle = "\(privateShares.count) \(title)"
				hasUserGroupSharing = true
			}
		}

		// find Public link shares
		let linkShares = shares.filter { (share) -> Bool in
			return share.type == .link
		}
		if linkShares.count > 0 {
			let title = ((linkShares.count > 1) ? "Links" : "Link").localized

			linkTitle.append("\(linkShares.count) \(title)")
			hasLinkSharing = true
		}

		if hasUserGroupSharing {
			let addGroupRow = StaticTableViewRow(buttonWithAction: { [weak presentingController, weak context] (_, _) in
				if let context = context, let presentingController = presentingController, let core = context.core {
					let sharingViewController = GroupSharingTableViewController(core: core, item: item)
					sharingViewController.shares = shares

					self.dismiss(presentingController: presentingController, andPresent: sharingViewController, on: context.viewController)
				}
			}, title: userTitle, style: .plain, image: nil, imageWidth: nil, alignment: .left, accessoryType: .disclosureIndicator)
			shareRows.append(addGroupRow)
		} else if item.isShareable {
			shareRows.append(self.shareAsGroupRow(item: item, presentingController: presentingController, context: context))
		}

		if hasLinkSharing, let core = context.core, core.connection.capabilities?.publicSharingEnabled == true {
			let addGroupRow = StaticTableViewRow(buttonWithAction: { [weak presentingController, weak context] (_, _) in
				if let context = context, let presentingController = presentingController {
					let sharingViewController = PublicLinkTableViewController(core: core, item: item)
					sharingViewController.shares = shares

					self.dismiss(presentingController: presentingController, andPresent: sharingViewController, on: context.viewController)
				}
			}, title: linkTitle, style: .plain, image: nil, imageWidth: nil, alignment: .left, accessoryType: .disclosureIndicator)
			shareRows.append(addGroupRow)
		} else if let publicLinkRow = self.shareAsPublicLinkRow(item: item, presentingController: presentingController, context: context) {
			shareRows.append(publicLinkRow)
		}

		return shareRows
	}

	private class func updateSharingSection(sectionIdentifier: String, rows: [StaticTableViewRow], tableViewController: MoreStaticTableViewController, contentViewController: MoreViewController) {
		if let section = tableViewController.sectionForIdentifier(sectionIdentifier) {
			tableViewController.removeSection(section)
		}
		if rows.count > 0 {
			tableViewController.insertSection(MoreStaticTableViewSection(identifier: "share-section", rows: rows), at: 0, animated: false)
		}
	}

	private class func shareAsGroupRow(item : OCItem, presentingController: UIViewController, context: ActionContext) -> StaticTableViewRow {
		let title = ((item.type == .collection) ? "Share this folder" : "Share this file").localized

		let addGroupRow = StaticTableViewRow(buttonWithAction: { [weak presentingController, weak context] (_, _) in
			if let context = context, let presentingController = presentingController, let core = context.core {
				self.dismiss(presentingController: presentingController,
							 andPresent: GroupSharingTableViewController(core: core, item: item),
							 on: context.viewController)
			}
		}, title: title, style: .plain, image: nil, imageWidth:nil, imageTintColorKey: nil, alignment: .left, identifier: "share-add-group", accessoryView: UIImageView(image: UIImage(named: "group")))

		return addGroupRow
	}

	private class func shareAsPublicLinkRow(item : OCItem, presentingController: UIViewController, context: ActionContext) -> StaticTableViewRow? {
		let addGroupRow = StaticTableViewRow(buttonWithAction: { [weak presentingController, weak context] (_, _) in
			if let context = context, let presentingController = presentingController, let core = context.core {
				self.dismiss(presentingController: presentingController,
							 andPresent: PublicLinkTableViewController(core: core, item: item),
							 on: context.viewController)
			}
			}, title: "Links".localized, style: .plain, image: nil, imageWidth: nil, alignment: .left, identifier: "share-add-group", accessoryView: UIImageView(image: UIImage(named: "link")))

		return addGroupRow
	}

	private class func dismiss(presentingController: UIViewController, andPresent viewController: UIViewController, on hostViewController: UIViewController?) {
		presentingController.dismiss(animated: true)

		guard let hostViewController = hostViewController else { return }

		let navigationController = ThemeNavigationController(rootViewController: viewController)

		hostViewController.present(navigationController, animated: true, completion: nil)
	}
}
