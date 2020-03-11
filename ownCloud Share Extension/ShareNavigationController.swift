//
//  ShareNavigationController.swift
//  ownCloud Share Extension
//
//  Created by Matthias Hühne on 10.03.20.
//  Copyright © 2020 ownCloud GmbH. All rights reserved.
//

import UIKit

@objc(ShareNavigationController)
class ShareNavigationController: UINavigationController {

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)

        self.setViewControllers([ShareViewController()], animated: false)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
