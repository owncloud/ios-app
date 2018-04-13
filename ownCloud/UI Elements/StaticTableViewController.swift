//
//  StaticTableViewController.swift
//  ownCloud
//
//  Created by Felix Schwarz on 08.03.18.
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

enum StaticTableViewEvent {
	case initial
	case appBecameActive
	case tableViewWillAppear
	case tableViewWillDisappear
	case tableViewDidDisappear
}

class StaticTableViewController: UITableViewController, Themeable {
	public var sections : [StaticTableViewSection] = Array()

	// MARK: - Section administration
	func addSection(_ section: StaticTableViewSection, animated animateThis: Bool = false) {
		self.insertSection(section, at: sections.count, animated: animateThis)
	}

	func insertSection(_ section: StaticTableViewSection, at index: Int, animated: Bool = false) {
		section.viewController = self

		if animated {
			tableView.performBatchUpdates({
				sections.insert(section, at: index)
				tableView.insertSections(IndexSet(integer: index), with: UITableViewRowAnimation.fade)
			}, completion: { (_) in

			})
		} else {
			sections.insert(section, at: index)

			tableView.reloadData()
		}
	}

	func removeSection(_ section: StaticTableViewSection, animated: Bool = false) {
		if animated {
			tableView.performBatchUpdates({
				if let index : Int = sections.index(of: section) {
					sections.remove(at: index)
					tableView.deleteSections(IndexSet(integer: index), with: UITableViewRowAnimation.fade)
				}
			}, completion: { (_) in
				section.viewController = nil
			})
		} else {
			sections.remove(at: sections.index(of: section)!)

			section.viewController = nil

			tableView.reloadData()
		}
	}

	// MARK: - Search
	func sectionForIdentifier(_ sectionID: String) -> StaticTableViewSection? {
		for section in sections {
			if section.identifier == sectionID {
				return section
			}
		}

		return nil
	}

	func rowInSection(_ inSection: StaticTableViewSection?, rowIdentifier: String) -> StaticTableViewRow? {
		if inSection == nil {
			for section in sections {
				if let row = section.row(withIdentifier: rowIdentifier) {
					return row
				}
			}
		} else {
			return inSection?.row(withIdentifier: rowIdentifier)
		}

		return nil
	}

	// MARK: - View Controller
	override func viewDidLoad() {
		super.viewDidLoad()

		Theme.shared.register(client: self)
	}

	deinit {
		Theme.shared.unregister(client: self)
	}

	// MARK: - Tools
	func staticRowForIndexPath(_ indexPath: IndexPath) -> StaticTableViewRow {
		return (sections[indexPath.section].rows[indexPath.row])
	}

	// MARK: - Table view data source
	override func numberOfSections(in tableView: UITableView) -> Int {
		// #warning Incomplete implementation, return the number of sections
		return sections.count
	}

	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		// #warning Incomplete implementation, return the number of rows
		return sections[section].rows.count
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		return sections[indexPath.section].rows[indexPath.row].cell!
	}

	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

		let staticRow : StaticTableViewRow = staticRowForIndexPath(indexPath)

		if let action = staticRow.action {
			action(staticRow, self)
		}

		tableView.deselectRow(at: indexPath, animated: true)
	}

	override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		return sections[section].headerTitle
	}

	override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
		return sections[section].footerTitle
	}

	// MARK: Theme support
	func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		self.tableView.backgroundColor = collection.tableGroupBackgroundColor
		self.tableView.separatorColor = collection.tableRowSeparatorColor
	}
}
