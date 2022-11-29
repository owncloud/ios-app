//
//  OCAction+Interactions.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 30.05.22.
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

extension OCAction : DataItemSelectionInteraction {
	public func handleSelection(in viewController: UIViewController?, with context: ClientContext?, completion: ((Bool) -> Void)?) -> Bool {
		guard (self as? CollectionSidebarAction) == nil else {
			// Use openItem() for CollectionSidebarAction
			return false
		}

		var options: [OCActionRunOptionKey:Any] = [:]

		if let context {
			options[.clientContext] = context
		}

		run(options: options, completionHandler: { error in
			completion?(error == nil)
		})

		return true
	}

	public func allowSelection(in viewController: UIViewController?, section: CollectionViewSection?, with context: ClientContext?) -> Bool {
		return selectable
	}
}

extension OCAction : DataItemDropInteraction {
	public func allowDropOperation(for session: UIDropSession, with context: ClientContext?) -> UICollectionViewDropProposal? {
		if supportsDrop == false {
			return nil
		}

		if session.localDragSession == nil {
			return nil
		}

		return UICollectionViewDropProposal(operation: .move, intent: .insertIntoDestinationIndexPath)
	}

	public func performDropOperation(of items: [UIDragItem], with context: ClientContext?, handlingCompletion: @escaping (Bool) -> Void) {
		var options: [OCActionRunOptionKey:Any] = [:]

		if let context {
			options[.clientContext] = context
		}

		run(options: options, completionHandler: { error in
			handlingCompletion(error == nil)
		})
	}
}
