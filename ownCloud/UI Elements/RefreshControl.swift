//
//  RefreshControl.swift
//  ownCloud
//
//  Created by Pablo Carrascal on 28/11/2018.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

/*
* Copyright (C) 2018, ownCloud GmbH.
*
* This code is covered by the GNU Public License Version 3.
*
* For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
* You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
*
*/

import UIKit


/// This class is base on the solution proposed here https://stackoverflow.com/a/50670500
// It's the only way I found that fixed the white line problem.
class RefreshControl: UIRefreshControl {

	override var isHidden: Bool {
		get {
			return super.isHidden
		}
		set(hiding) {
			if hiding {
				guard frame.origin.y >= 0 else { return }
				super.isHidden = hiding
			} else {
				guard frame.origin.y < 0 else { return }
				super.isHidden = hiding
			}
		}
	}

	override var frame: CGRect {
		didSet {
			if frame.origin.y < 0 {
				isHidden = false
			} else {
				isHidden = true
			}
		}
	}

	override func layoutSubviews() {
		super.layoutSubviews()
		let originalFrame = frame
		frame = originalFrame
	}
}
