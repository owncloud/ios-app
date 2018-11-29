//
//  RefreshControl.swift
//  ownCloud
//
//  Created by Pablo Carrascal on 28/11/2018.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

import UIKit

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
