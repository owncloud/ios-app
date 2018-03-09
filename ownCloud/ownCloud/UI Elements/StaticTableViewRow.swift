//
//  StaticTableViewRow.swift
//  ownCloud
//
//  Created by Felix Schwarz on 08.03.18.
//  Copyright © 2018 ownCloud. All rights reserved.
//

import UIKit

typealias StaticTableViewRowAction = (_ staticRow : StaticTableViewRow) -> Void

class StaticTableViewRow: NSObject {
	public weak var section : StaticTableViewSection?

	public var identifier : String?
	public var groupIdentifier : String?

	public var cell : UITableViewCell?
	
	public var action : StaticTableViewRowAction?

	convenience init(text: String, action: @escaping StaticTableViewRowAction) {
		self.init()
		
		self.cell = UITableViewCell.init(style: UITableViewCellStyle.default, reuseIdentifier: nil)
		self.cell?.textLabel?.text = text
		
		self.action = action
	}
}
