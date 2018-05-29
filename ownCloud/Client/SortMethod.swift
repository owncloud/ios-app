//
//  OCSortMethod.swift
//  ownCloud
//
//  Created by Pablo Carrascal on 23/05/2018.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

import Foundation
import ownCloudSDK

typealias OCSort = Comparator

public enum SortMethod: Int {

    case alphabeticallyAscendant = 0
    case alphabeticallyDescendant = 1
    case type = 2
    case size = 3

    static var all: [SortMethod] = [alphabeticallyAscendant, alphabeticallyDescendant, type, size]

    func localizedName() -> String {
        var name = ""

        switch self {
        case .alphabeticallyAscendant:
            name = "A-Z".localized
        case .alphabeticallyDescendant:
            name = "Z-A".localized
        case .type:
            name = "Type".localized
        case .size:
            name = "Size".localized
        }

        return name
    }

    func comparator() -> OCSort? {
        var comparator: OCSort? = nil

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
                let leftItem = left as? OCItem
                let rightItem = right as? OCItem

                return (leftItem?.name.compare(rightItem!.name))!

            }

        case .alphabeticallyDescendant:
            comparator = {
                (left, right) in
                let leftItem = left as? OCItem
                let rightItem = right as? OCItem

                return (rightItem?.name.compare(leftItem!.name))!
            }

        case .type:
            comparator = {
                (left, right) in
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

                if leftItem?.mimeType == nil {
                    leftMimeType = "various"
                }

                if rightItem?.mimeType == nil {
                    rightMimeType = "various"
                }

                return leftMimeType!.compare(rightMimeType!)
            }
        }
        return comparator
    }
}
