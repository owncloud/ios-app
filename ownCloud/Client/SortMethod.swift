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

public enum SortMethod: Int {

	case alphabeticallyAscendant = 0
	case alphabeticallyDescendant = 1
	case type = 2
	case size = 3
	case date = 4
	case shared = 5

	static var all: [SortMethod] = [alphabeticallyAscendant, alphabeticallyDescendant, type, size, date, shared]

	func localizedName() -> String {
		var name = ""

		switch self {
		case .alphabeticallyAscendant:
			name = "name (A-Z)".localized
		case .alphabeticallyDescendant:
			name = "name (Z-A)".localized
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

	func comparator() -> OCSort {
		var comparator: OCSort

		switch self {
		case .size:
			comparator = { (left, right) in
				let leftItem = left as? OCItem
				let rightItem = right as? OCItem

				let leftSize = leftItem!.size as NSNumber
				let rightSize = rightItem!.size as NSNumber

				return (rightSize.compare(leftSize))
			}

		case .alphabeticallyAscendant:
			comparator = { (left, right) in
				guard let leftName  = (left as? OCItem)?.name, let rightName = (right as? OCItem)?.name else {
					return .orderedSame
				}

				return (leftName.caseInsensitiveCompare(rightName))
			}

		case .alphabeticallyDescendant:
			comparator = { (left, right) in
				guard let leftName  = (left as? OCItem)?.name, let rightName = (right as? OCItem)?.name else {
					return .orderedSame
				}

				return (rightName.caseInsensitiveCompare(leftName))
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

				return leftMimeType!.compare(rightMimeType!)
			}
		case .shared:
			comparator = { (left, right) in
				guard let leftItem = left as? OCItem else { return .orderedSame }
				guard let rightItem = right as? OCItem else { return .orderedSame }

				let leftShared = leftItem.isShared()
				let rightShared = rightItem.isShared()

				if leftShared == rightShared {
					return .orderedSame
				} else if leftShared {
					return .orderedAscending
				}
				return .orderedDescending
			}
		case .date:
			comparator = { (left, right) in

				guard let leftLastModified  = (left as? OCItem)?.lastModified, let rightLastModified = (right as? OCItem)?.lastModified else {
					return .orderedSame
				}

				return (rightLastModified.compare(leftLastModified))
			}
		}
		return comparator
	}
}
