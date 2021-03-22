//
//  ClientItemResolvingCell.swift
//  ownCloud
//
//  Created by Felix Schwarz on 18.07.19.
//  Copyright © 2019 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2019, ownCloud GmbH.
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

class ClientItemResolvingCell: ClientItemCell {
	var itemTracker : OCCoreItemTracking?

	// MARK: - Resolve item from path
	var itemResolutionPath : String? {
		didSet {
			self.item = nil

			if let atPath = itemResolutionPath {
				self.itemResolutionLocalID = nil
				self.itemTracker = core?.trackItem(atPath: atPath, trackingHandler: { (error, item, isInitial) in
					if error == nil, let item = item, isInitial {
						OnMainThread {
							self.item = item
							self.itemTracker = nil // unless isInitial is removed from above "if", that's it - we can stop tracking as any updates won't be used anyway
						}
					} else if (error != nil) || (item == nil) {
						OnMainThread {
							self.resolutionFailed(error: error)
						}
					}
				})
			} else {
				self.itemTracker = nil
			}
		}
	}

	var itemResolutionLocalID : String? {
		didSet {
			if let itemResolutionLocalID = itemResolutionLocalID {
				self.item = nil
				self.itemResolutionPath = nil

				core?.retrieveItemFromDatabase(forLocalID: itemResolutionLocalID, completionHandler: { (error, _, item) in
					if let item = item, item.localID == self.itemResolutionLocalID {
						OnMainThread {
							self.item = item
						}
					} else {
						OnMainThread {
							self.resolutionFailed(error: error)
						}
					}
				})
			}
		}
	}

	func resolutionFailed(error: Error?) {

	}

	deinit {
		itemTracker = nil
	}
}
