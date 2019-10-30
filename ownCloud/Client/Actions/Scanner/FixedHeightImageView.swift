//
//  FixedHeightImageView.swift
//  ownCloud
//
//  Created by Felix Schwarz on 23.09.19.
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

class FixedHeightImageView : UIImageView {
	var aspectHeight : CGFloat? {
		didSet {
			self.invalidateIntrinsicContentSize()
		}
	}

	override var intrinsicContentSize: CGSize {
		if let aspectHeight = aspectHeight, let image = image {
			let imageSize = image.size
			var intrinsicSize : CGSize = CGSize(
				width: imageSize.width * aspectHeight / imageSize.height,
				height: aspectHeight
			)

			if intrinsicSize.width < 1 { intrinsicSize.width = 1 }
			if intrinsicSize.height < 1 { intrinsicSize.height = 1 }

			return intrinsicSize
		}

		return super.intrinsicContentSize
	}
}
