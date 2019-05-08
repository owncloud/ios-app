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
		}, title: "Theme".localized, value: ThemeStyle.preferredStyle.localizedName, accessoryType: .disclosureIndicator)

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
		let styleSelectorSection = StaticTableViewSection(headerTitle: "Theme".localized)

		styleSelectorViewController.navigationItem.title = "Theme".localized

		if let availableStyles = ThemeStyle.availableStyles {
			var themeIdentifiersByName : [[String:Any]] = []

			for style in availableStyles {
				themeIdentifiersByName.append([style.localizedName : style.identifier ])
			}

			styleSelectorSection.add(radioGroupWithArrayOfLabelValueDictionaries: themeIdentifiersByName, radioAction: { [weak themeRow] (row, _) in
				if let styleIdentifier = row.value as? String,
				   let style = ThemeStyle.forIdentifier(styleIdentifier) {
					ThemeStyle.preferredStyle = style
					Theme.shared.switchThemeCollection(ThemeCollection(with: style))

					themeRow?.cell?.detailTextLabel?.text = style.localizedName
				}
			}, groupIdentifier: "theme-id", selectedValue: ThemeStyle.preferredStyle.identifier)
		}

		styleSelectorViewController.addSection(styleSelectorSection)

		self.viewController?.navigationController?.pushViewController(styleSelectorViewController, animated: true)
	}

	func pushLogSettings() {
		self.viewController?.navigationController?.pushViewController(LogSettingsViewController(style: .grouped), animated: true)
	}
}
