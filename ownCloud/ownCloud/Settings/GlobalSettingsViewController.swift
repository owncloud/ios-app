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

		// Add dynamic sections demo section
		var section : StaticTableViewSection = StaticTableViewSection.init(headerTitle: "Dynamic sections demo", footerTitle: "Tap the items above to add a section - or remove the last section", rows: [
			// .. with two rows
			StaticTableViewRow.init(text: "Add Section", action: { (row, sender) in
				let sectionCount = row.viewController!.sections.count

				row.viewController?.addSection(StaticTableViewSection.init(headerTitle: "Section \(sectionCount)", footerTitle: "Footer of section \(sectionCount)", rows: [
					StaticTableViewRow.init(text: "Line 1", action: { (row, sender) in
						print ("Line 1 tapped in \(row.section!.headerTitle!)")
					}),
					StaticTableViewRow.init(text: "Line 2", action: { (row, sender) in
						print ("Line 2 tapped in \(row.section!.headerTitle!)")
					}),
					StaticTableViewRow.init(text: "Remove section", action: { (row, sender) in
						row.viewController?.removeSection(row.section!, animated: true)
					})
				]), animated:true)
			}),
			StaticTableViewRow.init(text: "Remove Section", action: { (row, sender) in
				if let removeSection = row.viewController?.sections.last {
					row.viewController?.removeSection(removeSection, animated:true)
				}
			})
		]);

		self.addSection(section)

		// Add a radio group section
		section = StaticTableViewSection.init(headerTitle: "Radio group", footerTitle: nil)

		section.add(radioGroupWithArrayOfLabelValueDictionaries: [
				["Line 1" : "value-of-line-1"],
				["Line 2" : "value-of-line-2"],
				["Line 3" : "value-of-line-3"]
			    ], radioAction: { (row, sender) in
				let selectedValueFromSection = row.section?.selectedValue(forGroupIdentifier: "radioExample")

				Log.log("Radio value for \(row.groupIdentifier!) changed to \(row.value!)")
				Log.log("Values can also be read from the section object: \(selectedValueFromSection!)")
			    }, groupIdentifier: "radioExample", selectedValue: "value-of-line-2")

		self.addSection(section)

		// Uncomment the following line to preserve selection between presentations
		// self.clearsSelectionOnViewWillAppear = false
		
		// Uncomment the following line to display an Edit button in the navigation bar for this view controller.
		// self.navigationItem.rightBarButtonItem = self.editButtonItem
	}
}
