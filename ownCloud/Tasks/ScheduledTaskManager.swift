//
//  ScheduledTaskManager.swift
//  ownCloud
//
//  Created by Michael Neuwert on 28.05.2019.
//  Copyright © 2019 ownCloud GmbH. All rights reserved.
//

/*
* Copyright (C) 2020, ownCloud GmbH.
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
import ownCloudAppShared
import BackgroundTasks
import CoreLocation

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

		didSet {
			if state != oldValue && state != .backgroundFetch {
				scheduleTasks()
			}
		}
	}

	private static let lowBatteryThreshold : Float = 0.2

	private var lowBatteryDetected = false {

		didSet {
			if self.lowBatteryDetected != oldValue {
				scheduleTasks()
			}
		}
	}

	private var externalPowerConnected = false {
		didSet {
			if self.externalPowerConnected != oldValue {
				scheduleTasks()
			}
		}
	}

	private var wifiDetected = false {
		didSet {
			if self.wifiDetected != oldValue {
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

	let locationManager = CLLocationManager()

	private let taskQueue = DispatchQueue(label: "com.owncloud.task-scheduler.queue", qos: .background, attributes: .concurrent)

	private var activeRefreshTask: Any?

	private override init() {
		super.init()
	}

	deinit {
		NotificationCenter.default.removeObserver(self)
		(wifiMonitor as? NWPathMonitor)?.cancel()
		stopMonitoringPhotoLibraryChanges()
	}

	func setup() {

		// Monitor app states
		NotificationCenter.default.addObserver(self, selector: #selector(applicationStateChange), name: UIApplication.didEnterBackgroundNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(applicationStateChange), name: UIApplication.didBecomeActiveNotification, object: nil)

		// Monitor media upload settings changes
		NotificationCenter.default.addObserver(self, selector: #selector(mediaUploadSettingsDidChange), name: UserDefaults.MediaUploadSettingsChangedNotification, object: nil)

		// Activate Wifi monitoring
		wifiMonitorQueue = DispatchQueue(label: "com.owncloud.scheduled_task_mgr.wifi_monitor")
		wifiMonitor = NWPathMonitor(requiredInterfaceType: .wifi)
		(wifiMonitor as? NWPathMonitor)?.pathUpdateHandler = { [weak self] path in
			// Use "inexpensive" WiFi only (not behind a cellular hot-spot)
			self?.wifiDetected = (path.status == .satisfied && !path.isExpensive)
		}
		(wifiMonitor as? NWPathMonitor)?.start(queue: wifiMonitorQueue!)

		checkPowerState()

		startMonitoringPhotoLibraryChangesIfNecessary()

		locationManager.delegate = self

		if #available(iOS 13, *) {
			BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.owncloud.background-refresh-task", using: nil) { (task) in
				if let refreshTask = task as? BGAppRefreshTask {
					self.handleBackgroundRefresh(task: refreshTask)
				}
			}
		}
	}

	// MARK: - Notifications handling

	@objc private func applicationStateChange(notificaton:Notification) {
		switch notificaton.name {
		case UIApplication.didBecomeActiveNotification:
			state = .foreground
            stopLocationMonitoring()
		case UIApplication.didEnterBackgroundNotification:
			state = .background
            startLocationMonitoringIfAuthorized()
			if #available(iOS 13, *) {
				scheduleBackgroundRefreshTask()
			}
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
			stopLocationMonitoring()
		}
	}

	// MARK: - Background fetching

	func backgroundFetch(completionHandler: ((UIBackgroundFetchResult) -> Void)? = nil) {
		self.state = .backgroundFetch
		scheduleTasks(fetchCompletion: completionHandler)
	}

	// MARK: - Private methods

	private func getCurrentContext() -> OCExtensionContext {
		// Build a context
		let location = OCExtensionLocation(ofType: .scheduledTask, identifier: self.state.locationIdentifier())

		// Add requirements
		var requirements = [String : Bool]()
		var preferences = [String : Bool]()

		if self.wifiDetected {
			preferences[ScheduledTaskAction.FeatureKeys.runOnWifi] = true
		}
		if self.lowBatteryDetected {
			requirements[ScheduledTaskAction.FeatureKeys.runOnLowBattery] = true
		}
		if self.externalPowerConnected {
			requirements[ScheduledTaskAction.FeatureKeys.runOnExternalPower] = true
		}
		if shallMonitorPhotoLibraryChanges() && checkForNewAssets() {
			if self.state == .backgroundFetch, let userDefaults = OCAppIdentity.shared.userDefaults {
				requirements[ScheduledTaskAction.FeatureKeys.photoLibraryChanged] = userDefaults.backgroundMediaUploadsEnabled
			} else {
				requirements[ScheduledTaskAction.FeatureKeys.photoLibraryChanged] = true
			}
		}

		return OCExtensionContext(location: location, requirements: requirements, preferences: preferences)
	}

	private func scheduleTasks(fetchCompletion:((UIBackgroundFetchResult) -> Void)? = nil, completion:((_ scheduledTaskCount:Int) -> Void)? = nil) {

		let state = self.state
		let context = self.getCurrentContext()

		Log.debug(tagged: ["TASK_MANAGER"], "Scheduling tasks in state \(state), location id: \(state.locationIdentifier())")

		// Find a task to run
		if let matches = try? OCExtensionManager.shared.provideExtensions(for: context) {
			var bgFetchedNewDataTasks = 0
			var bgFailedTasks = 0

			for match in matches {
				Log.debug(tagged: ["TASK_MANAGER"], "Task extension match: \(match.extension.identifier)")

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
						}
					}

					let backgroundExecution = state == .background

					taskQueue.async {
						task.run(background: backgroundExecution)
					}
				}
			}

			Log.debug(tagged: ["TASK_MANAGER"], "Scheduled \(matches.count) tasks")

			taskQueue.async(flags: .barrier) {
				// Report background fetch result back to the OS
				if state == .backgroundFetch {
					if bgFetchedNewDataTasks > 0 {
						fetchCompletion?(.newData)
					} else if bgFailedTasks > 0 {
						fetchCompletion?(.failed)
					} else {
						fetchCompletion?(.noData)
					}

					if #available(iOS 13, *) {
						if let activeTask = self.activeRefreshTask as? BGAppRefreshTask {
							// Schedule the next refresh
							self.scheduleBackgroundRefreshTask()

							activeTask.setTaskCompleted(success: true)

							self.activeRefreshTask = nil
						}
					}
				}
				Log.debug(tagged: ["TASK_MANAGER"], "All tasks executed")
			}

			completion?(matches.count)
		} else {
			completion?(0)
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

// MARK: - Background tasks handling for iOS >= 13

@available(iOS 13, *)
extension ScheduledTaskManager {

	static let backgroundRefreshInterval = TimeInterval(15 * 60)

	func scheduleBackgroundRefreshTask() {

        let request = BGAppRefreshTaskRequest(identifier: "com.owncloud.background-refresh-task")
		request.earliestBeginDate = Date(timeIntervalSinceNow: ScheduledTaskManager.backgroundRefreshInterval)
		do {
			try BGTaskScheduler.shared.submit(request)
		} catch {
			// Submitting new task if there is already one in the queue will fail.
			// iOS permitts 1 pending refresh task at a time and up to 10 processing tasks
			Log.error(tagged: ["TASK_MANAGER"], "Failed to submit BGAppRefreshTask request")
		}
	}

	func handleBackgroundRefresh(task: BGAppRefreshTask) {

		Log.log(tagged: ["TASK_MANAGER"], "BGAppRefreshTask launched")

		self.activeRefreshTask = task
		self.backgroundFetch()
	}
}

// MARK: - PHPhotoLibraryChangeObserver implementation

extension ScheduledTaskManager : PHPhotoLibraryChangeObserver {

	// MARK: - PHPhotoLibraryChangeObserver

	func photoLibraryDidChange(_ changeInstance: PHChange) {
		scheduleTasks()
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
		}
	}

	private func checkForNewAssets() -> Bool {
		guard let userDefaults = OCAppIdentity.shared.userDefaults else { return false }

		// Get timestamps for last successfully uploaded media assets
		var lastUploadedMediaTimestamps = [Date]()
		if let timestamp = userDefaults.instantUploadPhotosAfter {
			lastUploadedMediaTimestamps.append(timestamp)
		}
		if let timestamp = userDefaults.instantUploadVideosAfter {
			lastUploadedMediaTimestamps.append(timestamp)
		}

		// We need at least one earlier timestamp, to check if there are new media assets available
		guard lastUploadedMediaTimestamps.count > 0 else { return false }
		lastUploadedMediaTimestamps.sort(by: >)
		let earliestTimestamp = lastUploadedMediaTimestamps.first!

		// At least one not yet uploaded media asset found?
		var assetCount = 0
		if let result = PHAsset.fetchAssetsFromCameraRoll(with: [.image, .video], createdAfter: earliestTimestamp, fetchLimit: 1) {
			assetCount = result.count
		}

		Log.debug(tagged: ["TASK_MANAGER", "MEDIA_UPLOAD"], "\(assetCount) new assets found ")

		return assetCount > 0 ? true : false
	}
}

extension ScheduledTaskManager : CLLocationManagerDelegate {

    private func startLocationTracking() {
        //locationManager.startMonitoringSignificantLocationChanges()
        locationManager.startMonitoringVisits()

    }

    private func stopLocationTracking() {
        //locationManager.stopMonitoringSignificantLocationChanges()
        locationManager.stopMonitoringVisits()
    }

	@discardableResult func startLocationMonitoringIfAuthorized() -> Bool {
		guard let userDefaults = OCAppIdentity.shared.userDefaults else { return false }

		if CLLocationManager.authorizationStatus() == .authorizedAlways && userDefaults.backgroundMediaUploadsLocationUpdatesEnabled {
			Log.debug(tagged: ["TASK_MANAGER", "MEDIA_UPLOAD"], "Significant location monitoring has started")
			startLocationTracking()
			return true
		} else {
			return false
		}
	}

	func stopLocationMonitoring() {
		if CLLocationManager.authorizationStatus() == .authorizedAlways || CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
			stopLocationTracking()
		}
	}

	func requestLocationAuthorization() -> Bool {
		let currentStatus = CLLocationManager.authorizationStatus()
		switch currentStatus {
		case .notDetermined, .authorizedWhenInUse:
			self.locationManager.requestAlwaysAuthorization()
			return true
		case .authorizedAlways:
			return true
		default:
			return false
		}
	}

	func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		Log.debug(tagged: ["TASK_MANAGER", "MEDIA_UPLOAD"], "Significant location change event")

		if shallMonitorPhotoLibraryChanges() {
			scheduleTasks()
		} else {
			Log.warning(tagged: ["TASK_MANAGER"], "Significant location change event without access to photo library")
		}
	}

    func locationManager(_ manager: CLLocationManager, didVisit visit: CLVisit) {
        Log.debug(tagged: ["TASK_MANAGER", "MEDIA_UPLOAD"], "Location visit event")

        if shallMonitorPhotoLibraryChanges() {
            scheduleTasks()
		} else {
			Log.warning(tagged: ["TASK_MANAGER"], "Location visit event without access to photo library")
		}
    }

	func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
		guard let userDefaults = OCAppIdentity.shared.userDefaults else { return }

		guard status == .authorizedAlways else {
			userDefaults.backgroundMediaUploadsLocationUpdatesEnabled = false
			return
		}

		userDefaults.backgroundMediaUploadsLocationUpdatesEnabled = true

		guard shallMonitorPhotoLibraryChanges() == true else { return }

		startLocationTracking()
	}

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let error = error as? CLError, error.code == .denied {
            stopLocationTracking()
			if let userDefaults = OCAppIdentity.shared.userDefaults {
				userDefaults.backgroundMediaUploadsLocationUpdatesEnabled = false
			}
        }
    }
}
