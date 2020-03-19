//
//  AppLockWindow.swift
//  ownCloud
//
//  Created by Javier Gonzalez on 17/05/2018.
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

import UIKit

//Subclass that only allows the protrait mode
public class AppLockWindow: UIWindow {

    // MARK: - Show and hide animations
    public func showWindowAnimation(completion: (() -> Void)? = nil) {
        let height = self.bounds.height
        self.frame = CGRect(x: 0, y: height, width: self.frame.size.width, height: self.frame.size.height)

        UIView.transition(with: self, duration: 0.3, options: [], animations: {() -> Void in
            self.frame = CGRect(x: 0, y: 0, width: self.frame.size.width, height: self.frame.size.height)
        }, completion: {(_) in
            completion?()
        })
    }

    public func hideWindowAnimation(completion: (() -> Void)? = nil) {
        let height = self.bounds.height

        UIView.transition(with: self, duration: 0.3, options: [], animations: {() -> Void in
            self.frame = CGRect(x: 0, y: height, width: self.frame.size.width, height: self.frame.size.height)
        }, completion: {(_) in
            completion?()
        })
    }
}
