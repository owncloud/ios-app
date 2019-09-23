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

	private var state: State = .launched {
		willSet {
			if state != newValue {
				scheduleTasks()
			}
		}
	}
	private static let lowBatteryThreshold : Float = 0.2

	private var lowBatteryDetected = false {
		willSet {
			if self.lowBatteryDetected != newValue {
				scheduleTasks()
			}
		}
	}

	private var externalPowerConnected = false {
		willSet {
			if self.externalPowerConnected != newValue {
				scheduleTasks()
			}
		}
	}

	private var wifiDetected = false {
		willSet {
			if self.wifiDetected != newValue {
				scheduleTasks()
			}
		}
	}

	private var photoLibraryChangeDetected = false {
		willSet {
			if self.photoLibraryChangeDetected != newValue && newValue == true {
				scheduleTasks()
			}
		}
	}

	private var wifiMonitorQueue: DispatchQueue?
	private var wifiMonitor : Any?
	private var monitoringPhotoLibrary = false

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
				self?.wifiDetected = (path.status == .satisfied && !path.isExpensive)
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
			// TODO: Find a better way how to prevent multiple invocation of instant upload tasks
			photoLibraryChangeDetected = false
		default:
			break
		}
	}

	@objc private func batteryLevelDidChange(notification:Notification) {
		checkPowerState()
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

	private func scheduleTasks(fetchCompletion:((UIBackgroundFetchResult) -> Void)? = nil, completion:((_ scheduledTaskCount:Int) -> Void)? = nil) {
		OnMainThread {

			let state = self.state
			let context = self.getCurrentContext()

			// Find a task to run
			if let matches = try? OCExtensionManager.shared.provideExtensions(for: context) {
				var bgFetchedNewDataTasks = 0
				var bgFailedTasks = 0
				let bgFetchGroup = DispatchGroup()
				let queue = DispatchQueue.global(qos: .background)

				for match in matches {
					if let task = match.extension.provideObject(for: context) as? ScheduledTaskAction {
						// Set completion handler for the task performing background fetch
						if state == .backgroundFetch {
							task.backgroundFetchCompletion = { result in
								switch result {
								case .newData :
									bgFetchedNewDataTasks += 1
								case .failed:
									bgFailedTasks += 1
								default:
									break
								}
								bgFetchGroup.leave()
							}
						}

						let backgroundExecution = state == .background
						if backgroundExecution {
							task.runUntil = Date().addingTimeInterval(UIApplication.shared.backgroundTimeRemaining)
						}
						if state == .backgroundFetch {
							bgFetchGroup.enter()
						}
						queue.async {
							task.run(background: backgroundExecution)
						}
					}
				}

				// Report background fetch result back to the OS
				if state == .backgroundFetch {
					bgFetchGroup.notify(queue: queue, execute: {
						if bgFetchedNewDataTasks > 0 {
							fetchCompletion?(.newData)
						} else if bgFailedTasks > 0 {
							fetchCompletion?(.failed)
						} else {
							fetchCompletion?(.noData)
						}
					})
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
		photoLibraryChangeDetected = true
	}

	// MARK: - Helper methods

	private func shallMonitorPhotoLibraryChanges() -> Bool {
		guard PHPhotoLibrary.authorizationStatus() == .authorized else { return false }

		guard let settings = OCAppIdentity.shared.userDefaults else { return false }

		guard settings.instantUploadVideosAfter != nil || settings.instantUploadPhotosAfter != nil else { return false }

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
