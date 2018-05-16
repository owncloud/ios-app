//
//  UploadsSettingsViewController.swift
//  ownCloud
//
//  Created by Pablo Carrascal on 30/04/2018.
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
import ownCloudSDK

// MARK: Photo uploads user defaults key.
public let UploadsPhotoUploadKey: String =  "uploads-settings-photos"
public let UploadsPhotoWifiOnlyKey: String = "uploads-settings-photos-wifi"
public let UploadsPhotoSelectedPathKey: String = "uploads-settings-photos-path"

// MARK: Video uploads user defaults key.
public let UploadsVideoUploadKey: String = "uploads-settings-videos"
public let UploadsVideoWifiOnlyKey: String = "uploads-settings-videos-wifi"
public let UploadsVideoSelectedPathKey: String = "uploads-settings-videos-path"

private let UploadsBackgroundUploadsKey: String = "uploads-settings-background"

private let uploadsSelectedPath: String = "/cameraUpload"

// MARK: - Section identifier
private let UploadsSectionIdentifier: String = "settings-uploads-section"

class UploadsSettingsSection: SettingsSection {

    // MARK: Upload settings properties.

    /// Instant Photo Uploads are anabled.
    private var isPhotoUploadEnabled: Bool {
        willSet {
            userDefaults.set(newValue, forKey: UploadsPhotoUploadKey)
            photosRow?.value = newValue
        }

        didSet {
            updateUI()
        }
    }
    /// Instant Photo Uploads only with WiFi connection.
    private var isPhotoWifiOnlyUploadsEnabled: Bool {
        willSet {
            userDefaults.set(newValue, forKey: UploadsPhotoWifiOnlyKey)
            photosWifiOnlyRow?.value = newValue
        }
    }
    /// Path in which the photos are going to be instant uploaded
    private var photoSelectedPath: String? {
        willSet {
            if newValue == nil {
                userDefaults.removeObject(forKey: UploadsPhotoSelectedPathKey)
            } else {
                userDefaults.set(newValue, forKey: UploadsPhotoSelectedPathKey)
                videosSelectedPathRow?.value = newValue
            }
        }
    }

    /// Instant Video Uploads are anabled.
    private var isVideoUploadEnabled: Bool {
        willSet {
            userDefaults.set(newValue, forKey: UploadsVideoUploadKey)
            videosRow?.value = newValue
        }

        didSet {
            updateUI()
        }
    }
    /// Instant Video Uploads only with WiFi connection.
    private var isVideoWifiOnlyUploadsEnabled: Bool {
        willSet {
            userDefaults.set(newValue, forKey: UploadsVideoWifiOnlyKey)
            videosWifiOnlyRow?.value = newValue
        }
    }
    /// Path in which the video are going to be instant uploaded
    private var videoSelectedPath: String? {
        willSet {
            if newValue == nil {
                 userDefaults.removeObject(forKey: UploadsVideoSelectedPathKey)
            } else {
                userDefaults.set(newValue, forKey: UploadsVideoSelectedPathKey)
                videosSelectedPathRow?.value = newValue
            }
        }
    }

    /// Instant Background Uploads are anabled.
    private var backgroundUploadsEnabled: Bool {
        willSet {
            userDefaults.set(newValue, forKey: UploadsBackgroundUploadsKey)
            backgroundUploadsRow?.value = newValue
        }
    }

    // MARK: - Upload Settings Cells

    private var photosRow: StaticTableViewRow?
    private var photosWifiOnlyRow: StaticTableViewRow?
    private var photosSelectedPathRow: StaticTableViewRow?

    private var videosRow: StaticTableViewRow?
    private var videosWifiOnlyRow: StaticTableViewRow?
    private var videosSelectedPathRow: StaticTableViewRow?

    private var backgroundUploadsRow: StaticTableViewRow?

    override init(userDefaults: UserDefaults) {

        self.isPhotoUploadEnabled = userDefaults.bool(forKey: UploadsPhotoUploadKey)
        self.isPhotoWifiOnlyUploadsEnabled = userDefaults.bool(forKey: UploadsPhotoWifiOnlyKey)
        self.photoSelectedPath = userDefaults.string(forKey: UploadsPhotoSelectedPathKey) ?? uploadsSelectedPath

        self.isVideoUploadEnabled = userDefaults.bool(forKey: UploadsVideoUploadKey)
        self.isVideoWifiOnlyUploadsEnabled = userDefaults.bool(forKey: UploadsVideoWifiOnlyKey)
        self.videoSelectedPath = userDefaults.string(forKey: UploadsVideoSelectedPathKey) ?? uploadsSelectedPath

        self.backgroundUploadsEnabled = userDefaults.bool(forKey: UploadsBackgroundUploadsKey)

        super.init(userDefaults: userDefaults)

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

        photosRow = StaticTableViewRow(switchWithAction: { (_, sender) in
            if let photosSwitch = sender as? UISwitch {
                self.isPhotoUploadEnabled = photosSwitch.isOn
            }
        }, title: "Photos".localized, value: isPhotoUploadEnabled)

        photosWifiOnlyRow = StaticTableViewRow(switchWithAction: { (_, sender) in
            if let photosWifiOnlySwitch = sender as? UISwitch {
                self.isPhotoWifiOnlyUploadsEnabled = photosWifiOnlySwitch.isOn
            }
        }, title: "Upload pictures via WiFi only".localized, value: isPhotoWifiOnlyUploadsEnabled)

        photosSelectedPathRow = StaticTableViewRow(subtitleRowWithAction: { (_, _) in
            // TODO: Use a more advanced version of ClientQueryViewController to select the path
        }, title: "Photo upload path".localized, subtitle: photoSelectedPath, accessoryType: .disclosureIndicator)
    }

    private func createVideoRows() {

        videosRow = StaticTableViewRow(switchWithAction: { (_, sender) in
            if let videosSwitch = sender as? UISwitch {
                self.isVideoUploadEnabled = videosSwitch.isOn
            }
        }, title: "Videos".localized, value: isVideoUploadEnabled)

        videosWifiOnlyRow = StaticTableViewRow(switchWithAction: { (_, sender) in
            if let videosWifiOnlySwitch = sender as? UISwitch {
                self.isVideoWifiOnlyUploadsEnabled = videosWifiOnlySwitch.isOn
            }
        }, title: "Upload videos via WiFi only".localized, value: isVideoWifiOnlyUploadsEnabled)

        videosSelectedPathRow = StaticTableViewRow(subtitleRowWithAction: { (_, _) in
            // TODO: Use a more advanced version of ClientQueryViewController to select the path
        }, title: "Video upload path".localized, subtitle: videoSelectedPath, accessoryType: .disclosureIndicator)
    }

    private func createCommonRows() {
        backgroundUploadsRow = StaticTableViewRow(switchWithAction: { (_, sender) in
            if let backgroundsSwitch = sender as? UISwitch {
                self.backgroundUploadsEnabled = backgroundsSwitch.isOn
            }
        }, title: "Background uploads".localized, value: backgroundUploadsEnabled)
    }

    /// Create and configure all the rows the Uploads Section has in the settings view.
    func updateUI() {

        if isPhotoUploadEnabled {

            let photoUploadIndex = rows.index(of: photosRow!)!

            if !rows.contains(photosWifiOnlyRow!) {
                insert(row: photosWifiOnlyRow!, at: photoUploadIndex + 1, animated: true)
                insert(row: photosSelectedPathRow!, at: photoUploadIndex + 2, animated: true)
            }

        } else {
            isPhotoWifiOnlyUploadsEnabled = false
            remove(rows: [photosWifiOnlyRow!, photosSelectedPathRow!], animated: true)
            videoSelectedPath = nil
        }

        if isVideoUploadEnabled {

            let videoUploadIndex = rows.index(of: videosRow!)!

            if !rows.contains(videosWifiOnlyRow!) {
                insert(row: videosWifiOnlyRow!, at: videoUploadIndex + 1, animated: true)
                insert(row: videosSelectedPathRow!, at: videoUploadIndex + 2, animated: true)
            }

        } else {
            isVideoWifiOnlyUploadsEnabled = false
            remove(rows: [videosWifiOnlyRow!, videosSelectedPathRow!], animated: true)
            videoSelectedPath = nil
        }

        // Background uploads flow
        if isPhotoUploadEnabled || isVideoUploadEnabled {

            if !rows.contains(backgroundUploadsRow!) {
                add(row: backgroundUploadsRow!, animated: true)
            }

        } else {
            backgroundUploadsEnabled = false
            remove(rows: [backgroundUploadsRow!], animated: true)
        }
    }

}
