//
//  ScheduledTaskManager.swift
//  ownCloud
//
//  Created by Michael Neuwert on 28.05.2019.
//  Copyright © 2019 ownCloud GmbH. All rights reserved.
//

import Foundation
import UIKit
import Network
import Photos

class ScheduledTaskManager : NSObject, PHPhotoLibraryChangeObserver {

	enum State {
		case launched, foreground, background, backgroundFetch
	}

	static let shared = ScheduledTaskManager()

	private var state: State = .launched
	private static let lowBatteryThreshold : Float = 0.2
	private var lowBatteryDetected = false
	private var externalPowerConnected = false
	private var wifiDetected = false
	private var wifiMonitorQueue: DispatchQueue?
	private var wifiMonitor : Any?

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
		// Monitor app states
		NotificationCenter.default.addObserver(self, selector: #selector(applicationStateChange), name: UIApplication.didEnterBackgroundNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(applicationStateChange), name: UIApplication.didBecomeActiveNotification, object: nil)

		PHPhotoLibrary.shared().register(self)

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
	}

	deinit {
		PHPhotoLibrary.shared().unregisterChangeObserver(self)
		NotificationCenter.default.removeObserver(self)
		if #available(iOS 12, *) {
			(wifiMonitor as? NWPathMonitor)?.cancel()
		}
	}

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

	func photoLibraryDidChange(_ changeInstance: PHChange) {
		//TODO:
	}

	private func scheduleTasks() {
		OnMainThread {
			// TODO Build a context

			// TODO Find matching extensions

			// TODO Find a task to run
		}
	}

	private func checkPowerState() {
		lowBatteryDetected = (UIDevice.current.batteryLevel <= ScheduledTaskManager.lowBatteryThreshold)
		externalPowerConnected = (UIDevice.current.batteryState != .unplugged)
	}
}
