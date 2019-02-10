//
//  OCMockingManagerSwiftExtension.swift
//  ownCloudTests
//
//  Created by Felix Schwarz on 20.09.18.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

// import Cocoa
import ownCloudMocking

extension OCMockManager {
	func addMocking(blocks: [ OCMockLocation : Any ]) {
		for (location, block) in blocks {
			self.setMockingBlock(block, forLocation: location)
		}
	}
}
