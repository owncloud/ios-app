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
import ownCloudAppShared

class DisplaySleepPreventer : NSObject {
	static var shared : DisplaySleepPreventer = DisplaySleepPreventer()

	var preventCount : Int = 0

	func startPreventingDisplaySleep() {
		if preventCount == 0 {
			UIApplication.shared.isIdleTimerDisabled = true
		}

		preventCount += 1
	}

	func stopPreventingDisplaySleep() {
		if preventCount > 0 {
			preventCount -= 1

			if preventCount == 0 {
				UIApplication.shared.isIdleTimerDisabled = false
			}
		}
	}
}

class ClientActivityViewController: UITableViewController, Themeable {

	weak var core : OCCore? {
		willSet {
			if let core = core {
				NotificationCenter.default.removeObserver(self, name: core.activityManager.activityUpdateNotificationName, object: nil)
			}
		}

		didSet {
			if let core = core {
				NotificationCenter.default.addObserver(self, selector: #selector(handleActivityNotification(_:)), name: core.activityManager.activityUpdateNotificationName, object: nil)
			}
		}
	}

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
								self.tableView.reloadRows(at: [IndexPath(row: firstIndex, section: 0)], with: .none)
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
		self.tableView.rowHeight = UITableView.automaticDimension
		self.tableView.estimatedRowHeight = 80
		self.tableView.allowsSelection = false

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
		return 1
	}

	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		// #warning Incomplete implementation, return the number of rows
		return activities?.count ?? 0
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		guard let cell = tableView.dequeueReusableCell(withIdentifier: "activity-cell", for: indexPath) as? ClientActivityCell else {
			return UITableViewCell()
		}

		if let activities = activities, indexPath.row < activities.count {
			cell.activity = activities[indexPath.row]
		}

		return cell
	}

	/*
	// Override to support conditional editing of the table view.
	override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
	// Return false if you do not want the specified item to be editable.
	return true
	}
	*/

	/*
	// Override to support editing the table view.
	override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
	if editingStyle == .delete {
	// Delete the row from the data source
	tableView.deleteRows(at: [indexPath], with: .fade)
	} else if editingStyle == .insert {
	// Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
	}
	}
	*/

	/*
	// Override to support rearranging the table view.
	override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

	}
	*/

	/*
	// Override to support conditional rearranging of the table view.
	override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
	// Return false if you do not want the item to be re-orderable.
	return true
	}
	*/

	/*
	// MARK: - Navigation

	// In a storyboard-based application, you will often want to do a little preparation before navigation
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
	// Get the new view controller using segue.destination.
	// Pass the selected object to the new view controller.
	}
	*/

}
