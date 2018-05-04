//
//  UploadsSettingsViewController.swift
//  ownCloud
//
//  Created by Pablo Carrascal on 30/04/2018.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

import UIKit
import ownCloudSDK

// MARK: - Instant Uploads UserDefaults keys
public let UploadsPhotosUploadKey: String =  "uploads-settings-photos"
public let UploadsPhotosWifiOnlyKey: String = "uploads-settings-photos-wifi"
public let UploadsPhotosSelectedPathKey: String = "uploads-settings-photos-path"

public let UploadsVideosUploadKey: String = "uploads-settings-videos"
public let UploadsVideosWifiOnlyKey: String = "uploads-settings-videos-wifi"
public let UploadsVideosSelectedPathKey: String = "uploads-settings-videos-path"

private let uploadsSelectedPath: String = "/cameraUpload"

private let UploadsBackgroundUploadsKey: String = "uploads-settings-background"

// MARK: - Section identifier
private let UploadsSectionIdentifier: String = "settings-uploads-section"

// MARK: - Row identifiers
private let UploadsPhotosRowIdentifier: String = "uploads-photos-row"
private let UploadsPhotosWifiOnlyRowIdentifier: String = "uploads-photos-wifi-row"
private let UploadsPhotosSelectedPathRowIdentifier: String = "uploads-photos-path-row"

private let UploadsVideosRowIdentifier: String = "uploads-videos-row"
private let UploadsVideosWifiOnlyRowIdentifier: String = "uploads-videos-wifi-row"
private let UploadsVideosSelectedPathRowIdentifier: String = "uploads-videos-path-row"

private let UploadsBackgroundUploadsRowIdentifier: String = "uploads-background-row"

class UploadsSettings: StaticTableViewSection {

    // MARK: Upload settings properties.

    /// Instant Photo Uploads are anabled.
    private var photoUploadEnabled: Bool {
        willSet {
            self.userDefaults.set(newValue, forKey: UploadsPhotosUploadKey)
        }
    }
    /// Instant Photo Uploads only with WiFi connection.
    private var photoWifiOnlyUploadsEnabled: Bool {
        willSet {
            self.userDefaults.set(newValue, forKey: UploadsPhotosWifiOnlyKey)
        }
    }
    /// Path in which the photos are going to be instant uploaded
    private var photoSelectedPath: String {
        willSet {
            self.userDefaults.set(newValue, forKey: UploadsPhotosSelectedPathKey)
        }
    }

    /// Instant Video Uploads are anabled.
    private var videoUploadEnabled: Bool {
        willSet {
            self.userDefaults.set(newValue, forKey: UploadsVideosUploadKey)
        }
    }
    /// Instant Video Uploads only with WiFi connection.
    private var videoWifiOnlyUploadsEnabled: Bool {
        willSet {
            self.userDefaults.set(newValue, forKey: UploadsVideosWifiOnlyKey)
        }
    }
    /// Path in which the video are going to be instant uploaded
    private var videoSelectedPath: String {
        willSet {
            self.userDefaults.set(newValue, forKey: UploadsVideosSelectedPathKey)
        }
    }

    /// Instant Background Uploads are anabled.
    private var backgroundUploadsEnabled: Bool {
        willSet {
            self.userDefaults.set(newValue, forKey: UploadsBackgroundUploadsKey)
        }
    }
    /// User defaults to store the settings.
    private var userDefaults: UserDefaults

    init(userDefaults: UserDefaults) {

        self.userDefaults = userDefaults

        self.photoUploadEnabled = userDefaults.bool(forKey: UploadsPhotosUploadKey)
        self.photoWifiOnlyUploadsEnabled = userDefaults.bool(forKey: UploadsPhotosWifiOnlyKey)
        self.photoSelectedPath = userDefaults.string(forKey: UploadsPhotosSelectedPathKey) ?? uploadsSelectedPath

        self.videoUploadEnabled = userDefaults.bool(forKey: UploadsVideosUploadKey)
        self.videoWifiOnlyUploadsEnabled = userDefaults.bool(forKey: UploadsVideosWifiOnlyKey)
        self.videoSelectedPath = userDefaults.string(forKey: UploadsVideosSelectedPathKey) ?? uploadsSelectedPath

        self.backgroundUploadsEnabled = userDefaults.bool(forKey: UploadsBackgroundUploadsKey)

        super.init()
        self.headerTitle = "Instant Uploads".localized
        self.identifier = UploadsSectionIdentifier

        updateUI()
    }

    // MARK: - Creation of the rows.
    private func photosRow() -> StaticTableViewRow {
        let photosRow = StaticTableViewRow(switchWithAction: { (row, _) in
            if let value = row.value as? Bool {
                self.photoUploadEnabled = value
                self.updateUI()
            }
        }, title: "Photos".localized, value: photoUploadEnabled, identifier: UploadsPhotosRowIdentifier)

        return photosRow
    }

    private func photosWifiOnlyRow() -> StaticTableViewRow {
        let photosWifiOnlyRow = StaticTableViewRow(switchWithAction: { (row, _) in
            if let value = row.value as? Bool {
                self.photoWifiOnlyUploadsEnabled = value
            }
        }, title: "Upload pictures via WiFi only".localized, value: photoWifiOnlyUploadsEnabled, identifier: UploadsPhotosWifiOnlyRowIdentifier)

        return photosWifiOnlyRow
    }

    private func photosSelectedPathRow() -> StaticTableViewRow {
        let photosSelectedPathRow = StaticTableViewRow(textFieldWithAction: { (row, _) in
            if let value = row.value as? String {
                self.photoSelectedPath = value
            }
        }, placeholder: uploadsSelectedPath,
           value: photoSelectedPath,
           secureTextEntry: false,
           keyboardType: .default,
           autocorrectionType: .no,
           autocapitalizationType: .none,
           enablesReturnKeyAutomatically: true,
           returnKeyType: .done,
           identifier: UploadsPhotosSelectedPathRowIdentifier)

        return photosSelectedPathRow
    }

    private func videosRow() -> StaticTableViewRow {
        let videosRow = StaticTableViewRow(switchWithAction: { (row, _) in
            if let value = row.value as? Bool {
                self.videoUploadEnabled = value
                self.updateUI()
            }
        }, title: "Videos".localized, value: videoUploadEnabled, identifier: UploadsVideosRowIdentifier)

        return videosRow
    }

    private func videosWifiOnlyRow() -> StaticTableViewRow {
        let videosWifiOnlyRow = StaticTableViewRow(switchWithAction: { (row, _) in
            if let value = row.value as? Bool {
                self.videoWifiOnlyUploadsEnabled = value
            }
        }, title: "Upload videos via WiFi only".localized, value: videoWifiOnlyUploadsEnabled, identifier: UploadsVideosWifiOnlyRowIdentifier)

        return videosWifiOnlyRow
    }

    private func videosSelectedPathRow() -> StaticTableViewRow {
        let videosSelectedPathRow = StaticTableViewRow(textFieldWithAction: { (row, _) in
            if let value = row.value as? String {
                self.videoSelectedPath = value
            }
        }, placeholder: uploadsSelectedPath,
           value: videoSelectedPath,
           secureTextEntry: false,
           keyboardType: .default,
           autocorrectionType: .no,
           autocapitalizationType: .none,
           enablesReturnKeyAutomatically: true,
           returnKeyType: .done,
           identifier: UploadsVideosSelectedPathRowIdentifier)

        return videosSelectedPathRow
    }

    private func backgroundUploadsRow() -> StaticTableViewRow {
        let backgroundUploadsRow = StaticTableViewRow(switchWithAction: { (row, _) in
            if let value = row.value as? Bool {
                self.backgroundUploadsEnabled = value
            }
        }, title: "Background uploads".localized, value: backgroundUploadsEnabled, identifier: UploadsBackgroundUploadsRowIdentifier)

        return backgroundUploadsRow
    }

    /// Create and configure all the rows the Uploads Section has in the settings view.
    func updateUI() {

        // Photo camera uploads flow
        if row(withIdentifier: UploadsPhotosRowIdentifier) == nil {
            add(rows: [photosRow()])
        }

        if photoUploadEnabled {

            let photoUploadIndex = rows.index(of: row(withIdentifier: UploadsPhotosRowIdentifier)!)!

            if row(withIdentifier: UploadsPhotosWifiOnlyRowIdentifier) == nil {
                insert(row: photosWifiOnlyRow(), at: photoUploadIndex + 1)
            }
            if row(withIdentifier: UploadsPhotosSelectedPathRowIdentifier) == nil {

                insert(row: photosSelectedPathRow(), at: photoUploadIndex + 2)
            }
        } else {
            if let row = row(withIdentifier: UploadsPhotosWifiOnlyRowIdentifier) {
                self.photoWifiOnlyUploadsEnabled = false
                remove(rows: [row])
            }

            if let row = row(withIdentifier: UploadsPhotosSelectedPathRowIdentifier) {
                self.userDefaults.removeObject(forKey: UploadsPhotosSelectedPathKey)
                remove(rows: [row])
            }
        }

        // Video camera uploads flow
        if row(withIdentifier: UploadsVideosRowIdentifier) == nil {
            add(rows: [videosRow()])
        }

        if videoUploadEnabled {
            let videoUploadIndex = rows.index(of: row(withIdentifier: UploadsVideosRowIdentifier)!)!

            if row(withIdentifier: UploadsVideosWifiOnlyRowIdentifier) == nil {
                insert(row: videosWifiOnlyRow(), at: videoUploadIndex + 1)
            }
            if row(withIdentifier: UploadsVideosSelectedPathRowIdentifier) == nil {
                insert(row: videosSelectedPathRow(), at: videoUploadIndex + 2)
            }
        } else {
            if let row = row(withIdentifier: UploadsVideosWifiOnlyRowIdentifier) {
                self.videoWifiOnlyUploadsEnabled = false
                remove(rows: [row])
            }

            if let row = row(withIdentifier: UploadsVideosSelectedPathRowIdentifier) {
                self.userDefaults.removeObject(forKey: UploadsVideosSelectedPathKey)
                remove(rows: [row])
            }
        }

        // Background uploads flow
        if photoUploadEnabled || videoUploadEnabled {
            if row(withIdentifier: UploadsBackgroundUploadsRowIdentifier) == nil {
                add(rows: [backgroundUploadsRow()])
            }

        } else {
            if let row = row(withIdentifier: UploadsBackgroundUploadsRowIdentifier) {
                self.backgroundUploadsEnabled = false
                remove(rows: [row])
            }
        }

        reload()
    }
}
