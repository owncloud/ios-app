//
//  SortMethod.swift
//  ownCloud
//
//  Created by Pablo Carrascal on 23/05/2018.
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

import Foundation
import ownCloudSDK

typealias OCSort = Comparator

public enum SortDirection: Int {
	case ascendant = 0
	case descendant = 1
}

public enum SortMethod: Int {

	case alphabetically = 0
	case type = 1
	case size = 2
	case date = 3
	case shared = 4

	static var all: [SortMethod] = [alphabetically, type, size, date, shared]

	func localizedName() -> String {
		var name = ""

		switch self {
		case .alphabetically:
			name = "name".localized
		case .type:
			name = "type".localized
		case .size:
			name = "size".localized
		case .date:
			name = "date".localized
		case .shared:
			name = "shared".localized
		}

		return name
	}

	func comparator(direction: SortDirection) -> OCSort {
		var comparator: OCSort

		switch self {
		case .size:
			comparator = { (left, right) in
				let leftItem = left as? OCItem
				let rightItem = right as? OCItem

				let leftSize = leftItem!.size as NSNumber
				let rightSize = rightItem!.size as NSNumber
				if direction == .descendant {
					return (leftSize.compare(rightSize))
				}

				return (rightSize.compare(leftSize))
			}
		case .alphabetically:
			comparator = { (left, right) in
				guard let leftName  = (left as? OCItem)?.name, let rightName = (right as? OCItem)?.name else {
					return .orderedSame
				}
				if direction == .descendant {
					return (rightName.caseInsensitiveCompare(leftName))
				}

				return (leftName.caseInsensitiveCompare(rightName))
			}
		case .type:
			comparator = { (left, right) in
				let leftItem = left as? OCItem
				let rightItem = right as? OCItem

				var leftMimeType = leftItem?.mimeType
				var rightMimeType = rightItem?.mimeType

				if leftItem?.type == OCItemType.collection {
					leftMimeType = "folder"
				}

				if rightItem?.type == OCItemType.collection {
					rightMimeType = "folder"
				}

				if leftMimeType == nil {
					leftMimeType = "various"
				}

				if rightMimeType == nil {
					rightMimeType = "various"
				}
				if direction == .descendant {
					return rightMimeType!.compare(leftMimeType!)
				}

				return leftMimeType!.compare(rightMimeType!)
			}
		case .shared:
			comparator = { (left, right) in
				guard let leftItem = left as? OCItem else { return .orderedSame }
				guard let rightItem = right as? OCItem else { return .orderedSame }

				let leftShared = leftItem.isSharedWithUser || leftItem.isShared
				let rightShared = rightItem.isSharedWithUser || rightItem.isShared

				if leftShared == rightShared {
					return .orderedSame
				}

				if direction == .descendant {
					 if rightShared {
						return .orderedAscending
					}

					return .orderedDescending
				} else {
					if leftShared {
						return .orderedAscending
					}

					return .orderedDescending
				}
			}
		case .date:
			comparator = { (left, right) in

				guard let leftLastModified  = (left as? OCItem)?.lastModified, let rightLastModified = (right as? OCItem)?.lastModified else {
					return .orderedSame
				}
				if direction == .descendant {
					return (leftLastModified.compare(rightLastModified))
				}

				return (rightLastModified.compare(leftLastModified))
			}
		}
		return comparator
	}
}
