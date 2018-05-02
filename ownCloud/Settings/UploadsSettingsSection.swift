//
//  UploadsSettingsViewController.swift
//  ownCloud
//
//  Created by Pablo Carrascal on 30/04/2018.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

import UIKit

class UploadsSettings: StaticTableViewSection {

    // MARK: Upload settings properties

    /// Instant Photo Uploads are anabled
    private var photoUploadEnabled: Bool
    /// Instant Video Uploads are anabled
    private var videoUploadEnabled: Bool
    /// Instant Background Uploads are anabled
    private var backgroundUploadsEnabled: Bool
    /// Instant uploads only trough wifi
    private var wifiOnlyEnabled: Bool

    /// Section presenting those settings
    var section: StaticTableViewSection

    init(photoUploads: Bool, videoUploads: Bool, backgroundUploads: Bool, wifiOnly: Bool) {
        self.photoUploadEnabled = photoUploads
        self.videoUploadEnabled = videoUploads
        self.backgroundUploadsEnabled = backgroundUploads
        self.wifiOnlyEnabled = wifiOnly
        self.section = StaticTableViewSection(headerTitle: "Uploads".localized, footerTitle: nil)

        super.init()

        updateUI()
    }

    /// Create and configure all the rows the Uploads Section has in the settings view.
    func updateUI() {
        let photosRow = StaticTableViewRow(switchWithAction: { (row, sender) in
            // TODO: do something
        }, title: "Photos".localized, value: photoUploadEnabled, identifier: "uploads-photos-row")

        let videosRow = StaticTableViewRow(switchWithAction: { (row, sender) in
            // TODO: do something
        }, title: "Videos".localized, value: videoUploadEnabled, identifier: "uploads-videos-row")

        let backgroundUploadsRow = StaticTableViewRow(switchWithAction: { (row, sender) in
            // TODO: do something
        }, title: "Background uploads".localized, value: backgroundUploadsEnabled, identifier: "uploads-background-row")

        let wifiOnlyRow = StaticTableViewRow(switchWithAction: { (row, sender) in
            // TODO: do something
        }, title: "Wifi only".localized, value: wifiOnlyEnabled, identifier: "uploads-wifi-row")

        self.section.add(rows: [photosRow, videosRow, backgroundUploadsRow, wifiOnlyRow])
    }

}
