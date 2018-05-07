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

    // MARK: - Upload Settings Cells

    private var photosRow: StaticTableViewRow?
    private var photosWifiOnlyRow: StaticTableViewRow?
    private var photosSelectedPathRow: StaticTableViewRow?

    private var videosRow: StaticTableViewRow?
    private var videosWifiOnlyRow: StaticTableViewRow?
    private var videosSelectedPathRow: StaticTableViewRow?

    private var backgroundUploadsRow: StaticTableViewRow?

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

        createPhotoRows()
        createVideoRows()
        createCommonRows()

        self.headerTitle = "Instant Uploads".localized
        self.identifier = UploadsSectionIdentifier

        self.add(rows: [photosRow!, videosRow!])
        updateUI()
    }

    // MARK: - Creation of the rows.

    private func createPhotoRows() {

        photosRow = StaticTableViewRow(switchWithAction: { (row, _) in
            if let value = row.value as? Bool {
                self.photoUploadEnabled = value
                self.updateUI()
            }
        }, title: "Photos".localized, value: photoUploadEnabled)

        photosWifiOnlyRow = StaticTableViewRow(switchWithAction: { (row, _) in
            if let value = row.value as? Bool {
                self.photoWifiOnlyUploadsEnabled = value
            }
        }, title: "Upload pictures via WiFi only".localized, value: photoWifiOnlyUploadsEnabled)

        photosSelectedPathRow = StaticTableViewRow(subtitleRowWithAction: { (_, _) in
            // TODO: Use a more advanced version of ClientQueryViewController to select the path
        }, title: "Photo upload path".localized, subtitle: photoSelectedPath, accessoryType: .disclosureIndicator)
    }

    private func createVideoRows() {

        videosRow = StaticTableViewRow(switchWithAction: { (row, _) in
            if let value = row.value as? Bool {
                self.videoUploadEnabled = value
                self.updateUI()
            }
        }, title: "Videos".localized, value: videoUploadEnabled)

        videosWifiOnlyRow = StaticTableViewRow(switchWithAction: { (row, _) in
            if let value = row.value as? Bool {
                self.videoWifiOnlyUploadsEnabled = value
            }
        }, title: "Upload videos via WiFi only".localized, value: videoWifiOnlyUploadsEnabled)

        videosSelectedPathRow = StaticTableViewRow(subtitleRowWithAction: { (_, _) in
            // TODO: Use a more advanced version of ClientQueryViewController to select the path
        }, title: "Video upload path".localized, subtitle: videoSelectedPath, accessoryType: .disclosureIndicator)
    }

    private func createCommonRows() {
        backgroundUploadsRow = StaticTableViewRow(switchWithAction: { (row, _) in
            if let value = row.value as? Bool {
                self.backgroundUploadsEnabled = value
            }
        }, title: "Background uploads".localized, value: backgroundUploadsEnabled)
    }

    /// Create and configure all the rows the Uploads Section has in the settings view.
    func updateUI() {

        if photoUploadEnabled {

            let photoUploadIndex = rows.index(of: photosRow!)!

            if !rows.contains(photosWifiOnlyRow!) {
                insert(row: photosWifiOnlyRow!, at: photoUploadIndex + 1)
                insert(row: photosSelectedPathRow!, at: photoUploadIndex + 2)
            }

        } else {
            photoWifiOnlyUploadsEnabled = false
            photosWifiOnlyRow?.value = false
            remove(rows: [photosWifiOnlyRow!])

            photosSelectedPathRow?.cell?.detailTextLabel?.text = uploadsSelectedPath
            userDefaults.removeObject(forKey: UploadsPhotosSelectedPathKey)
            remove(rows: [photosSelectedPathRow!])
        }

        if videoUploadEnabled {

            let videoUploadIndex = rows.index(of: videosRow!)!

            if !rows.contains(videosWifiOnlyRow!) {
                insert(row: videosWifiOnlyRow!, at: videoUploadIndex + 1)
                insert(row: videosSelectedPathRow!, at: videoUploadIndex + 2)
            }

        } else {

            videoWifiOnlyUploadsEnabled = false
            videosWifiOnlyRow?.value = false
            remove(rows: [videosWifiOnlyRow!])

            videosSelectedPathRow?.cell?.detailTextLabel?.text = uploadsSelectedPath
            userDefaults.removeObject(forKey: UploadsVideosSelectedPathKey)
            remove(rows: [videosSelectedPathRow!])
        }

        // Background uploads flow
        if photoUploadEnabled || videoUploadEnabled {

            if !rows.contains(backgroundUploadsRow!) {
                add(rows: [backgroundUploadsRow!])
            }

        } else {
            backgroundUploadsRow?.value = false
            remove(rows: [backgroundUploadsRow!])
        }

        reload()
    }
}
