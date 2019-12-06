//
//  ReleaseNotesTableViewController.swift
//  ownCloud
//
//  Created by Matthias Hühne on 09.10.19.
//  Copyright © 2019 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2019, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import UIKit

class ReleaseNotesTableViewController: StaticTableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

		tableView.separatorColor = .clear
		let section = StaticTableViewSection()

  		if let path = Bundle.main.path(forResource: "ReleaseNotes", ofType: "plist") {
 			if let releaseNotesValues = NSDictionary(contentsOfFile: path), let versionsValues = releaseNotesValues["Versions"] as? NSArray {

				let relevantReleaseNotes = versionsValues.filter {
					if let version = ($0 as AnyObject)["Version"] as? String, version.compare(VendorServices.shared.appVersion, options: .numeric) == .orderedDescending {
						print("store version is newer")
						return false
					}

					return true
				}

				for aDict in (relevantReleaseNotes as? [[String:Any]])! {
					if let notes = aDict["ReleaseNotes"] as? NSArray {
						for releaseNote in (notes as? [[String:String]])! {
							if let iconName = releaseNote["Icon"], let title = releaseNote["Title"], let subtitle = releaseNote["Subtitle"] {
							let row = StaticTableViewRow(rowWithAction: { (_, _) in
								self.dismissAnimated()
							}, title: title, subtitle: subtitle, image: UIImage(named: iconName), imageWidth: 50, alignment: .left, accessoryType: .none)
							section.add(row: row)
							}
						}
					}
				}
					}
		}

		self.addSection(section)
    }

}
