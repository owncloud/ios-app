//
//  XCTestsCase+Extension.swift
//  ownCloudTests
//
//  Created by Javier Gonzalez on 20/02/2019.
//  Copyright © 2019 ownCloud GmbH. All rights reserved.
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

import Foundation
import XCTest

extension XCTestCase {
	override open func setUp() {
		super.setUp()
		print("Starting \(self.name)")
	}
}
