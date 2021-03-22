//
//  ItemPolicyCell.swift
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

class ItemPolicyCell: ClientItemResolvingCell {
	var iconSize : CGSize = CGSize(width: 40, height: 40)

	override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	// MARK: - Item policy item
	override func titleLabelString(for item: OCItem?) -> String {
		if (itemResolutionPath as NSString?)?.isRootPath == true {
			return "Root folder".localized
		}

		if let item = item {
			return super.titleLabelString(for: item)
		} else {
			return "\((itemResolutionPath as NSString?)?.lastPathComponent ?? "") \("(no match)".localized)"
		}
	}

	override func detailLabelString(for item: OCItem?) -> String {
		if itemPolicy?.localID != nil, let itemPath = item?.path {
			return "\("at".localized) \(itemPath)"
		} else if let itemPolicyPath = itemPolicy?.path as NSString?, itemPolicyPath.length > 0 {
			return "\("at".localized) \(itemPolicyPath)"
		} else {
			return super.detailLabelString(for: item)
		}
	}

	var itemPolicy : OCItemPolicy? {
		didSet {
			if let itemPolicy = itemPolicy {
				if let itemPath = itemPolicy.path {
					if itemPath.hasSuffix("/") {
						self.iconView.image = Theme.shared.image(for: "folder", size: iconSize)

						self.itemResolutionPath = itemPath
					} else {
						self.iconView.image = Theme.shared.image(for: "file", size: iconSize)

						if let itemLocalID = itemPolicy.localID {
							self.itemResolutionLocalID = itemLocalID
						} else {
							self.itemResolutionPath = itemPath
						}
					}

					self.iconView.alpha = 0.5
					self.isUserInteractionEnabled = false
				}
			}

			self.updateLabels(with: self.item)
		}
	}

	override func updateWith(_ item: OCItem) {
		super.updateWith(item)

		self.iconView.alpha = 1.0
		self.isUserInteractionEnabled = true
	}
}
