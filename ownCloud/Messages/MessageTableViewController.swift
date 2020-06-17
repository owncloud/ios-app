//
//  MessageTableViewController.swift
//  ownCloud
//
//  Created by Felix Schwarz on 26.05.20.
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
import ownCloudSDK

class MessageTableViewController: UITableViewController, Themeable {
	weak var core : OCCore? {
		willSet {
			messageSelector = nil
		}
	}

	var messageSelector : MessageSelector?
	var messages : [OCMessage]?

	var isOnScreen : Bool = false

	init(with core: OCCore, messageFilter: @escaping MessageSelectorFilter) {
		super.init(style: .plain)

		self.core = core

		messageSelector = MessageSelector(from: core.messageQueue, filter: messageFilter, handler: { [weak self] (_, _, _) in
			OnMainThread {
				self?.setNeedsDataReload()
			}
		})
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	deinit {
		Theme.shared.unregister(client: self)
		self.core = nil
	}

	var needsDataReload : Bool = true

	func setNeedsDataReload() {
		needsDataReload = true
		self.reloadDataIfOnScreen()
	}

	func reloadDataIfOnScreen() {
		if needsDataReload, isOnScreen {
			needsDataReload = false

			messages = messageSelector?.selection
			self.tableView.reloadData()
		}
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		self.tableView.register(MessageGroupCell.self, forCellReuseIdentifier: "message-group-cell")
		self.tableView.rowHeight = UITableView.automaticDimension
		self.tableView.estimatedRowHeight = 80
		self.tableView.separatorStyle = .none

		messages = messageSelector?.selection

		Theme.shared.register(client: self, applyImmediately: true)
	}

	func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		self.tableView.applyThemeCollection(collection)
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		self.navigationItem.title = "Messages".localized
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
		return messages?.count ?? 0
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		guard let cell = tableView.dequeueReusableCell(withIdentifier: "message-group-cell", for: indexPath) as? MessageGroupCell else {
			return UITableViewCell()
		}

		if let messages = messages, indexPath.row < messages.count {
			cell.noBottomSpacing = true
			cell.messageGroup = MessageGroup(with: messages[indexPath.row])
		}

		return cell
	}

	override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
		return false
	}

	override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
		return nil
	}

}
