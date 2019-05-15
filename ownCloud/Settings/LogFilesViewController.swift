//
//  LogFilesViewController.swift
//  ownCloud
//
//  Created by Michael Neuwert on 15.05.2019.
//  Copyright © 2019 ownCloud GmbH. All rights reserved.
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

class LogFileTableViewCell : UITableViewCell {

	static let identifier = "LogFileTableViewCell"

	override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
		super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}

class LogFilesViewController : UITableViewController, Themeable {

	var logFiles: [String]?

	lazy var byteCounterFormatter = ByteCountFormatter()

	override func viewDidLoad() {
		super.viewDidLoad()
		Theme.shared.register(client: self, applyImmediately: true)
		self.tableView.register(LogFileTableViewCell.self, forCellReuseIdentifier: LogFileTableViewCell.identifier)
		self.title = "Log Files".localized
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		self.populateLogFileList()
	}

	deinit {
		Theme.shared.unregister(client: self)
	}

	// MARK: - Theme support

	func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		self.tableView.applyThemeCollection(collection)

		if event == .update {
			self.tableView.reloadData()
		}
	}

	// MARK: - Table view data source / delegate

	override func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}

	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return logFiles != nil ? logFiles!.count : 0
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: LogFileTableViewCell.identifier, for: indexPath) as? LogFileTableViewCell
		cell?.textLabel?.text = self.logFiles![indexPath.row]
		
		return cell!
	}

	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
	}

	// MARK: - Private Helpers

	private func populateLogFileList() {
		guard let logFileWriter = OCLogger.shared.writer(withIdentifier: .writerFile) as? OCLogFileWriter else { return }

		guard let logFiles = logFileWriter.logFiles() else { return }

		self.logFiles = logFiles as? [String]

		self.tableView.reloadData()
	}
}
