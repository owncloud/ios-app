//
//  UIDevide+UIUserInterfaceIdiom.swift
//  ownCloud
//
//  Created by Pablo Carrascal on 05/06/2018.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

import UIKit

extension UIDevice {

	func isIpad() -> Bool {
		if self.userInterfaceIdiom == .pad {
			return true
		}

		return false
	}
}
