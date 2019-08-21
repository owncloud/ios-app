//
//  ScheduledTaskManager.swift
//  ownCloud
//
//  Created by Michael Neuwert on 28.05.2019.
//  Copyright © 2019 ownCloud GmbH. All rights reserved.
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

import Foundation
import UIKit
import Network
import Photos
import ownCloudSDK

class ScheduledTaskManager : NSObject {
	enum State {
		case launched, foreground, background, backgroundFetch

		func locationIdentifier() -> OCExtensionLocationIdentifier {
			switch self {
			case .launched:
				return .appLaunch
			case .foreground:
				return .appDidComeToForeground
			case .background:
				return .appDidBecomeBackgrounded
			case .backgroundFetch:
				return .appBackgroundFetch
			}
		}
	}

	static let shared = ScheduledTaskManager()

	private var state: State = .launched
	private static let lowBatteryThreshold : Float = 0.2
	private var lowBatteryDetected = false
	private var externalPowerConnected = false
	private var wifiDetected = false
	private var wifiMonitorQueue: DispatchQueue?
	private var wifiMonitor : Any?
	private var monitoringPhotoLibrary = false
	private var photoLibraryChangeDetected = false

	var considerLowBattery : Bool {
		get {
			return UIDevice.current.isBatteryMonitoringEnabled
		}

		set {
			UIDevice.current.isBatteryMonitoringEnabled = newValue
			if newValue == true {
				NotificationCenter.default.addObserver(self, selector: #selector(batteryLevelDidChange), name: UIDevice.batteryLevelDidChangeNotification, object: nil)
			} else {
				NotificationCenter.default.removeObserver(self, name: UIDevice.batteryLevelDidChangeNotification, object: nil)
				lowBatteryDetected = false
			}
		}
	}

	private override init() {
		super.init()
	}

	deinit {
		NotificationCenter.default.removeObserver(self)
		if #available(iOS 12, *) {
			(wifiMonitor as? NWPathMonitor)?.cancel()
		}
		stopMonitoringPhotoLibraryChanges()
	}

	func setup() {
		// Monitor app states
		NotificationCenter.default.addObserver(self, selector: #selector(applicationStateChange), name: UIApplication.didEnterBackgroundNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(applicationStateChange), name: UIApplication.didBecomeActiveNotification, object: nil)

		// Monitor media upload settings changes
		NotificationCenter.default.addObserver(self, selector: #selector(mediaUploadSettingsDidChange), name: UserDefaults.MediaUploadSettingsChangedNotification, object: nil)

		// In iOS12 or later, activate Wifi monitoring
		if #available(iOS 12, *) {
			wifiMonitorQueue = DispatchQueue(label: "com.owncloud.scheduled_task_mgr.wifi_monitor")
			wifiMonitor = NWPathMonitor(requiredInterfaceType: .wifi)
			(wifiMonitor as? NWPathMonitor)?.pathUpdateHandler = { [weak self] path in
				// Use "inexpensive" WiFi only (not behind a cellular hot-spot)
				let wifiAvailable =  (path.status == .satisfied && !path.isExpensive)
				self?.wifiDetected = wifiAvailable
				if wifiAvailable {
					self?.scheduleTasks()
				}
			}
			(wifiMonitor as? NWPathMonitor)?.start(queue: wifiMonitorQueue!)
		}

		checkPowerState()

		startMonitoringPhotoLibraryChangesIfNecessary()
	}

	// MARK: - Notifications handling

	@objc private func applicationStateChange(notificaton:Notification) {
		switch notificaton.name {
		case UIApplication.didBecomeActiveNotification:
			state = .foreground
		case UIApplication.didEnterBackgroundNotification:
			state = .background
		default:
			break
		}

		scheduleTasks()
	}

	@objc private func batteryLevelDidChange(notification:Notification) {
		checkPowerState()
		if lowBatteryDetected || externalPowerConnected {
			scheduleTasks()
		}
	}

	@objc private func mediaUploadSettingsDidChange(notification:Notification) {
		if shallMonitorPhotoLibraryChanges() {
			startMonitoringPhotoLibraryChangesIfNecessary()
		} else {
			stopMonitoringPhotoLibraryChanges()
		}
	}

	// MARK: - Background fetching

	func backgroundFetch(completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
		self.state = .backgroundFetch
		scheduleTasks(fetchCompletion: completionHandler)
	}

	// MARK: - Private methods

	private func getCurrentContext() -> OCExtensionContext {
		// Build a context
		let location = OCExtensionLocation(ofType: .scheduledTask, identifier: self.state.locationIdentifier())

		// Add requirements
		var requirements = [String : Bool]()
		if self.wifiDetected {
			requirements[ScheduledTaskAction.FeatureKeys.runOnWifi] = true
		}
		if self.lowBatteryDetected {
			requirements[ScheduledTaskAction.FeatureKeys.runOnLowBattery] = true
		}
		if self.externalPowerConnected {
			requirements[ScheduledTaskAction.FeatureKeys.runOnExternalPower] = true
		}
		if self.photoLibraryChangeDetected {
			requirements[ScheduledTaskAction.FeatureKeys.photoLibraryChanged] = true
		}

		return OCExtensionContext(location: location, requirements: requirements, preferences: nil)
	}

	private func scheduleTasks(fetchCompletion:((UIBackgroundFetchResult) -> Void)? = nil, completion:((_ scheduledTaskCount:Int)->Void)? = nil) {
		OnMainThread {

			let context = self.getCurrentContext()

			// Find a task to run
			if let matches = try? OCExtensionManager.shared.provideExtensions(for: context) {
				for match in matches {
					if let task = match.extension.provideObject(for: context) as? ScheduledTaskAction {
						if self.state == .backgroundFetch {
							task.backgroundFetchCompletion = fetchCompletion
						}
						let backgroundExecution = self.state == .background
						if backgroundExecution {
							task.runUntil = Date().addingTimeInterval(UIApplication.shared.backgroundTimeRemaining)
						}
						DispatchQueue.global(qos: .background).async {
							task.run(background: backgroundExecution)
						}
					}
				}

				completion?(matches.count)
			} else {
				completion?(0)
			}
		}
	}

	private func checkPowerState() {
		if UIDevice.current.batteryLevel >= 0 {
			lowBatteryDetected = (UIDevice.current.batteryLevel <= ScheduledTaskManager.lowBatteryThreshold)
		}
		if UIDevice.current.batteryState != .unknown {
			externalPowerConnected = (UIDevice.current.batteryState != .unplugged)
		}
	}
}

extension ScheduledTaskManager : PHPhotoLibraryChangeObserver {

	// MARK: - PHPhotoLibraryChangeObserver

	func photoLibraryDidChange(_ changeInstance: PHChange) {
		if !photoLibraryChangeDetected {
			photoLibraryChangeDetected = true
			scheduleTasks( completion:{ [weak self] (taskCount) in
				if taskCount > 0 {
					self?.photoLibraryChangeDetected = false
				}
			})
		}
	}

	// MARK: - Helper methods

	private func shallMonitorPhotoLibraryChanges() -> Bool {
		guard PHPhotoLibrary.authorizationStatus() == .authorized else { return false }

		guard let settings = OCAppIdentity.shared.userDefaults else { return false }

		guard settings.instantUploaVideosAfter != nil || settings.instantUploadPhotosAfter != nil else { return false }

		return true
	}

	private func startMonitoringPhotoLibraryChangesIfNecessary() {
		if !monitoringPhotoLibrary && shallMonitorPhotoLibraryChanges() {
			PHPhotoLibrary.shared().register(self)
			monitoringPhotoLibrary = true
		}
	}

	private func stopMonitoringPhotoLibraryChanges() {
		if monitoringPhotoLibrary {
			PHPhotoLibrary.shared().unregisterChangeObserver(self)
			monitoringPhotoLibrary = false
		}
	}
}
