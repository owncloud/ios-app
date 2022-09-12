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
		run(options: nil, completionHandler: { error in
			completion?(error == nil)
		})

		return true
	}
}

extension OCAction : DataItemDropInteraction {
	public func allowDropOperation(for session: UIDropSession, with context: ClientContext?) -> UICollectionViewDropProposal? {
		if session.localDragSession == nil {
			return nil
		}

		return UICollectionViewDropProposal(operation: .move, intent: .insertIntoDestinationIndexPath)
	}

	public func performDropOperation(of items: [UIDragItem], with context: ClientContext?, handlingCompletion: @escaping (Bool) -> Void) {
		run(options: nil, completionHandler: { error in
			handlingCompletion(error == nil)
		})
	}
}
