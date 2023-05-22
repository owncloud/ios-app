//
//  AppRootViewController+ItemActions.swift
//  ownCloud
//
//  Created by Felix Schwarz on 21.11.22.
//  Copyright © 2022 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2022, ownCloud GmbH.
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

extension AppRootViewController: ViewItemAction {
	public func provideViewer(for item: OCDataItem, context: ClientContext) -> UIViewController? {
		let queryDatasource = context.queryDatasource ?? context.query?.queryResultsDataSource

		guard let item = item as? OCItem, context.core != nil else {
			return nil
		}

		let itemViewController = DisplayHostViewController(clientContext: context, selectedItem: item, queryDataSource: queryDatasource)
		itemViewController.hidesBottomBarWhenPushed = true
		itemViewController.progressSummarizer = context.progressSummarizer

		return itemViewController
	}
}

extension AppRootViewController: MoreItemAction {
	public func moreOptions(for item: OCDataItem, at locationIdentifier: OCExtensionLocationIdentifier, context: ClientContext, sender: AnyObject?) -> Bool {
		guard let sender = sender, let core = context.core, let item = item as? OCItem else {
			return false
		}
		let originatingViewController : UIViewController = context.originatingViewController ?? self
		let actionsLocation = OCExtensionLocation(ofType: .action, identifier: locationIdentifier)
		let actionContext = ActionContext(viewController: originatingViewController, clientContext: context, core: core, query: context.query, items: [item], location: actionsLocation, sender: sender)

		if let moreViewController = Action.cardViewController(for: item, with: actionContext, progressHandler: context.actionProgressHandlerProvider?.makeActionProgressHandler(), completionHandler: nil) {
			originatingViewController.present(asCard: moreViewController, animated: true)
		}

		return true
	}
}
