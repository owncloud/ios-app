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
	var headerLabel = UILabel()

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
		headerLabel.applyThemeCollection(collection, itemStyle: .welcomeMessage)
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

	override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		let rootView = UIView()

		let backgroundImageView = UIImageView()
		backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
		rootView.addSubview(backgroundImageView)

		let headerLogoView = UIImageView()
		headerLogoView.translatesAutoresizingMaskIntoConstraints = false
		rootView.addSubview(headerLogoView)

		headerLabel.translatesAutoresizingMaskIntoConstraints = false
		rootView.addSubview(headerLabel)

		NSLayoutConstraint.activate([
			// Background image view
			backgroundImageView.topAnchor.constraint(equalTo: rootView.topAnchor),
			backgroundImageView.bottomAnchor.constraint(equalTo: rootView.bottomAnchor),
			backgroundImageView.leftAnchor.constraint(equalTo: rootView.leftAnchor),
			backgroundImageView.rightAnchor.constraint(equalTo: rootView.rightAnchor),

			// Logo size
			headerLogoView.leftAnchor.constraint(equalTo: rootView.leftAnchor),
			headerLogoView.rightAnchor.constraint(equalTo: rootView.rightAnchor),
			headerLogoView.heightAnchor.constraint(equalTo: rootView.heightAnchor, multiplier: 0.5, constant: 0),
			headerLogoView.topAnchor.constraint(equalTo: rootView.topAnchor, constant: 15),

			// Header Label
			headerLabel.leftAnchor.constraint(equalTo: rootView.leftAnchor, constant: 15),
			headerLabel.rightAnchor.constraint(equalTo: rootView.rightAnchor, constant: -15),
			headerLabel.topAnchor.constraint(equalTo: headerLogoView.bottomAnchor, constant: 10),
			headerLabel.bottomAnchor.constraint(equalTo: rootView.bottomAnchor, constant: -15)
		])

		if let organizationLogoImage = UIImage(named: "branding-splashscreen") {
			headerLogoView.image = organizationLogoImage
			headerLogoView.contentMode = .scaleAspectFit
		}

		if let organizationBackgroundImage = UIImage(named: "branding-splashscreen-background") {
			backgroundImageView.image = organizationBackgroundImage
		}

		headerLabel.text = "The app was upgraded to a new version. Below there is an overview of all migrated accounts.".localized
		headerLabel.textAlignment = .center
		headerLabel.numberOfLines = 0

		return rootView
	}

	open override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		return self.view.frame.height * 0.35
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
