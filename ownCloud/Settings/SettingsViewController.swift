//
//  SettingsViewController.swift
//  ownCloud
//
//  Created by Pablo Carrascal on 30/04/2018.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

import UIKit

class SettingsViewController: StaticTableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.title = "Settings".localized

        let standardUserDefaults = UserDefaults.standard
        let uploadSettings = UploadsSettings(userDefaults: standardUserDefaults)
        let securitySettings = SecuritySettings(userDefaults: standardUserDefaults)
        self.addSection(securitySettings)
        self.addSection(uploadSettings)
    }

}
