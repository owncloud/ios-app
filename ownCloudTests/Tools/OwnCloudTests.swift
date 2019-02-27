//
//  ownCloudTests.swift
//  ownCloudTests
//
//  Created by Pablo Carrascal on 07/03/2018.
//  Copyright © 2018 ownCloud. All rights reserved.
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

import XCTest
import EarlGrey

@testable import ownCloud

class OwnCloudTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    /*
     * Passed if: "Add account" button is enabled
     */
    func testAddServerButtonIsEnabled() {
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("addServer")).assert(with: grey_enabled())
    }

    func testClickOnTheButtonAndNothingHappens() {
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("addServer")).perform(grey_tap())
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("cancel")).perform(grey_tap())
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
}
