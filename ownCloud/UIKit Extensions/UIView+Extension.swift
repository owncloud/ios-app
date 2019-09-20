//
//  UIButton+Extension.swift
//  ownCloud
//
//  Created by Matthias Hühne on 20.09.2019.
//  Copyright © 2019 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2019, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import UIKit

extension UIView {
    func getSubview<T>(type: T.Type) -> T? {
        let allSubviews = subviews.flatMap { $0.subviews }
        let element = (allSubviews.filter { $0 is T }).first

        return element as? T
    }
}
