//
//  StaticTableViewRow.swift
//  ownCloud
//
//  Created by Felix Schwarz on 08.03.18.
//  Copyright © 2018 ownCloud. All rights reserved.
//

import UIKit

typealias StaticTableViewRowAction = (_ staticRow : StaticTableViewRow, _ sender: Any?) -> Void
typealias StaticTableViewRowEventHandler = (_ staticRow : StaticTableViewRow, _ event : StaticTableViewEvent) -> Void

class StaticTableViewRow: NSObject {
	public weak var section : StaticTableViewSection?

	public var identifier : String?
	public var groupIdentifier : String?

	public var value : Any?

	public var cell : UITableViewCell?

	public var selectable : Bool = true
	
	public var action : StaticTableViewRowAction?
	public var eventHandler : StaticTableViewRowEventHandler?

	public var viewController: StaticTableViewController? {
		return (section?.viewController)
	}

	convenience init(text: String, action: @escaping StaticTableViewRowAction) {
		self.init()
		
		self.cell = UITableViewCell.init(style: UITableViewCellStyle.default, reuseIdentifier: nil)
		self.cell?.textLabel?.text = text
		
		self.action = action
	}

	convenience init(radioAction: StaticTableViewRowAction?, groupIdentifier: String, value: Any, title: String, selected: Bool) {
		self.init()

		self.cell = UITableViewCell.init(style: UITableViewCellStyle.default, reuseIdentifier: nil)
		self.cell?.textLabel?.text = title

		self.groupIdentifier = groupIdentifier
		self.value = value

		if (selected) {
			self.cell?.accessoryType = UITableViewCellAccessoryType.checkmark
		}

		self.action = { (row, sender) in
			row.section?.setSelected(row.value!, groupIdentifier: row.groupIdentifier!)
			radioAction?(row, sender)
		}
	}
}
