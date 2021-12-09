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
		if let relevantReleaseNotes = ReleaseNotesDatasource().releaseNotes(for: VendorServices.shared.appVersion) {
			let section = StaticTableViewSection()

			for aDict in relevantReleaseNotes {
				if let notes = aDict["ReleaseNotes"] as? NSArray {
					for releaseNote in (notes as? [[String:String]])! {
						if let title = releaseNote["Title"], let subtitle = releaseNote["Subtitle"] {
							var image : UIImage?
							if #available(iOS 13.0, *), let imageSystemName = releaseNote["ImageSystemName"] {
								let homeSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 32, weight: .thin)
								image = UIImage(systemName: imageSystemName, withConfiguration: homeSymbolConfiguration)?.withRenderingMode(.alwaysTemplate)
							} else if let strBase64 = releaseNote["ImageData"] {
								let dataDecoded : Data = Data(base64Encoded: strBase64, options: .ignoreUnknownCharacters)!

								if let decodedimage = UIImage(data: dataDecoded)?.scaledImageFitting(in: CGSize(width: 50.0, height: 44.0))?.withRenderingMode(.alwaysTemplate) {
									image = decodedimage
								}
							}
							if let image = image {
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
