//
//  UploadsSettingsViewController.swift
//  ownCloud
//
//  Created by Pablo Carrascal on 30/04/2018.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

import UIKit

// MARK: - Instant Uploads UserDefaults keys
private let UploadsPhotosUploadKey: String =  "uploads-settings-photos"
private let UploadsVideosUploadKey: String = "uploads-settings-videos"
private let UploadsBackgroundUploadsKey: String = "uploads-settings-background"
private let UploadsWifiOnlyKey: String = "uploads-settings-wifi"

// MARK: - Section key
private let UploadsSectionIdentifier: String = "settings-uploads-section"

// MARK: - Row keys
private let UploadsPhotosRowIdentifier: String = "uploads-photos-row"
private let UploadsVideosRowIdentifier: String = "uploads-videos-row"
private let UploadsBackgroundUploadsRowIdentifier: String = "uploads-background-row"
private let UploadsWifiOnlyRowIdentifier: String = "uploads-wifi-row"

class UploadsSettings: StaticTableViewSection {

    // MARK: Upload settings properties.

    /// Instant Photo Uploads are anabled.
    private var photoUploadEnabled: Bool {
        willSet {
            self.userDefaults.set(newValue, forKey: UploadsPhotosUploadKey)
        }
    }
    /// Instant Video Uploads are anabled.
    private var videoUploadEnabled: Bool {
        willSet {
            self.userDefaults.set(newValue, forKey: UploadsVideosUploadKey)
        }
    }
    /// Instant Background Uploads are anabled.
    private var backgroundUploadsEnabled: Bool {
        willSet {
            self.userDefaults.set(newValue, forKey: UploadsBackgroundUploadsKey)
        }
    }
    /// Instant uploads only trough wifi.
    private var wifiOnlyEnabled: Bool {
        willSet {
            self.userDefaults.set(newValue, forKey: UploadsWifiOnlyKey)
        }
    }
    /// User defaults to store the settings.
    private var userDefaults: UserDefaults

    init(userDefaults: UserDefaults) {

        self.userDefaults = userDefaults

        self.photoUploadEnabled = userDefaults.bool(forKey: UploadsPhotosUploadKey)
        self.videoUploadEnabled = userDefaults.bool(forKey: UploadsVideosUploadKey)
        self.backgroundUploadsEnabled = userDefaults.bool(forKey: UploadsBackgroundUploadsKey)
        self.wifiOnlyEnabled = userDefaults.bool(forKey: UploadsWifiOnlyKey)

        super.init()
        self.headerTitle = "Instant Uploads".localized
        self.identifier = UploadsSectionIdentifier

        updateUI()
    }

    // MARK: - Creation of the rows.
    @discardableResult
    private func photosRow() -> StaticTableViewRow {
        let photosRow = StaticTableViewRow(switchWithAction: { (row, _) in
            self.photoUploadEnabled = row.value as! Bool
            self.updateUI()
        }, title: "Photos".localized, value: photoUploadEnabled, identifier: UploadsPhotosRowIdentifier)

        return photosRow
    }

    @discardableResult
    private func videosRow() -> StaticTableViewRow {
        let videosRow = StaticTableViewRow(switchWithAction: { (row, _) in
            self.videoUploadEnabled = row.value as! Bool
            self.updateUI()
        }, title: "Videos".localized, value: videoUploadEnabled, identifier: UploadsVideosRowIdentifier)

        return videosRow
    }

    @discardableResult
    private func backgroundUploadsRow() -> StaticTableViewRow {
        let backgroundUploadsRow = StaticTableViewRow(switchWithAction: { (row, _) in
            self.backgroundUploadsEnabled = row.value as! Bool
        }, title: "Background uploads".localized, value: backgroundUploadsEnabled, identifier: UploadsBackgroundUploadsRowIdentifier)

        return backgroundUploadsRow
    }

    @discardableResult
    private func wifiOnlyRow() -> StaticTableViewRow {
        let wifiOnlyRow = StaticTableViewRow(switchWithAction: { (row, _) in
            self.wifiOnlyEnabled = row.value as! Bool
        }, title: "Wifi only".localized, value: wifiOnlyEnabled, identifier: UploadsWifiOnlyRowIdentifier)

        return wifiOnlyRow
    }

    /// Create and configure all the rows the Uploads Section has in the settings view.
    func updateUI() {

        if row(withIdentifier: UploadsPhotosRowIdentifier) == nil {
            add(rows: [photosRow()])
        }

        if row(withIdentifier: UploadsVideosRowIdentifier) == nil {
            add(rows: [videosRow()])
        }

        if photoUploadEnabled || videoUploadEnabled {
            if row(withIdentifier: UploadsBackgroundUploadsRowIdentifier) == nil {
                add(rows: [backgroundUploadsRow()])
            }

            if row(withIdentifier: UploadsWifiOnlyRowIdentifier) == nil {
                add(rows: [wifiOnlyRow()])
            }
        } else {
            if let row = row(withIdentifier: UploadsBackgroundUploadsRowIdentifier) {
                self.backgroundUploadsEnabled = false
                remove(rows: [row])
            }

            if let row = row(withIdentifier: UploadsWifiOnlyRowIdentifier) {
                self.wifiOnlyEnabled = false
                remove(rows: [row])
            }
        }

        reload()
    }

}
