//
//  LogSettingsViewController.swift
//  ownCloud
//
//  Created by Felix Schwarz on 08.11.18.
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

extension OCLogLevel {
	var label : String {
		switch self {
			case .debug:
				return "Debug".localized
			case .info:
				return "Info".localized
			case .warning:
				return "Warning".localized
			case .error:
				return "Error".localized
			case .off:
				return "Off".localized
		}
	}
}

class LogSettingsViewController: StaticTableViewController {

	private let loggingSection = StaticTableViewSection(headerTitle: "Logging".localized)
	private var logLevelSection : StaticTableViewSection?
	private var logOutputSection : StaticTableViewSection?
	private var logTogglesSection : StaticTableViewSection?
	private var logPrivacySection : StaticTableViewSection?

	static let logLevelChangedNotificationName = NSNotification.Name("settings.log-level-changed")

	static var loggingEnabled : Bool {
		get {
			return OCLogger.logLevel.rawValue != OCLogLevel.off.rawValue
		}

		set {
			OCLogger.logLevel = newValue ? .debug : .off
			NotificationCenter.default.post(name: LogSettingsViewController.logLevelChangedNotificationName, object: nil)
		}
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		self.navigationItem.title = "Logging".localized

		// Logging
		loggingSection.add(row: StaticTableViewRow(switchWithAction: { [weak self] (row, _) in
			if let enabled = row.value as? Bool {
				LogSettingsViewController.loggingEnabled = enabled
				self?.updateSectionVisibility(animated: true)
			}
		}, title: "Enable logging".localized, value: LogSettingsViewController.loggingEnabled, identifier: "enable-logging"))

		// Update section visibility
		self.addSection(loggingSection)

		updateSectionVisibility(animated: false)
	}

	private func updateSectionVisibility(animated: Bool) {
		if LogSettingsViewController.loggingEnabled {
			var addSections : [StaticTableViewSection] = []

			// Log level
			if logLevelSection == nil {
				logLevelSection = StaticTableViewSection(headerTitle: "Log Level".localized)

				let logLevels : [[String:Any]] = [
					[ OCLogLevel.debug.label   : OCLogLevel.debug.rawValue   ],
					[ OCLogLevel.info.label    : OCLogLevel.info.rawValue    ],
					[ OCLogLevel.warning.label : OCLogLevel.warning.rawValue ],
					[ OCLogLevel.error.label   : OCLogLevel.error.rawValue   ]
				]

				logLevelSection?.add(radioGroupWithArrayOfLabelValueDictionaries: logLevels, radioAction: { (row, _) in
					if let logLevel = row.value as? Int {
						OCLogger.logLevel = OCLogLevel(rawValue: logLevel)!

						NotificationCenter.default.post(name: LogSettingsViewController.logLevelChangedNotificationName, object: nil)
					}
				}, groupIdentifier: "log-level", selectedValue: OCLogger.logLevel.rawValue)

				addSections.append(logLevelSection!)
			}

			// Log toggles
			if logTogglesSection == nil {
				logTogglesSection = StaticTableViewSection(headerTitle: "Options".localized)

				for toggle in OCLogger.shared.toggles {
					let row = StaticTableViewRow(switchWithAction: { (row, _) in
						if let enabled = row.value as? Bool {
							toggle.enabled = enabled
						}
					}, title: toggle.localizedName, value: toggle.enabled, identifier: toggle.identifier.rawValue)

					logTogglesSection?.add(row: row)
				}

				addSections.append(logTogglesSection!)
			}

			// Log output
			if logOutputSection == nil {
				logOutputSection = StaticTableViewSection(headerTitle: "Log Destinations".localized)

				var logFileWriterSwitchRow : StaticTableViewRow?

				for writer in OCLogger.shared.writers {
					let row = StaticTableViewRow(switchWithAction: { (row, _) in
						if let enabled = row.value as? Bool {
							writer.enabled = enabled
						}
					}, title: writer.name, value: writer.enabled, identifier: writer.identifier.rawValue)

					if writer.identifier == .writerFile {
						logFileWriterSwitchRow = row
					}

					logOutputSection?.add(row: row)
				}

				logOutputSection?.add(row: StaticTableViewRow(buttonWithAction: { [weak self] (row, _) in
					if let logFileWriter = OCLogger.shared.writer(withIdentifier: .writerFile) as? OCLogFileWriter {
						if !FileManager.default.fileExists(atPath: logFileWriter.logFileURL.path) {
							let alert = UIAlertController(title: "No log file found".localized, message: "The log file can't be shared because no log file could be found or the log file is empty.".localized, preferredStyle: .alert)

							alert.addAction(UIAlertAction(title: "Cancel".localized, style: .default, handler: nil))

							if !logFileWriter.enabled {
								alert.addAction(UIAlertAction(title: "Enable log file".localized, style: .default, handler: { (_) in
									logFileWriter.enabled = true
									logFileWriterSwitchRow?.value = logFileWriter.enabled
								}))
							}

							self?.present(alert, animated: true, completion: nil)
						} else {
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

							if UIDevice.current.isIpad() {
								shareViewController.popoverPresentationController?.sourceView = row.cell
								shareViewController.popoverPresentationController?.sourceRect = CGRect(x: row.cell?.bounds.midX ?? 0, y: row.cell?.bounds.midY ?? 0, width: 1, height: 1)
								shareViewController.popoverPresentationController?.permittedArrowDirections = .down
							}

							row.viewController?.present(shareViewController, animated: true, completion: nil)
						}
					}
				}, title: "Share log file".localized, style: .plain, identifier: "share-logfile"))

				logOutputSection?.add(row: StaticTableViewRow(buttonWithAction: { (row, _) in
					let alert = UIAlertController(with: "Really reset log file?".localized, message: "This action can't be undone.".localized, destructiveLabel: "Reset log file".localized, preferredStyle: .alert, destructiveAction: {
						OCLogger.shared.pauseWriters(intermittentBlock: {
							if let logFileWriter = OCLogger.shared.writer(withIdentifier: .writerFile) as? OCLogFileWriter {
//								logFileWriter.eraseOrTruncate()
							}
						})
					})

					row.viewController?.present(alert, animated: true, completion: nil)
				}, title: "Reset log file".localized, style: .destructive, identifier: "reset-logfile"))

				addSections.append(logOutputSection!)
			}

			// Privacy
			if logPrivacySection == nil {
				logPrivacySection = StaticTableViewSection(headerTitle: "Privacy".localized)

				logPrivacySection?.add(row: StaticTableViewRow(switchWithAction: { (row, _) in
					if let maskPrivateData = row.value as? Bool {
						OCLogger.maskPrivateData = maskPrivateData
					}
				}, title: "Mask private data".localized, value: OCLogger.maskPrivateData, identifier: "mask-private-data"))
				logPrivacySection?.footerTitle = "Enabling this option will attempt to mask private data, so it does not become part of any log. Since logging is a development and debugging feature, though, we can't guarantee that the log file will be free of any private data even with this option enabled. Therefore, please look through any log file and verify its free of any data you're not comfortable sharing before sharing it with anybody.".localized

				addSections.append(logPrivacySection!)
			}

			if addSections.count > 0 {
				self.addSections(addSections, animated: animated)
			}
		} else {
			var removeSections : [StaticTableViewSection] = []

			if logLevelSection != nil {
				removeSections.append(logLevelSection!)
				logLevelSection = nil
			}
			if logTogglesSection != nil {
				removeSections.append(logTogglesSection!)
				logTogglesSection = nil
			}
			if logOutputSection != nil {
				removeSections.append(logOutputSection!)
				logOutputSection = nil
			}
			if logPrivacySection != nil {
				removeSections.append(logPrivacySection!)
				logPrivacySection = nil
			}

			self.removeSections(removeSections, animated: animated)
		}
	}
}
