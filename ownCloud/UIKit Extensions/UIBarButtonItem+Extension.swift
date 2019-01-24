//
//  UIBarButtonItem+Extension.swift
//  ownCloud
//
//  Created by Michael Neuwert on 24.01.2019.
//  Copyright © 2019 ownCloud GmbH. All rights reserved.
//

import Foundation
import UIKit
import ownCloudSDK

public extension UIBarButtonItem {


    private struct AssociatedKeys {
        static var actionKey = "actionKey"
    }

    public var actionIdentifier: OCExtensionIdentifier? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.actionKey) as? OCExtensionIdentifier
        }

        set {
            if newValue != nil {
                objc_setAssociatedObject(self, &AssociatedKeys.actionKey, newValue!, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
            }
        }
    }
}
