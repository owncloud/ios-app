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
import ownCloudApp

public typealias OCSort = Comparator

public enum SortDirection: Int {
	case ascending = 0
	case descending = 1
}

public enum SortMethod: Int {
	case alphabetically = 0
	case kind = 1
	case size = 2
	case date = 3
	case shared = 4
	case lastUsed = 5

	public static var all: [SortMethod] = [alphabetically, kind, size, date, lastUsed, shared]

	public var localizedName : String {
		var name = ""

		switch self {
			case .alphabetically:
				name = "name".localized
			case .kind:
				name = "kind".localized
			case .size:
				name = "size".localized
			case .date:
				name = "date".localized
			case .shared:
				name = "shared".localized
			case .lastUsed:
				name = "last used".localized
		}

		return name
	}

	public var sortPropertyName : OCItemPropertyName? {
		var propertyName : OCItemPropertyName?

		switch self {
			case .alphabetically:
				propertyName = .name
			case .kind:
				propertyName = .mimeType
			case .size:
				propertyName = .size
			case .date:
				propertyName = .lastModified
			case .shared: break
			case .lastUsed:
				propertyName = .lastUsed
		}

		return propertyName
	}

	public func comparator(direction: SortDirection) -> OCSort {
		var comparator: OCSort
		var combinedComparator: OCSort?
		let localizedSortComparator = OCSQLiteCollationLocalized.sortComparator!

		let alphabeticComparator : OCSort = { (left, right) in
			guard let leftName  = (left as? OCItem)?.name, let rightName = (right as? OCItem)?.name else {
				return .orderedSame
			}
			if direction == .descending {
				return localizedSortComparator(rightName, leftName)
			}

			return localizedSortComparator(leftName, rightName)
		}

		let itemTypeComparator : OCSort = { (left, right) in
			let leftItem = left as? OCItem
			let rightItem = right as? OCItem

			if let leftItemType = leftItem?.type, let rightItemType = rightItem?.type {
				if leftItemType != rightItemType {
					if leftItemType == .collection, rightItemType == .file {
						return .orderedAscending
					} else {
						return .orderedDescending
					}
				}
			}

			return .orderedSame
		}

		switch self {
			case .size:
				comparator = { (left, right) in
					let leftItem = left as? OCItem
					let rightItem = right as? OCItem

					let leftSize = leftItem!.size as NSNumber
					let rightSize = rightItem!.size as NSNumber
					if direction == .descending {
						return leftSize.compare(rightSize)
					}

					return rightSize.compare(leftSize)
				}

			case .alphabetically:
				comparator = alphabeticComparator

			case .kind:
				comparator = { (left, right) in
					let leftItem = left as? OCItem
					let rightItem = right as? OCItem

					let leftKind = leftItem?.fileExtension ?? leftItem?.mimeType ?? "_various"
					let rightKind = rightItem?.fileExtension ?? rightItem?.mimeType ?? "_various"

					var result : ComparisonResult = leftKind.compare(rightKind)

					let typeResult = itemTypeComparator(left, right)

					if typeResult != .orderedSame {
						result = typeResult
					}

					if direction == .descending {
						if result == .orderedDescending {
							result = .orderedAscending
						} else if result == .orderedAscending {
							result = .orderedDescending
						}
					}

					return result
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

					if direction == .descending {
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
					if direction == .descending {
						return leftLastModified.compare(rightLastModified)
					}

					return rightLastModified.compare(leftLastModified)
				}

			case .lastUsed:
				comparator = { (left, right) in

					guard let leftLastUsed  = (left as? OCItem)?.lastUsed ?? (left as? OCItem)?.lastModified, let rightLastUsed = (right as? OCItem)?.lastUsed ?? (right as? OCItem)?.lastModified else {
						return .orderedSame
					}
					if direction == .descending {
						return leftLastUsed.compare(rightLastUsed)
					}

					return rightLastUsed.compare(leftLastUsed)
				}
		}

		if combinedComparator == nil {
			combinedComparator = { (left, right) in
				var result : ComparisonResult = .orderedSame

				if DisplaySettings.shared.sortFoldersFirst {
					result = itemTypeComparator(left, right)
				}

				if result == .orderedSame {
					result = comparator(left, right)

					if result == .orderedSame, self != .alphabetically {
						result = alphabeticComparator(left, right)
					}
				}

				return result
			}
		}

		return combinedComparator ?? comparator
	}
}

public class SortDescriptor: NSObject {
	public var method: SortMethod
	public var direction: SortDirection

	public init(method inMethod: SortMethod, direction inDirection: SortDirection) {
		method = inMethod
		direction = inDirection

		super.init()
	}

	public var comparator: OCSort {
		return method.comparator(direction: direction)
	}

	public static var defaultSortDescriptor: SortDescriptor {
		get {
			let defaultSortMethod: SortMethod = SortMethod(rawValue: UserDefaults.standard.integer(forKey: "sort-method")) ?? .alphabetically
			let defaultSortDirection: SortDirection = SortDirection(rawValue: UserDefaults.standard.integer(forKey: "sort-direction")) ?? .ascending

			return SortDescriptor(method: defaultSortMethod, direction: defaultSortDirection)
		}

		set {
			UserDefaults.standard.setValue(newValue.method.rawValue, forKey: "sort-method")
			UserDefaults.standard.setValue(newValue.direction.rawValue, forKey: "sort-direction")
		}
	}
}
