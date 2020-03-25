//
//  ClientActivityViewController.swift
//  ownCloud
//
//  Created by Felix Schwarz on 26.01.19.
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

class ClientActivityViewController: UITableViewController, Themeable {
	enum ActivitySection : Int, CaseIterable {
		case messages
		case activities
	}

	weak var core : OCCore? {
		willSet {
			if let core = core {
				NotificationCenter.default.removeObserver(self, name: core.activityManager.activityUpdateNotificationName, object: nil)
			}

			messageSelector = nil
		}

		didSet {
			if let core = core {
				let bookmarkUUID = core.bookmark.uuid

				NotificationCenter.default.addObserver(self, selector: #selector(handleActivityNotification(_:)), name: core.activityManager.activityUpdateNotificationName, object: nil)

				messageSelector = MessageSelector(from: core.messageQueue, filter: { (message) in
					return (message.bookmarkUUID == bookmarkUUID)
				}, handler: { (messages) in
					OnMainThread {
						self.messages = messages
						self.setNeedsDataReload()
					}
				})
			}
		}
	}

	var messageSelector : MessageSelector?
	var messages : [OCMessage]?

	var activities : [OCActivity]?
	var isOnScreen : Bool = false {
		didSet {
			updateDisplaySleep()
		}
	}

	private var shouldPauseDisplaySleep : Bool = false {
		didSet {
			updateDisplaySleep()
		}
	}

	private func updateDisplaySleep() {
		pauseDisplaySleep = isOnScreen && shouldPauseDisplaySleep
	}

	private var pauseDisplaySleep : Bool = false {
		didSet {
			if pauseDisplaySleep != oldValue {
				if pauseDisplaySleep {
					DisplaySleepPreventer.shared.startPreventingDisplaySleep()
				} else {
					DisplaySleepPreventer.shared.stopPreventingDisplaySleep()
				}
			}
		}
	}

	deinit {
		Theme.shared.unregister(client: self)
		self.shouldPauseDisplaySleep = false
		self.core = nil
	}

	@objc func handleActivityNotification(_ notification: Notification) {
		if let activitiyUpdates = notification.userInfo?[OCActivityManagerNotificationUserInfoUpdatesKey] as? [ [ String : Any ] ] {
			for activityUpdate in activitiyUpdates {
				if let updateTypeInt = activityUpdate[OCActivityManagerUpdateTypeKey] as? UInt, let updateType = OCActivityUpdateType(rawValue: updateTypeInt) {
					switch updateType {
						case .publish, .unpublish:
							setNeedsDataReload()

							if core?.activityManager.activities.count == 0 {
								shouldPauseDisplaySleep = false
							} else {
								shouldPauseDisplaySleep = true
							}

						case .property:
							if isOnScreen,
							   let activity = activityUpdate[OCActivityManagerUpdateActivityKey] as? OCActivity,
							   let firstIndex = activities?.firstIndex(of: activity) {
							   	// Update just the updated activity
								self.tableView.reloadRows(at: [IndexPath(row: firstIndex, section: ActivitySection.activities.rawValue)], with: .none)
							} else {
								// Schedule table reload if not on-screen
								setNeedsDataReload()
							}
					}
				}
			}
		}
	}

	var needsDataReload : Bool = true

	func setNeedsDataReload() {
		needsDataReload = true
		self.reloadDataIfOnScreen()
	}

	func reloadDataIfOnScreen() {
		if needsDataReload, isOnScreen {
			needsDataReload = false

			activities = core?.activityManager.activities
			self.tableView.reloadData()
		}
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		self.tableView.register(ClientActivityCell.self, forCellReuseIdentifier: "activity-cell")
		self.tableView.register(MessageCell.self, forCellReuseIdentifier: "message-cell")
		self.tableView.rowHeight = UITableView.automaticDimension
		self.tableView.estimatedRowHeight = 80

		Theme.shared.register(client: self, applyImmediately: true)
	}

	func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		self.tableView.applyThemeCollection(collection)
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		self.navigationItem.title = "Status".localized
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		isOnScreen = true

		self.reloadDataIfOnScreen()
	}

	override func viewWillDisappear(_ animated: Bool) {
		isOnScreen = false
		super.viewWillDisappear(animated)
	}

	// MARK: - Table view data source

	override func numberOfSections(in tableView: UITableView) -> Int {
		return ActivitySection.allCases.count
	}

	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		// #warning Incomplete implementation, return the number of rows
		switch ActivitySection(rawValue: section) {
			case .messages:
				return messages?.count ?? 0

			case .activities:
				return activities?.count ?? 0

			default:
				return 0
		}
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		switch ActivitySection(rawValue: indexPath.section) {
			case .messages:
				guard let cell = tableView.dequeueReusableCell(withIdentifier: "message-cell", for: indexPath) as? MessageCell else {
					return UITableViewCell()
				}

				if let messages = messages, indexPath.row < messages.count {
					cell.message = messages[indexPath.row]
				}

				return cell

			case .activities:
				guard let cell = tableView.dequeueReusableCell(withIdentifier: "activity-cell", for: indexPath) as? ClientActivityCell else {
					return UITableViewCell()
				}

				if let activities = activities, indexPath.row < activities.count {
					cell.activity = activities[indexPath.row]
				}

				return cell

			default:
				return UITableViewCell()
		}
	}

	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		switch ActivitySection(rawValue: indexPath.section) {
			case .messages:
				if let messages = messages, indexPath.row < messages.count {
					if let core = core, let coreDelegate = core.delegate, let queue = messageSelector?.queue {
						coreDelegate.core(core, handleError: nil, issue: OCIssue(from: messages[indexPath.row], from: queue))
					}
				}

			default: break
		}
	}

	override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
		switch ActivitySection(rawValue: indexPath.section) {
			case .messages:
				return true

			default:
				return false
		}
	}

	override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
		switch ActivitySection(rawValue: indexPath.section) {
			case .messages:
				return indexPath

			default:
				return nil
		}
	}
}
