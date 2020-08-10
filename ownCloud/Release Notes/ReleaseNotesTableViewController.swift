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
		prepareReleaseNotes()
    }

	func prepareReleaseNotes() {
		if let relevantReleaseNotes = ReleaseNotesDatasource().releaseNotes(for: VendorServices.shared.appVersion), let imageData = ReleaseNotesDatasource().releaseNotes(for: VendorServices.shared.appVersion) {
			let section = StaticTableViewSection()

			for aDict in relevantReleaseNotes {
				if let notes = aDict["ReleaseNotes"] as? NSArray {
					for releaseNote in (notes as? [[String:String]])! {
						if let title = releaseNote["Title"], let subtitle = releaseNote["Subtitle"] {
							var image : UIImage?

							if let imageName = releaseNote["ImageName"], let image = ReleaseNotesDatasource().image(for: imageName) {
								let row = StaticTableViewRow(rowWithAction: { (_, _) in
									self.dismissAnimated()
								}, title: title, subtitle: subtitle, image: image, imageWidth:50.0, alignment: .left, accessoryType: .none)
								section.add(row: row)
							} else {
								let row = StaticTableViewRow(rowWithAction: { (_, _) in
									self.dismissAnimated()
								}, title: title, subtitle: subtitle, alignment: .left, accessoryType: .none)
								section.add(row: row)
							}
						}
					}
				}
			}
			self.addSection(section)
		}
	}

}
