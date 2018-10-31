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
		}, title: "Theme".localized, value: ThemeStyle.preferredStyle.localizedName)

		self.add(row: themeRow!)

		self.add(row: StaticTableViewRow(rowWithAction: { [weak self] (_, _) in
			self?.pushLogSettings()
		}, title: "Logging".localized, accessoryType: .disclosureIndicator, identifier: "logging"))
	}

	deinit {
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
		let logSettingsViewController = StaticTableViewController(style: .grouped)
		let logLevelSection = StaticTableViewSection(headerTitle: "Log Level".localized)
		let logOutputSection = StaticTableViewSection(headerTitle: "Log Output".localized)
		let logPrivacySection = StaticTableViewSection(headerTitle: "Privacy".localized)

		logSettingsViewController.navigationItem.title = "Logging".localized

		// Log level
		let logLevels : [[String:Any]] = [
			[ "Off".localized     : OCLogLevel.off.rawValue     ],
			[ "Debug".localized   : OCLogLevel.debug.rawValue   ],
			[ "Default".localized : OCLogLevel.default.rawValue ],
			[ "Warning".localized : OCLogLevel.warning.rawValue ],
			[ "Error".localized   : OCLogLevel.error.rawValue   ]
		]

		logLevelSection.add(radioGroupWithArrayOfLabelValueDictionaries: logLevels, radioAction: { (row, _) in
			if let logLevel = row.value as? Int {
				OCLogger.logLevel = OCLogLevel(rawValue: logLevel)!
			}
		}, groupIdentifier: "log-level", selectedValue: OCLogger.logLevel.rawValue)

		logSettingsViewController.addSection(logLevelSection)

		// Log output
		for writer in OCLogger.shared.writers {
			logOutputSection.add(row: StaticTableViewRow(switchWithAction: { (row, _) in
				if let enabled = row.value as? Bool {
					writer.enabled = enabled
				}
			}, title: writer.name, value: writer.enabled, identifier: writer.identifier.rawValue))
		}

		logOutputSection.add(row: StaticTableViewRow(buttonWithAction: { (row, _) in
			if let logFileWriter = OCLogger.shared.writer(withIdentifier: .file) as? OCLogFileWriter {
				let logURL = FileManager.default.temporaryDirectory.appendingPathComponent("ownCloud App Log.txt")

				do {
					if FileManager.default.fileExists(atPath: logURL.path) {
						try FileManager.default.removeItem(at: logURL)
					}

					try FileManager.default.copyItem(at: logFileWriter.logFileURL, to: logURL)
				} catch {
				}

				let shareViewController = UIActivityViewController(activityItems: [logURL], applicationActivities:nil)
				shareViewController.completionWithItemsHandler = { (_, _, _, _) in
					do {
						try FileManager.default.removeItem(at: logURL)
					} catch {
					}
				}
				row.viewController?.present(shareViewController, animated: true, completion: nil)
			}
		}, title: "Share logfile".localized, style: .plain, identifier: "share-logfile"))

		logOutputSection.add(row: StaticTableViewRow(buttonWithAction: { (_, _) in
			if let logFileWriter = OCLogger.shared.writer(withIdentifier: .file) as? OCLogFileWriter {
				logFileWriter.eraseOrTruncate()
			}
		}, title: "Reset logfile".localized, style: .destructive, identifier: "reset-logfile"))

		logSettingsViewController.addSection(logOutputSection)

		// Privacy
		logPrivacySection.add(row: StaticTableViewRow(switchWithAction: { (row, _) in
			if let maskPrivateData = row.value as? Bool {
				OCLogger.maskPrivateData = maskPrivateData
			}
		}, title: "Mask private data".localized, value: OCLogger.maskPrivateData, identifier: "mask-private-data"))
		logPrivacySection.footerTitle = "Enabling this option will attempt to mask private data, so it does not become part of any log. Since logging is a development and debugging feature, though, we can't guarantee that the log file will be free of any private data even with this option enabled. Therefore, please look through any log file and verify its free of any data you're not comfortable sharing before sharing it with anybody.".localized

		logSettingsViewController.addSection(logPrivacySection)

		self.viewController?.navigationController?.pushViewController(logSettingsViewController, animated: true)
	}
}
