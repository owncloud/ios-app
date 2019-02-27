//
//  OCMockingManagerSwiftExtension.swift
//  ownCloudTests
//
//  Created by Felix Schwarz on 20.09.18.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
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

// import Cocoa
import ownCloudMocking

extension OCMockManager {
	func addMocking(blocks: [ OCMockLocation : Any ]) {
		for (location, block) in blocks {
			self.setMockingBlock(block, forLocation: location)
		}
	}
}
