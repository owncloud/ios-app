//
//  ClientActivityViewController.swift
//  ownCloud
//
//  Created by Felix Schwarz on 26.01.19.
//  Copyright © 2019 ownCloud GmbH. All rights reserved.
//

import UIKit
import ownCloudSDK

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
	var isOnScreen : Bool = false

	deinit {
		Theme.shared.unregister(client: self)
		self.core = nil
	}

	@objc func handleActivityNotification(_ notification: Notification) {
		if let activitiyUpdates = notification.userInfo?[OCActivityManagerNotificationUserInfoUpdatesKey] as? [ [ String : Any ] ] {
			for activityUpdate in activitiyUpdates {
				if let updateTypeInt = activityUpdate[OCActivityManagerUpdateTypeKey] as? UInt, let updateType = OCActivityUpdateType(rawValue: updateTypeInt) {
					switch updateType {
						case .publish, .unpublish:
							setNeedsDataReload()

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

		self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "activity-cell")
		self.tableView.rowHeight = UITableView.automaticDimension
		self.tableView.estimatedRowHeight = 80
		self.tableView.allowsSelectionDuringEditing = true

		Theme.shared.register(client: self, applyImmediately: true)
	}

	func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		self.tableView.applyThemeCollection(collection)
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		self.navigationItem.title = "Activities".localized
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
		guard let cell = tableView.dequeueReusableCell(withIdentifier: "activity-cell", for: indexPath) as? UITableViewCell else {
			return UITableViewCell()
		}

		if let activities = activities, indexPath.row < activities.count {
			let activity = activities[indexPath.row]

			cell.textLabel?.text = activity.localizedDescription
			cell.detailTextLabel?.text = activity.localizedStatusMessage
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
