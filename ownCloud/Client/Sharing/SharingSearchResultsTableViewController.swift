//
//  SharingSearchResultsTableViewController.swift
//  ownCloud
//
//  Created by Matthias Hühne on 11.04.19.
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

class SharingSearchResultsTableViewController: StaticTableViewController, UISearchResultsUpdating {

    override func viewDidLoad() {
        super.viewDidLoad()
    }

	// MARK: - UISearchResultsUpdating Delegate
	func updateSearchResults(for searchController: UISearchController) {
	}
}
