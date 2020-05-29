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

	private var photoLibraryChangeDetected = false {
		didSet {
			if self.photoLibraryChangeDetected != oldValue && self.photoLibraryChangeDetected == true {
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

	var activeProcessingTask: Any?

	let locationManager = CLLocationManager()

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

		locationManager.delegate = self

		startLocationMonitoringIfAuthorized()

		if #available(iOS 13, *) {
			BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.owncloud.background-task.instant-media-refresh", using: nil) { (task) in
				if let refreshTask = task as? BGAppRefreshTask {
					self.handleMediaRefresh(task: refreshTask)
				}
			}

			BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.owncloud.background-task.instant-media-upload", using: nil) { (task) in
				if let processingTask = task as? BGProcessingTask {
					self.handleMediaUpload(task: processingTask)
				}
			}
		}
	}

	// MARK: - Notifications handling

	@objc private func applicationStateChange(notificaton:Notification) {
		switch notificaton.name {
		case UIApplication.didBecomeActiveNotification:
			state = .foreground
		case UIApplication.didEnterBackgroundNotification:
			state = .background
			if #available(iOS 13, *) {
				scheduleMediaRefreshTask()
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
		if self.photoLibraryChangeDetected {
			requirements[ScheduledTaskAction.FeatureKeys.photoLibraryChanged] = true
		}

		return OCExtensionContext(location: location, requirements: requirements, preferences: preferences)
	}

	private func scheduleTasks(fetchCompletion:((UIBackgroundFetchResult) -> Void)? = nil, completion:((_ scheduledTaskCount:Int) -> Void)? = nil) {

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

					if state == .backgroundFetch {
						bgFetchGroup.enter()
					}

					if #available(iOS 13, *) {
						if let processingTask = activeProcessingTask as? BGProcessingTask, let instantUploadTask = task as? InstantMediaUploadTaskExtension {
							instantUploadTask.completion = { _ in
								Log.log(tagged: ["TASK_MANAGER"], "BGProcessingTask completed")
								processingTask.setTaskCompleted(success: true)
							}
						}
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

		if 	photoLibraryChangeDetected {
			photoLibraryChangeDetected = false
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

	static let backgroundRefreshInterval = TimeInterval(20 * 60)

	func scheduleMediaRefreshTask() {

        let request = BGAppRefreshTaskRequest(identifier: "com.owncloud.background-task.instant-media-refresh")
		request.earliestBeginDate = Date(timeIntervalSinceNow: ScheduledTaskManager.backgroundRefreshInterval)
		do {
			try BGTaskScheduler.shared.submit(request)
		} catch {
			Log.error(tagged: ["TASK_MANAGER"], "Failed to submit BGAppRefreshTask request")
		}
	}

	func scheduleMediaUploadTask() {
        let request = BGProcessingTaskRequest(identifier: "com.owncloud.background-task.instant-media-upload")
		// At least to do export of media assets and import them into sync engine, we don't need connectivity
        request.requiresNetworkConnectivity = false
		do {
			try BGTaskScheduler.shared.submit(request)
		} catch {
			Log.error(tagged: ["TASK_MANAGER"], "Failed to submit BGProcessingTask request")
		}
	}

	func handleMediaRefresh(task: BGAppRefreshTask) {

		Log.log(tagged: ["TASK_MANAGER"], "BGAppRefreshTask launched")

		guard let userDefaults = OCAppIdentity.shared.userDefaults else { return }

		self.backgroundFetch()

		if shallMonitorPhotoLibraryChanges() && userDefaults.backgroundMediaUploadsEnabled {

			if checkForNewAssets() {
				scheduleMediaUploadTask()
			}

			// Schedule the next refresh
			scheduleMediaRefreshTask()
		}
		task.setTaskCompleted(success: true)
	}

	func handleMediaUpload(task: BGProcessingTask) {
		Log.log(tagged: ["TASK_MANAGER"], "BGProcessingTask launched")

		// This will kick-in task scheduling
		activeProcessingTask = task
		photoLibraryChangeDetected = true
	}
}

// MARK: - PHPhotoLibraryChangeObserver implementation

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

	private func checkForNewAssets() -> Bool {
		guard let userDefaults = OCAppIdentity.shared.userDefaults else { return false }

		Log.debug(tagged: ["TASK_MANAGER", "MEDIA_UPLOAD"], "Checking for new assets")

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
		guard let result = PHAsset.fetchAssetsFromCameraRoll(with: [.image, .video], createdAfter: earliestTimestamp, fetchLimit: 1) else {
			return false
		}

		Log.debug(tagged: ["TASK_MANAGER", "MEDIA_UPLOAD"], "\(result.count) new assets found ")

		return result.count > 0 ? true : false
	}
}

extension ScheduledTaskManager : CLLocationManagerDelegate {

	@discardableResult func startLocationMonitoringIfAuthorized() -> Bool {
		if CLLocationManager.authorizationStatus() == .authorizedAlways {
			Log.debug(tagged: ["TASK_MANAGER", "MEDIA_UPLOAD"], "Significant location monitoring has started")
			self.locationManager.startMonitoringSignificantLocationChanges()
			return true
		} else {
			return false
		}
	}

	func stopLocationMonitoring() {
		if CLLocationManager.authorizationStatus() == .authorizedAlways || CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
			locationManager.stopMonitoringSignificantLocationChanges()
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
			if checkForNewAssets() {
				photoLibraryChangeDetected = true
			}
		}
	}

	func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
		guard shallMonitorPhotoLibraryChanges() == true else { return }

		guard status == .authorizedAlways else { return }

		locationManager.startMonitoringSignificantLocationChanges()
	}
}
