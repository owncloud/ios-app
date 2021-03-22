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
import ownCloudAppShared

class ShareClientItemCell: ClientItemResolvingCell {
	var iconSize : CGSize = CGSize(width: 40, height: 40)

	// MARK: - Share Item
	override func titleLabelString(for item: OCItem?) -> String {
		if let shareItemPath = share?.itemPath {
			return shareItemPath
		}

		return super.titleLabelString(for: item)
	}

	var share : OCShare? {
		didSet {
			if let share = share {
				if share.itemType == .collection {
					self.iconView.image = Theme.shared.image(for: "folder", size: iconSize)
				} else {
					self.iconView.image = Theme.shared.image(for: "file", size: iconSize)
				}

				self.itemResolutionPath = share.itemPath

				self.updateLabels(with: item)
			}
		}
	}
}
