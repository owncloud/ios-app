//
//  StaticTableViewSection.swift
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

open class StaticTableViewSection: NSObject {
	public weak var viewController : StaticTableViewController?

	public var identifier : String?

	public var rows : [StaticTableViewRow] = []

	public var headerTitle : String?
	public var footerTitle : String?

	public var index : Int? {
		return self.viewController?.sections.index(of: self)
	}

	public var attached : Bool {
		return self.index != nil
	}

	convenience public init( headerTitle theHeaderTitle: String?, footerTitle theFooterTitle: String? = nil, identifier : String? = nil, rows rowsToAdd: [StaticTableViewRow] = Array()) {
		self.init()

		self.headerTitle = theHeaderTitle
		self.footerTitle = theFooterTitle

		self.identifier  = identifier

		self.add(rows: rowsToAdd)
	}

	// MARK: - Adding rows
	public func add(rows rowsToAdd: [StaticTableViewRow], animated: Bool = false) {
		var indexPaths : [IndexPath] = []
		let sectionIndex = self.index
		var rowIndex = rows.count

		for row in rowsToAdd {
			// Add reference to section to row
			if row.section == nil {
				row.eventHandler?(row, .initial)
			}

			row.section = self

			// Generate indexpaths
			if sectionIndex != nil {
				indexPaths.append(IndexPath(row: rowIndex, section: sectionIndex!))
			}

			rowIndex += 1
		}

		// Append to rows
		rows.append(contentsOf: rowsToAdd)

		// Update view controller
		if sectionIndex != nil, self.viewController?.needsLiveUpdates == true {
			self.viewController?.tableView.insertRows(at: indexPaths, with: animated ? .fade : .none)
		}
	}

	@discardableResult
	public func add(radioGroupWithArrayOfLabelValueDictionaries labelValueDictRows: [[String : Any]], radioAction:StaticTableViewRowAction?, groupIdentifier: String, selectedValue: Any, animated : Bool = false) -> [StaticTableViewRow] {

		var radioGroupRows : [StaticTableViewRow] = []

		for labelValueDict in labelValueDictRows {
			for (label, value) in labelValueDict {
				var selected = false

				if let selectedValueObject = selectedValue as? NSObject, let valueObject = value as? NSObject, (selectedValueObject == valueObject) { selected = true }

				radioGroupRows.append(StaticTableViewRow(radioItemWithAction: radioAction, groupIdentifier: groupIdentifier, value: value, title: label, subtitle: "", selected: selected))
			}
		}

		self.add(rows: radioGroupRows, animated: animated)

		return radioGroupRows
	}

	public func add(row rowToAdd: StaticTableViewRow, animated: Bool = false) {
		self.insert(row: rowToAdd, at: rows.count, animated: animated)
	}

	public func insert(row rowToAdd: StaticTableViewRow, at index: Int, animated: Bool = false) {
		// Add reference to section to row
		if rowToAdd.section == nil {
			rowToAdd.eventHandler?(rowToAdd, .initial)
		}

		rowToAdd.section = self

		// Insert in rows
		rows.insert(rowToAdd, at: index)

		// Update view controller
		if let sectionIndex = self.index, self.viewController?.needsLiveUpdates == true {
			self.viewController?.tableView.insertRows(at: [IndexPath(row: index, section: sectionIndex)], with: animated ? .fade : .none)
		}
	}

	// MARK: - Removing rows
	public func remove(rows rowsToRemove: [StaticTableViewRow], animated: Bool = false) {
		var indexPaths : [IndexPath] = []
		var indexes : IndexSet = IndexSet()
		let sectionIndex = self.index

		// Finds rows to remove
		for row in rowsToRemove {
			if let index = rows.index(of: row) {
				// Save indexes and index paths
				indexes.insert(index)
				if sectionIndex != nil {
					indexPaths.append(IndexPath(row: index, section: sectionIndex!))
				}
			}
		}

		// Remove from rows
		for row in indexes.reversed() {
			rows.remove(at: row)
		}

		// Update view controller
		if sectionIndex != nil, self.viewController?.needsLiveUpdates == true {
			self.viewController?.tableView.deleteRows(at: indexPaths, with: animated ? .fade : .none)
		}
	}

	public func remove(rowWithIdentifier identifier: String, animated : Bool = false) {
		if let row = row(withIdentifier: identifier) {
			self.remove(rows: [row], animated: animated)
		}
	}

	// MARK: - Update Section Titles
	public func updateHeader(title: String?) {
		self.headerTitle = title
		// with this way we are not loosing focus of selected text field
		UIView.setAnimationsEnabled(false)
		self.viewController?.tableView.beginUpdates()
		if let containerView = self.viewController?.tableView.headerView(forSection: self.index!) {
			containerView.textLabel!.text = self.headerTitle
			containerView.sizeToFit()
		}
		self.viewController?.tableView.endUpdates()
		UIView.setAnimationsEnabled(true)
	}

	public func updateFooter(title: String?) {
		self.footerTitle = title
		// with this way we are not loosing focus of selected text field
		UIView.setAnimationsEnabled(false)
		self.viewController?.tableView.beginUpdates()
		if let containerView = self.viewController?.tableView.footerView(forSection: self.index!) {
			containerView.textLabel!.text = self.footerTitle
			containerView.sizeToFit()
		}
		self.viewController?.tableView.endUpdates()
		UIView.setAnimationsEnabled(true)
	}

	// MARK: - Radio group value setter/getter
	public func selectedValue(forGroupIdentifier groupIdentifier: String) -> Any? {
		for row in rows {
			if row.groupIdentifier == groupIdentifier {
				if row.cell?.accessoryType == UITableViewCell.AccessoryType.checkmark {
					return (row.value)
				}
			}
		}

		return nil
	}

	public func setSelected(_ value: Any, groupIdentifier: String) {
		for row in rows {
			if row.groupIdentifier == groupIdentifier {
				if let rowValueObject = row.value as? NSObject, let valueObject = value as? NSObject, rowValueObject == valueObject {
					row.cell?.accessoryType = UITableViewCell.AccessoryType.checkmark
				} else {
					row.cell?.accessoryType = UITableViewCell.AccessoryType.none
				}
			}
		}
	}

	// MARK: - Finding rows
	public func row(withIdentifier: String) -> StaticTableViewRow? {
		for row in rows {
			if row.identifier == withIdentifier {
				return row
			}
		}

		return nil
	}
}
