//
//  QueryFileListTableViewController
//  ownCloud
//
//  Created by Matthias Hühne on 13.05.19.
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
import ownCloudSDK

class CustomFileListTableViewController: QueryFileListTableViewController {

	// MARK: - Theme support
	override func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		super.applyThemeCollection(theme: theme, collection: collection, event: event)

		tableView.sectionIndexColor = collection.tintColor
	}

	override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
		if sortMethod == .alphabeticallyAscendant || sortMethod == .alphabeticallyDescendant {
			return Array( Set( self.items.map { String(( $0.name?.first!.uppercased())!) })).sorted()
		}

		return []
	}

	override open func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
		let firstItem = self.items.filter { (( $0.name?.uppercased().hasPrefix(title) ?? nil)! ) }.first

		if let firstItem = firstItem {
			if let itemIndex = self.items.index(of: firstItem) {
				OnMainThread {
					tableView.scrollToRow(at: IndexPath(row: itemIndex, section: 0), at: UITableView.ScrollPosition.top, animated: false)
				}
			}
		}

		return 0
	}

}
