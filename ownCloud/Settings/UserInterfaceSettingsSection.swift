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
	var themeStyleNotificationObserverToken : Any?
	var styleSelectorViewController : StaticTableViewController?

	override init(userDefaults: UserDefaults) {
		super.init(userDefaults: userDefaults)

		self.headerTitle = "User Interface".localized
		self.identifier = "ui-section"

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

		themeStyleNotificationObserverToken = NotificationCenter.default.addObserver(forName: ThemeStyle.themeStyleChangedNotificationName, object: nil, queue: OperationQueue.main) { (_) in
			self.updateThemeStyleSelectionUI()
		}

		self.add(row: loggingRow!)
	}

	deinit {
		if loggingNotificationObserverToken != nil {
			NotificationCenter.default.removeObserver(loggingNotificationObserverToken!)
		}
		if themeStyleNotificationObserverToken != nil {
			NotificationCenter.default.removeObserver(themeStyleNotificationObserverToken!)
		}
	}

	func pushThemeStyleSelector() {
		styleSelectorViewController = StaticTableViewController(style: .grouped)
		guard let styleSelectorViewController = styleSelectorViewController else { return }

		styleSelectorViewController.navigationItem.title = "Theme".localized

		if #available(iOS 13, *) {
			styleSelectorViewController.addSection(StaticTableViewSection(headerTitle: "System light / dark appearance".localized, rows: [
				StaticTableViewRow(switchWithAction: { [weak themeRow] (_, sender) in
					if let followAppearanceSwitch = sender as? UISwitch {
						ThemeStyle.followSystemAppearance = followAppearanceSwitch.isOn

						if ThemeStyle.followSystemAppearance {
							if ThemeStyle.userInterfaceStyle() == .dark {
								if let darkStyleIdentifier = ThemeStyle.preferredStyle.darkStyleIdentifier, let style = ThemeStyle.forIdentifier(darkStyleIdentifier) {
									ThemeStyle.preferredStyle = style
								}
							} else {
								if ThemeStyle.preferredStyle.themeStyle == .dark, let lightStyle = ThemeStyle.availableStyles(for: [.light, .contrast])?.first {
									ThemeStyle.preferredStyle = lightStyle
								}
							}
						}

						themeRow?.cell?.detailTextLabel?.text = ThemeStyle.displayName
						self.updateThemeStyleSelectionUI()
					}
					}, title: "Follow system appearance".localized, value: ThemeStyle.followSystemAppearance, identifier: "theme-auto-dark-mode")
			]))
		}
		updateThemeStyleSelectionUI()
		self.viewController?.navigationController?.pushViewController(styleSelectorViewController, animated: true)
	}

	func updateThemeStyleSelectionUI() {
		guard let styleSelectorViewController = styleSelectorViewController else { return }

		if let styleSelectorSection = styleSelectorViewController.sectionForIdentifier("theme-style-selection") {
			styleSelectorViewController.removeSection(styleSelectorSection, animated: true)
		}
		let styleSelectorSection = StaticTableViewSection(headerTitle: "Theme".localized, footerTitle: nil, identifier: "theme-style-selection")

		var availableStyles = ThemeStyle.availableStyles
		if #available(iOS 13.0, *), ThemeStyle.followSystemAppearance, let currentStyles = ThemeStyle.userInterfaceStyle()?.themeCollectionStyles() {
			availableStyles = ThemeStyle.availableStyles(for: currentStyles)
		}

		if let availableStyles = availableStyles {
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
		styleSelectorViewController.addSection(styleSelectorSection, animated: true)
	}

	func pushLogSettings() {
		self.viewController?.navigationController?.pushViewController(LogSettingsViewController(style: .grouped), animated: true)
	}
}
