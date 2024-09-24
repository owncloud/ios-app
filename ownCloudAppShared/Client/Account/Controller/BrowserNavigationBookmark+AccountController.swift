//
//  BrowserNavigationBookmark+AccountController.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 09.02.23.
//  Copyright © 2023 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2023, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import UIKit
import ownCloudSDK

public extension BrowserNavigationBookmark {
	var representationSideBarItemRef: OCDataItemReference? {
		return representationSideBarItemRefs?.first
	}

	var representationSideBarItemRefs: [OCDataItemReference]? {
		// Returns the OCDataItemReference of the sidebar item that best represents the BrowserNavigationBookmark
		var itemRefs: [OCDataItemReference] = []

		func composedItemRef(for specialItem: AccountController.SpecialItem) -> OCDataItemReference {
			return ":B:\(bookmarkUUID?.uuidString ?? ""):I:\(specialItem.rawValue)" as NSString
		}

		switch type {
			case .dataItem:
				if let savedSearchUUID = savedSearch?.uuid {
					// OCSavedSearch.uuid
					itemRefs.append(savedSearchUUID as NSString)
				}

				if let sidebarItemUUID = sidebarItem?.uuid {
					// OCSidebarItem.uuid
					itemRefs.append(sidebarItemUUID as NSString)
				}

				if let driveID = location?.driveID as? NSString {
					// Respective driveID (OCDrive.dataItemReference)
					if let bookmarkUUID,
					   let spacesFolderID = BrowserNavigationBookmark(type: .specialItem, bookmarkUUID: bookmarkUUID, specialItem: .spacesFolder).representationSideBarItemRef {
					   	// Provide spaces folder as fallback 
						itemRefs.append(contentsOf: [driveID, spacesFolderID])
					} else {
						itemRefs.append(contentsOf: [driveID])
					}
				} else if let locationItemRef = location?.dataItemReference {
					// OCLocation.dataItemReference
					// Legacy account (for lack of drives)
					let rootLocation = OCLocation.legacyRoot
					rootLocation.bookmarkUUID = bookmarkUUID

					itemRefs.append(contentsOf: [locationItemRef, rootLocation.dataItemReference])
				}

			case .specialItem:
				if let specialItem {
					itemRefs.append(composedItemRef(for: specialItem))

					switch specialItem {
						case .sharedByMe, .sharedWithMe, .sharedByLink:
							itemRefs.append(composedItemRef(for: .sharingFolder))

						default: break
					}
				}

			default: break
		}

		return itemRefs.count > 0 ? itemRefs : nil
	}
}
