//
//  MigrationViewController.swift
//  ownCloud
//
//  Created by Michael Neuwert on 31.03.20.
//  Copyright © 2020 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2020, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import UIKit
import ownCloudAppShared

class MigrationViewController: UITableViewController, Themeable {

	var activities = [MigrationActivity]()

	var migrationFinishedHandler: (() -> Void)?

	var doneBarButtonItem: UIBarButtonItem?

	deinit {
		NotificationCenter.default.removeObserver(self, name: Migration.ActivityUpdateNotification, object: nil)
		NotificationCenter.default.removeObserver(self, name: Migration.FinishedNotification, object: nil)
		Theme.shared.unregister(client: self)
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		self.title = "Account Migration".localized

		self.tableView.register(MigrationActivityCell.self, forCellReuseIdentifier: MigrationActivityCell.identifier)
		self.tableView.rowHeight = UITableView.automaticDimension
		self.tableView.estimatedRowHeight = 80.0
		self.tableView.allowsSelection = false

		doneBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.done, target: self, action: #selector(finishMigration))
		self.navigationItem.rightBarButtonItem = doneBarButtonItem
		doneBarButtonItem?.isEnabled = false

		Theme.shared.register(client: self, applyImmediately: true)

		NotificationCenter.default.addObserver(self, selector: #selector(handleActivityNotification), name: Migration.ActivityUpdateNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(handleMigrationFinishedNotification), name: Migration.FinishedNotification, object: nil)
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		Migration.shared.migrateAccountsAndSettings(self)
	}

	func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		self.tableView.applyThemeCollection(collection)
		self.tableView.separatorColor = self.tableView.backgroundColor
	}

	// MARK: - User Actions

	@IBAction func finishMigration() {
		self.migrationFinishedHandler?()
		self.dismiss(animated: true)
	}

	// MARK: - Table view data source

	override func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}

	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return activities.count
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		guard let cell = tableView.dequeueReusableCell(withIdentifier: MigrationActivityCell.identifier, for: indexPath) as? MigrationActivityCell else {
			return UITableViewCell()
		}

		if indexPath.row < activities.count {
			cell.activity = self.activities[indexPath.row]
		}

		return cell
	}

	@objc func handleActivityNotification(_ notification: Notification) {
		if let updatedActivity = notification.object as? MigrationActivity {

			let index = self.activities.firstIndex { (activity) -> Bool in
				if activity.title == updatedActivity.title {
					return true
				}
				return false
			}

			if index != nil {
				self.activities[index!] = updatedActivity
				self.tableView.reloadRows(at: [IndexPath(row: index!, section: 0)], with: .automatic)
			} else {
				self.activities.append(updatedActivity)
				self.tableView.insertRows(at: [IndexPath(row: self.activities.count - 1, section: 0)], with: .automatic)
			}
		}
	}

	@objc func handleMigrationFinishedNotification(_ notification: Notification) {
		self.doneBarButtonItem?.isEnabled = true
	}
}
