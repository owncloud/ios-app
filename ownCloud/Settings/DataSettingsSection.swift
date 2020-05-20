//
//  DataSettingsSection.swift
//  ownCloud
//
//  Created by Felix Schwarz on 30.07.19.
//  Copyright © 2019 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2019, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import UIKit
import ownCloudSDK

class DataSettingsSection: SettingsSection {
	override init(userDefaults: UserDefaults) {
		super.init(userDefaults: userDefaults)

		self.headerTitle = "Data usage".localized

		cellularRow = StaticTableViewRow(valueRowWithAction: { [weak self] (_, _) in
			self?.pushCellularSettings()
		}, title: "Cellular transfers".localized, value: self.cellularSummary, accessoryType: .disclosureIndicator, identifier: "storage-use-cellular")

		self.add(row: cellularRow!)

		localCopyExpirationRow = StaticTableViewRow(valueRowWithAction: { [weak self] (_, _) in
			self?.pushLocalCopyExpirationSettings()
		}, title: "Delete unused local copies".localized, value: self.localCopyExpirationSummary, accessoryType: .disclosureIndicator, identifier: "storage-downloaded-files")

		self.add(row: localCopyExpirationRow!)
	}

	// MARK: - Cellular data properties
	var cellularRow : StaticTableViewRow?

	var cellularSummary : String {
		if let masterEnabled = OCCellularManager.shared.switch(withIdentifier: .master)?.allowed, masterEnabled {
			return "enabled".localized
		} else {
			return "off".localized
		}
	}

	// MARK: - Local copy expiration properties
	var localCopyExpirationRow : StaticTableViewRow?

	var localCopyExpirationEnabled : Bool {
		get {
			return OCItemPolicyProcessor.classSetting(forOCClassSettingsKey: .itemPolicyLocalCopyExpirationEnabled) as? Bool ?? false
		}

		set {
			OCItemPolicyProcessor.setUserPreferenceValue(NSNumber(value: newValue), forClassSettingsKey: .itemPolicyLocalCopyExpirationEnabled)
		}
	}

	var localCopyExpiration : Int {
		get {
			return OCItemPolicyProcessor.classSetting(forOCClassSettingsKey: .itemPolicyLocalCopyExpiration) as? Int ?? 0
		}

		set {
			OCItemPolicyProcessor.setUserPreferenceValue(newValue as NSNumber, forClassSettingsKey: .itemPolicyLocalCopyExpiration)
		}
	}

	func formatted(timeInterval: Int) -> String {
		let formatter = DateComponentsFormatter()

		formatter.unitsStyle = .full
		formatter.allowedUnits = [.day, .month, .year, .hour, .minute]
		formatter.maximumUnitCount = 1

		if let timeString = formatter.string(from: TimeInterval(timeInterval)) {
			return timeString
		} else {
			return "on".localized
		}
	}

	var localCopyExpirationSummary : String {
		if self.localCopyExpirationEnabled {
			return NSString(format: ("after %@".localized as NSString), formatted(timeInterval: localCopyExpiration)) as String
		} else {
			return "never".localized
		}
	}

	// MARK: - Cellular settings UI
	func pushCellularSettings() {
		let cellularSettingsViewController = CellularSettingsViewController(style: .grouped)

		cellularSettingsViewController.changeHandler = { [weak self] in
			self?.cellularRow?.cell?.detailTextLabel?.text = self?.cellularSummary
		}

		self.viewController?.navigationController?.pushViewController(cellularSettingsViewController, animated: true)
	}

	// MARK: - Local copy expiration UI
	func pushLocalCopyExpirationSettings() {
		let localCopyExpirationViewController = StaticTableViewController(style: .grouped)
		let localCopyExpirationSelectionSection = StaticTableViewSection(headerTitle: "Delete unused local copies".localized, footerTitle: "Time measured since uploading, editing, downloading or viewing the respective file through this device. Does not apply to files downloaded via the Available Offline feature. Local copies may be deleted before the given period of time has passed, f.ex. because there's a newer version of a file on the server - or through the manual deletion of offline copies. Also, local copies may not be deleted after the given period of time has passed, f.ex. if an action is performed on it, the file is still in use - or the account holding the file hasn't been used in the app.".localized)

		var timeIntervals : [Int] = [
			-1, // Off
			60, // 1 minute
			60 * 15, // 15 minutes
			60 * 60 * 1, // 1 hour
			60 * 60 * 2, // 2 hours
			60 * 60 * 12, // 12 hours
			60 * 60 * 24, // 1 day
			60 * 60 * 24 * 5, // 5 day
			60 * 60 * 24 * 7, // 7 days
			60 * 60 * 24 * 14, // 14 days
			60 * 60 * 24 * 30, // 30 days
			60 * 60 * 24 * 90, // 90 days
			60 * 60 * 24 * 180, // 180 days
			60 * 60 * 24 * 365 // 1 year
		]

		if !timeIntervals.contains(self.localCopyExpiration) {
			timeIntervals.append(self.localCopyExpiration)
			timeIntervals.sort()
		}

		let labelForTimeInterval : (Int) -> String = { (timeInterval) in
			if timeInterval == -1 {
				return "never".localized
			} else {
				return NSString(format: ("after %@".localized as NSString), self.formatted(timeInterval: timeInterval)) as String
			}
		}

		let labelForOffset : (Int) -> String = { (offset) in
			return labelForTimeInterval(timeIntervals[offset])
		}

		let offsetForTimeInterval : (Int) -> Int = { (timeInterval) in
			if let offset = timeIntervals.index(of: timeInterval) {
				return offset
			}

			return 0
		}

		localCopyExpirationViewController.navigationItem.title = "Storage".localized

		let timeIntervalRow = StaticTableViewRow(valueRowWithAction: nil, title: "", value: labelForTimeInterval(self.localCopyExpirationEnabled ? self.localCopyExpiration : -1))

		localCopyExpirationSelectionSection.add(row: StaticTableViewRow(sliderWithAction: { [weak self] (_, sender) in
			guard let newValue = (sender as? UISlider)?.value else { return }

			var sliderValue = Int(newValue)

			if newValue > (Float(timeIntervals.count) / 2) {
				sliderValue = Int(newValue + 0.6)
			}

			if sliderValue < 0 { sliderValue = 0 }
			if sliderValue > timeIntervals.count { sliderValue = timeIntervals.count-1 }

			(sender as? UISlider)?.value = Float(sliderValue)

			let timeInterval = timeIntervals[sliderValue]

			if timeInterval == -1 {
				self?.localCopyExpirationEnabled = false
			} else {
				self?.localCopyExpirationEnabled = true
				self?.localCopyExpiration = timeInterval
			}

			timeIntervalRow.cell?.detailTextLabel?.text = labelForOffset(sliderValue)

			self?.localCopyExpirationRow?.cell?.detailTextLabel?.text = self?.localCopyExpirationSummary
		}, minimumValue: 0, maximumValue: Float(timeIntervals.count-1)+0.01, value: Float(offsetForTimeInterval(self.localCopyExpirationEnabled ? self.localCopyExpiration : -1))))

		localCopyExpirationSelectionSection.add(row: timeIntervalRow)

		localCopyExpirationViewController.addSection(localCopyExpirationSelectionSection)

		self.viewController?.navigationController?.pushViewController(localCopyExpirationViewController, animated: true)
	}
}
