//
//  DriveGridCell.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 29.11.22.
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

class DriveGridCell: DriveHeaderCell {
	override var suggestedCellHeight: CGFloat? {
		return nil
	}

	override func configure() {
		super.configure()

		contentView.layer.cornerRadius = 8
		titleLabel.numberOfLines = 1
		titleLabel.lineBreakMode = .byTruncatingTail
		subtitleLabel.numberOfLines = 1
		subtitleLabel.lineBreakMode = .byTruncatingTail
	}

	override var subtitle: String? {
		didSet {
			subtitleLabel.text = subtitle ?? " " // Ensure the grid cells' titles align by always showing a subtitle - if necessary, an empty one
		}
	}
}
