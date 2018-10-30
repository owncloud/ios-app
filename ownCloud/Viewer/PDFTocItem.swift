//
//  PDFTocItem.swift
//  ownCloud
//
//  Created by Michael Neuwert on 05.10.2018.
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
