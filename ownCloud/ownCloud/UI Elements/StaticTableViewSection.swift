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

class StaticTableViewSection: NSObject {
	public weak var viewController : StaticTableViewController?

	public var identifier : String?

	public var rows : [StaticTableViewRow] = Array()

	public var headerTitle : String?
	public var footerTitle : String?
	
	convenience init( headerTitle theHeaderTitle: String?, footerTitle theFooterTitle: String?, identifier : String? = nil, rows rowsToAdd: Array<StaticTableViewRow> = Array()) {
		self.init()
		
		self.headerTitle = theHeaderTitle
		self.footerTitle = theFooterTitle

		self.identifier  = identifier

		self.add(rows: rowsToAdd)
	}
	
	// MARK: - Adding rows
	func add(rows rowsToAdd: Array<StaticTableViewRow>) {
		// Add reference to section to row
		for row in rowsToAdd {
			if (row.section == nil)
			{
				row.eventHandler?(row, StaticTableViewEvent.Initial)
			}

			row.section = self
		}

		// Append to rows
		rows.append(contentsOf: rowsToAdd)
	}

	@discardableResult
	func add(radioGroupWithArrayOfLabelValueDictionaries labelValueDictRows: Array<Dictionary<String, Any>>, radioAction:StaticTableViewRowAction?, groupIdentifier: String, selectedValue: Any) -> Array<StaticTableViewRow> {
		var radioGroupRows : Array<StaticTableViewRow> = Array()

		for labelValueDict in labelValueDictRows {
			for (label, value) in labelValueDict {
				var selected = false

				if let selectedValueObject = selectedValue as? NSObject, let valueObject = value as? NSObject, (selectedValueObject == valueObject) { selected = true }

				radioGroupRows.append(StaticTableViewRow.init(radioItemWithAction: radioAction, groupIdentifier: groupIdentifier, value: value, title: label, selected: selected))
			}
		}

		self.add(rows: radioGroupRows)

		return radioGroupRows
	}

	// MARK: - Radio group value setter/getter
	func selectedValue(forGroupIdentifier groupIdentifier: String) -> Any? {
		for row in rows {
			if (row.groupIdentifier == groupIdentifier) {
				if (row.cell?.accessoryType == UITableViewCellAccessoryType.checkmark) {
					return (row.value)
				}
			}
		}

		return nil
	}

	func setSelected(_ value: Any, groupIdentifier: String) {
		for row in rows {
			if (row.groupIdentifier == groupIdentifier) {
				if let rowValueObject = row.value as? NSObject, let valueObject = value as? NSObject, rowValueObject == valueObject {
					row.cell?.accessoryType = UITableViewCellAccessoryType.checkmark
				} else {
					row.cell?.accessoryType = UITableViewCellAccessoryType.none
				}
			}
		}
	}

	// MARK: - Finding rows
	func row(withIdentifier: String) -> StaticTableViewRow? {
		for row in rows {
			if row.identifier == withIdentifier {
				return row
			}
		}

		return nil
	}
}
