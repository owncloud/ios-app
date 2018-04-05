//
//  GlobalSettingsViewController.swift
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

class GlobalSettingsViewController: StaticTableViewController {

	override func viewDidLoad() {
		super.viewDidLoad()

		self.navigationItem.title = "Settings"

		// Add dynamic sections demo section
		var section : StaticTableViewSection = StaticTableViewSection(headerTitle: "Dynamic sections demo", footerTitle: "Tap the items above to add a section - or remove the last section", rows: [
			// .. with two rows
			StaticTableViewRow(rowWithAction: { (row, _) in
				let sectionCount = row.viewController!.sections.count

				row.viewController?.insertSection(StaticTableViewSection(headerTitle: "Section \(sectionCount)", footerTitle: "Footer of section \(sectionCount)", rows: [
					StaticTableViewRow(rowWithAction: { (row, _) in
						print ("Line 1 tapped in \(row.section!.headerTitle!)")
					}, title: "Line 1"),
					StaticTableViewRow(rowWithAction: { (row, _) in
						print ("Line 2 tapped in \(row.section!.headerTitle!)")
					}, title: "Line 2"),
					StaticTableViewRow(rowWithAction: { (row, _) in
						row.viewController?.removeSection(row.section!, animated: true)
					}, title: "Remove section")
				]), at: 1, animated:true)
			}, title:"Insert Section"),

			StaticTableViewRow(rowWithAction: { (row, _) in
				if let removeSection = row.viewController?.sections.last {
					row.viewController?.removeSection(removeSection, animated:true)
				}
			}, title:"Remove Last Section")
		])

		self.addSection(section)

		// Add a radio group section
		section = StaticTableViewSection(headerTitle: "Radio group", footerTitle: nil)

		section.add(radioGroupWithArrayOfLabelValueDictionaries: [
				["Line 1" : "value-of-line-1"],
				["Line 2" : "value-of-line-2"],
				["Line 3" : "value-of-line-3"]
			    ], radioAction: { (row, _) in
				let selectedValueFromSection = row.section?.selectedValue(forGroupIdentifier: "radioExample")

				Log.log("Radio value for \(row.groupIdentifier!) changed to \(row.value!)")
				Log.log("Values can also be read from the section object: \(selectedValueFromSection!)")
			    }, groupIdentifier: "radioExample", selectedValue: "value-of-line-2")

		self.addSection(section)

		// Add text field section
		section = StaticTableViewSection(headerTitle: "Text fields", footerTitle: nil)
		section.add(rows: [
			StaticTableViewRow(textFieldWithAction: { (row, _) in
				Log.log("New content: \(row.value!)")
			}, placeholder: "Text Field", keyboardType: UIKeyboardType.emailAddress, identifier: "plainText"),

			StaticTableViewRow(secureTextFieldWithAction: { (row, _) in
				Log.log("New content: \(row.value!)")
			}, placeholder: "Secure Text Field", identifier: "secureText"),

			StaticTableViewRow(buttonWithAction: { (row, _) in
				row.section?.row(withIdentifier: "plainText")?.value = "Plain"
				row.section?.row(withIdentifier: "secureText")?.value = "Secret"
			}, title: "Set values", style: StaticTableViewRowButtonStyle.plain),

			StaticTableViewRow(buttonWithAction: { (row, _) in
				row.section?.row(withIdentifier: "plainText")?.textField?.becomeFirstResponder()
			}, title: "Edit Text Field", style: StaticTableViewRowButtonStyle.plain)
		])

		self.addSection(section)

		// Add switch section
		section = StaticTableViewSection(headerTitle: "Switches", footerTitle: nil)
		section.add(rows: [
			StaticTableViewRow(switchWithAction: { (row, _) in
				Log.log("Switch 1 value: \(row.value!)")
			}, title: "Switch 1", value: true, identifier: "switch1"),

			StaticTableViewRow(switchWithAction: { (row, _) in
				Log.log("Switch 2 value: \(row.value!)")
			}, title: "Switch 2", value: false, identifier: "switch2"),

			StaticTableViewRow(buttonWithAction: { (row, _) in

                if let switch1 = row.section?.row(withIdentifier: "switch1")?.value as? Bool,
                let switch2 = row.section?.row(withIdentifier: "switch2")?.value as? Bool {
                    row.section?.row(withIdentifier: "switch1")?.value = switch1
                    row.section?.row(withIdentifier: "switch2")?.value = switch2
                }
			}, title: "Toggle values", style: StaticTableViewRowButtonStyle.plain)
		])

		self.addSection(section)

		// Add buttons section
		section = StaticTableViewSection(headerTitle: "Buttons", footerTitle: nil)
		section.add(rows: [

			StaticTableViewRow(buttonWithAction: { (_, _) in
				Log.log("Proceed pressed")
			}, title: "Proceed", style: StaticTableViewRowButtonStyle.proceed),

			StaticTableViewRow(buttonWithAction: { (_, _) in
				Log.log("Destructive pressed")
			}, title: "Destructive", style: StaticTableViewRowButtonStyle.destructive),

			StaticTableViewRow(buttonWithAction: { (_, _) in
				Log.log("Custom pressed")
			}, title: "Custom", style:
                StaticTableViewRowButtonStyle.custom(textColor: UIColor.magenta,
                                                     selectedTextColor: UIColor.cyan,
                                                     backgroundColor: UIColor.green,
                                                     selectedBackgroundColor: UIColor.blue))
		])

		self.addSection(section)
	}
}
