//
//  String+Extension.swift
//  ownCloud
//
//  Created by Pablo Carrascal on 05/04/2018.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

import Foundation

extension String {

    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
}
