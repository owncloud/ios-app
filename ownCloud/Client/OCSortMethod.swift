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

public enum SortMethod {

    case alphabeticallyAscendant
    case alphabeticallyDescendant
    case kindOfFiles
    case size

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

        case .kindOfFiles:
            comparator = {
                (left, right) in
                let leftItem = left as? OCItem
                let rightItem = right as? OCItem

                var leftMimeType = leftItem?.mimeType
                var rightMimeType = rightItem?.mimeType

                if leftItem?.mimeType == nil {
                    leftMimeType = "00folder"
                }

                if rightItem?.mimeType == nil {
                    rightMimeType = "00folder"
                }

                return leftMimeType!.compare(rightMimeType!)
            }

        default:
            comparator = nil
        }
        return comparator
    }
}
