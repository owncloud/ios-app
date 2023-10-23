//
//  ThemeSettingsSection.swift
//  ownCloud
//
//  Created by Felix Schwarz on 26.10.18.
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
import ownCloudApp
import ownCloudAppShared

class UserInterfaceSettingsSection: SettingsSection {
	var themeRow : StaticTableViewRow?
	var loggingRow : StaticTableViewRow?
	var loggingNotificationObserverToken : Any?

	override init(userDefaults: UserDefaults) {
		super.init(userDefaults: userDefaults)

		self.headerTitle = "User Interface".localized
		self.identifier = "ui-section"

		themeRow = StaticTableViewRow(valueRowWithAction: { [weak self] (_, _) in
			self?.pushThemeStyleSelector()
			}, title: "Theme".localized, value: ThemeStyle.displayName, accessoryType: .disclosureIndicator, identifier: "theme")

		if Branding.shared.allowThemeSelection {
			self.add(row: themeRow!)
		}

		loggingRow = StaticTableViewRow(valueRowWithAction: { [weak self] (_, _) in
			self?.pushLogSettings()
			}, title: "Logging".localized, value: OCLogger.logLevel.label, accessoryType: .disclosureIndicator, identifier: "logging")

		loggingNotificationObserverToken = NotificationCenter.default.addObserver(forName: LogSettingsViewController.logLevelChangedNotificationName, object: nil, queue: OperationQueue.main) { [weak loggingRow] (_) in
			loggingRow?.cell?.detailTextLabel?.text = OCLogger.logLevel.label
		}

		self.add(row: loggingRow!)
	}

	deinit {
		if loggingNotificationObserverToken != nil {
			NotificationCenter.default.removeObserver(loggingNotificationObserverToken!)
		}
	}

	func pushThemeStyleSelector() {
		let styleSelectorViewController = StaticTableViewController(style: .insetGrouped)
		styleSelectorViewController.navigationItem.title = "Theme".localized

		if let styleSelectorSection = styleSelectorViewController.sectionForIdentifier("theme-style-selection") {
			styleSelectorViewController.removeSection(styleSelectorSection, animated: true)
		}
		let styleSelectorSection = StaticTableViewSection(headerTitle: "Theme".localized, footerTitle: nil, identifier: "theme-style-selection")

		if let availableStyles = ThemeStyle.availableStyles {
			var themeIdentifiersByName : [[String:Any]] = []
			var selectedValue = ThemeStyle.preferredStyle.identifier

			themeIdentifiersByName = [["System Appeareance".localized : "com.owncloud.system"]]
			if ThemeStyle.followSystemAppearance {
				selectedValue = "com.owncloud.system"
			}

			for style in availableStyles {
				themeIdentifiersByName.append([style.localizedName : style.identifier ])
			}

			styleSelectorSection.add(radioGroupWithArrayOfLabelValueDictionaries: themeIdentifiersByName, radioAction: { [weak themeRow] (row, _) in
				if let styleIdentifier = row.value as? String, styleIdentifier == "com.owncloud.system" {
					ThemeStyle.followSystemAppearance = true
					themeRow?.cell?.detailTextLabel?.text = "System".localized
				} else if let styleIdentifier = row.value as? String,
					let style = ThemeStyle.forIdentifier(styleIdentifier), ThemeStyle.preferredStyle != style {
						ThemeStyle.followSystemAppearance = false
						ThemeStyle.preferredStyle = style

					themeRow?.cell?.detailTextLabel?.text = ThemeStyle.displayName
				}
				}, groupIdentifier: "theme-id", selectedValue: selectedValue)
		}
		styleSelectorViewController.addSection(styleSelectorSection, animated: true)

		self.viewController?.navigationController?.pushViewController(styleSelectorViewController, animated: true)
	}

	func pushLogSettings() {
		self.viewController?.navigationController?.pushViewController(LogSettingsViewController(style: .insetGrouped), animated: true)
	}
}
