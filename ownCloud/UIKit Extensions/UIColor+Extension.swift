//
//  UIColor+Extension.swift
//  ownCloud
//
//  Created by Pablo Carrascal on 15/03/2018.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

import UIKit

extension UIColor {

    convenience init(red: Int, green: Int, blue: Int, alpha: Float = 1.0) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")

        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: CGFloat(alpha))
    }

    convenience init(hex rgbHex: Int, alpha: Float = 1.0) {
        self.init(red: (rgbHex >> 16) & 0xFF, green: (rgbHex >> 8) & 0xFF, blue: (rgbHex & 0xFF), alpha: alpha)
    }
}
