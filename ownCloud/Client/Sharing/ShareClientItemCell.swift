//
//  ShareClientItemCell.swift
//  ownCloud
//
//  Created by Matthias Hühne on 16.05.19.
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

class ShareClientItemCell: ClientItemCell {

	var itemTracker : OCCoreItemTracking?
	var iconSize : CGSize = CGSize(width: 40, height: 40)

	// MARK: - Share Item

	var share : OCShare? {
		didSet {
			if let share = share {
				self.titleLabel.text = share.itemPath
				if share.itemType == .collection {
					self.iconView.image = Theme.shared.image(for: "folder", size: iconSize)
				} else {
					self.iconView.image = Theme.shared.image(for: "file", size: iconSize)
				}
				itemTracker = core?.trackItem(atPath: share.itemPath, trackingHandler: { (error, item, isInitial) in
					if error == nil, let item = item, isInitial {
						OnMainThread {
							self.item = item
						}
					}
				})
			}
		}
	}

	deinit {
		itemTracker = nil
	}

}
