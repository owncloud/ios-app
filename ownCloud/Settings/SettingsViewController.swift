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

        let uploadSettings = UploadsSettings(photoUploads: true, videoUploads: false, backgroundUploads: true, wifiOnly: false)
        let securitySettings = SecuritySettings(userDefaults: UserDefaults.standard)
        self.addSection(securitySettings)
        self.addSection(uploadSettings.section)
    }

}
