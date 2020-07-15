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

public class ClientActivityViewController: UITableViewController, Themeable, MessageGroupCellDelegate, ClientActivityCellDelegate {

	enum ActivitySection : Int, CaseIterable {
		case messageGroups
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
				NotificationCenter.default.addObserver(self, selector: #selector(handleActivityNotification(_:)), name: core.activityManager.activityUpdateNotificationName, object: nil)
			}
		}
	}

	weak var messageSelector : MessageSelector?
	var messageGroups : [MessageGroup]?

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
	func handleMessagesUpdates(messages: [OCMessage]?, groups : [MessageGroup]?) {

		if let tabBarItem = self.navigationController?.tabBarItem {
			if let messageCount = messages?.count, messageCount > 0 {
				tabBarItem.badgeValue = "\(messageCount)"
			} else {
				tabBarItem.badgeValue = nil
			}
		}

		self.setNeedsDataReload()
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
			messageGroups = messageSelector?.groupedSelection

			self.tableView.reloadData()

			if (activities?.count ?? 0) == 0, (messageGroups?.count ?? 0) == 0 {
				self.messageView?.message(show: true, imageName: "status-flash", title: "All done".localized, message: "No pending messages or ongoing actions.".localized)
			} else {
				self.messageView?.message(show: false)
			}
		}
	}

	var messageView : MessageView?

	public override func viewDidLoad() {
		super.viewDidLoad()

		self.tableView.register(ClientActivityCell.self, forCellReuseIdentifier: "activity-cell")
		self.tableView.register(MessageGroupCell.self, forCellReuseIdentifier: "message-group-cell")
		self.tableView.rowHeight = UITableView.automaticDimension
		self.tableView.estimatedRowHeight = 80

		Theme.shared.register(client: self, applyImmediately: true)

		messageView = MessageView(add: self.view)
	}

	public func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		self.tableView.applyThemeCollection(collection)
	}

	public override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		self.navigationItem.title = "Status".localized
	}

	public override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		isOnScreen = true

		self.reloadDataIfOnScreen()
	}

	public override func viewWillDisappear(_ animated: Bool) {
		isOnScreen = false
		super.viewWillDisappear(animated)
	}

	// MARK: - MessageGroupCell delegate
	public func cell(_ cell: MessageGroupCell, showMessagesLike likeMessage: OCMessage) {
		if let core = core, let likeMessageCategoryID = likeMessage.categoryIdentifier {
			let bookmarkUUID = core.bookmark.uuid

			let messageTableViewController = MessageTableViewController(with: core, messageFilter: { (message) -> Bool in
				return (message.categoryIdentifier == likeMessageCategoryID) && (message.bookmarkUUID == bookmarkUUID) && !message.resolved
			})

			self.navigationController?.pushViewController(messageTableViewController, animated: true)
		}
	}

	// MARK: - ClientActivityCell delegate
	func showMessage(for activity: OCActivity) {
		if let syncRecordActivity = activity as? OCSyncRecordActivity,
		   let firstMatchingMessage = messageSelector?.selection?.first(where: { (message) -> Bool in
			return message.syncIssue?.syncRecordID == syncRecordActivity.recordID
		}) {
			firstMatchingMessage.showInApp()
		}
 	}

	func hasMessage(for activity: OCActivity) -> Bool {
		guard let syncRecordActivity = activity as? OCSyncRecordActivity else {
			return false
		}

		return messageSelector?.syncRecordIDsInSelection?.contains(syncRecordActivity.recordID) ?? false
	}

	// MARK: - Table view data source

	public override func numberOfSections(in tableView: UITableView) -> Int {
		return ActivitySection.allCases.count
	}

	public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		switch ActivitySection(rawValue: section) {
			case .messageGroups:
				return messageGroups?.count ?? 0

			case .activities:
				return activities?.count ?? 0

			default:
				return 0
		}
	}

	public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		switch ActivitySection(rawValue: indexPath.section) {
			case .messageGroups:
				guard let cell = tableView.dequeueReusableCell(withIdentifier: "message-group-cell", for: indexPath) as? MessageGroupCell else {
					return UITableViewCell()
				}

				if let messageGroups = messageGroups, indexPath.row < messageGroups.count {
					cell.messageGroup = messageGroups[indexPath.row]
				}

				cell.delegate = self

				return cell

			case .activities:
				guard let cell = tableView.dequeueReusableCell(withIdentifier: "activity-cell", for: indexPath) as? ClientActivityCell else {
					return UITableViewCell()
				}

				cell.delegate = self

				if let activities = activities, indexPath.row < activities.count {
					cell.activity = activities[indexPath.row]
				}

				return cell

			default:
				return UITableViewCell()
		}
	}

	public override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
		return false
	}
	public override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {

		return nil
	}
}
