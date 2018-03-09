//
//  StaticTableViewSection.swift
//  ownCloud
//
//  Created by Felix Schwarz on 08.03.18.
//  Copyright © 2018 ownCloud. All rights reserved.
//

import UIKit

class StaticTableViewSection: NSObject {
	public var identifier : String?

	public var rows : Array<StaticTableViewRow> = Array()

	public var headerTitle : String?
	public var footerTitle : String?
	
	convenience init( headerTitle theHeaderTitle: String?, footerTitle theFooterTitle: String?, rows rowsToAdd: Array<StaticTableViewRow>) {
		self.init()
		
		self.add(rows: rowsToAdd)
		self.headerTitle = theHeaderTitle
		self.footerTitle = theFooterTitle
	}
	
	func add(rows rowsToAdd: Array<StaticTableViewRow>) {
		rows.append(contentsOf: rowsToAdd)
	}
}
