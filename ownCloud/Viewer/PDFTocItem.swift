//
//  PDFTocItem.swift
//  ownCloud
//
//  Created by Michael Neuwert on 05.10.2018.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

import Foundation
import PDFKit

class PDFTocItem : Equatable {
    var label: String?
    var level: Int
    var page: PDFPage?

    init(level:Int, outline:PDFOutline) {
        self.level = level
        self.label = outline.label
        self.page = outline.destination?.page
    }

    // MARK: - Equatable
    static func == (lhs: PDFTocItem, rhs: PDFTocItem) -> Bool {
        if lhs.label == rhs.label && lhs.page == rhs.page {
            return true
        } else {
            return false
        }
    }
}
