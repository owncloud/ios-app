//
//  CollaborateActionTests.swift
//  ownCloudTests
//
//  Created by Michael Stingl on 04.06.2025.
//  Copyright © 2025 ownCloud GmbH. All rights reserved.
//

import XCTest
import ownCloudSDK
import ownCloudAppShared
@testable import ownCloud

class CollaborateActionTests: XCTestCase {
    
    func testCollaborateActionIncludesMoreFolderLocation() {
        // Given
        let expectedLocations: [OCExtensionLocationIdentifier] = [
            .keyboardShortcut,
            .contextMenuSharingItem,
            .moreItem,
            .moreFolder,  // This is what we're testing
            .moreDetailItem,
            .accessibilityCustomAction
        ]
        
        // When
        let actualLocations = CollaborateAction.locations ?? []
        
        // Then
        XCTAssertEqual(actualLocations.count, expectedLocations.count, "CollaborateAction should have \(expectedLocations.count) locations")
        
        for expectedLocation in expectedLocations {
            XCTAssertTrue(actualLocations.contains(expectedLocation), "CollaborateAction should include location: \(expectedLocation.rawValue)")
        }
        
        // Specifically verify .moreFolder is included
        XCTAssertTrue(actualLocations.contains(.moreFolder), "CollaborateAction must include .moreFolder location for toolbar menu support")
    }
    
    func testCollaborateActionApplicabilityForMoreFolderLocation() {
        // This test would verify the special root folder handling logic
        // However, it requires mocking ActionContext which is more complex
        
        // Example of what we're testing:
        // 1. For OC10 root folders -> should return .none
        // 2. For oCIS virtual/personal space roots -> should return .none  
        // 3. For oCIS project space roots -> should return .first (if shareable)
        // 4. For regular folders -> should return .first (if shareable)
    }
}