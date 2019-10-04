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

class UserInterfaceSettingsSection: SettingsSection {
	var themeRow : StaticTableViewRow?
	var loggingRow : StaticTableViewRow?
	var loggingNotificationObserverToken : Any?

	override init(userDefaults: UserDefaults) {
		super.init(userDefaults: userDefaults)

		self.headerTitle = "User Interface".localized
		self.identifier = "ui-section"

		var themeStylesByName : [[String:String]] = []

		for themeStyle in ThemeCollectionStyle.allCases {
			themeStylesByName.append([themeStyle.name : themeStyle.rawValue])
		}

		themeRow = StaticTableViewRow(valueRowWithAction: { [weak self] (_, _) in
			self?.pushThemeStyleSelector()
			}, title: "Theme".localized, value: ThemeStyle.displayName, accessoryType: .disclosureIndicator, identifier: "theme")

		self.add(row: themeRow!)

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
		let styleSelectorViewController = StaticTableViewController(style: .grouped)

		styleSelectorViewController.navigationItem.title = "Theme".localized
		var showThemeStyleSelection = true

		if #available(iOS 13, *) {
			styleSelectorViewController.addSection(StaticTableViewSection(headerTitle: "System light / dark appearance".localized, rows: [
				StaticTableViewRow(switchWithAction: { [weak styleSelectorViewController, themeRow] (_, sender) in
					if let followAppearanceSwitch = sender as? UISwitch {
						ThemeStyle.followSystemAppearance = followAppearanceSwitch.isOn

						themeRow?.cell?.detailTextLabel?.text = ThemeStyle.displayName
						if let styleSelectorViewController = styleSelectorViewController {
							self.showThemeStyleSelectionUI(!ThemeStyle.followSystemAppearance, viewController: styleSelectorViewController)
						}
					}
				}, title: "Follow system appearance".localized, value: ThemeStyle.followSystemAppearance, identifier: "theme-auto-dark-mode")
			]))
			showThemeStyleSelection = !ThemeStyle.followSystemAppearance
		}
		showThemeStyleSelectionUI(showThemeStyleSelection, viewController: styleSelectorViewController)
		self.viewController?.navigationController?.pushViewController(styleSelectorViewController, animated: true)
	}

	func showThemeStyleSelectionUI(_ showThemeStyleSelection : Bool, viewController : StaticTableViewController) {
		if showThemeStyleSelection {
			let styleSelectorSection = StaticTableViewSection(headerTitle: "Theme".localized, footerTitle: nil, identifier: "theme-style-selection")
			if let availableStyles = ThemeStyle.availableStyles {
				var themeIdentifiersByName : [[String:Any]] = []

				for style in availableStyles {
					themeIdentifiersByName.append([style.localizedName : style.identifier ])
				}

				styleSelectorSection.add(radioGroupWithArrayOfLabelValueDictionaries: themeIdentifiersByName, radioAction: { [weak themeRow] (row, _) in
					if let styleIdentifier = row.value as? String,
						let style = ThemeStyle.forIdentifier(styleIdentifier) {
						ThemeStyle.preferredStyle = style

						themeRow?.cell?.detailTextLabel?.text = ThemeStyle.displayName
					}
					}, groupIdentifier: "theme-id", selectedValue: ThemeStyle.preferredStyle.identifier)
			}
			viewController.addSection(styleSelectorSection, animated: true)
		} else {
			if let styleSelectorSection = viewController.sectionForIdentifier("theme-style-selection") {
				viewController.removeSection(styleSelectorSection, animated: true)
			}
		}
	}

	func pushLogSettings() {
		self.viewController?.navigationController?.pushViewController(LogSettingsViewController(style: .grouped), animated: true)
	}
}
