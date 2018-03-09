//
//  GlobalSettingsViewController.swift
//  ownCloud
//
//  Created by Felix Schwarz on 08.03.18.
//  Copyright © 2018 ownCloud. All rights reserved.
//

import UIKit

class GlobalSettingsViewController: StaticTableViewController {
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.addSection(StaticTableViewSection.init(headerTitle: "Header", footerTitle: "Footer", rows: [
			StaticTableViewRow.init(text: "Add Section", action: { (row) in
				self.addSection(StaticTableViewSection.init(headerTitle: "Header 2", footerTitle: "Footer 2", rows: [
					StaticTableViewRow.init(text: "Line 1", action: { (row) in
						print ("Line 1 tapped")
					}),
					StaticTableViewRow.init(text: "Line 2", action: { (row) in
						print ("Line 2 tapped")
					})
				]), animated:true)
			}),
			StaticTableViewRow.init(text: "Remove Section", action: { (row) in
				if let removeSection = self.sections.last {
					self.removeSection(removeSection, animated:true)
				}
			})
		]), animated:false)

		// Uncomment the following line to preserve selection between presentations
		// self.clearsSelectionOnViewWillAppear = false
		
		// Uncomment the following line to display an Edit button in the navigation bar for this view controller.
		// self.navigationItem.rightBarButtonItem = self.editButtonItem
	}
}
