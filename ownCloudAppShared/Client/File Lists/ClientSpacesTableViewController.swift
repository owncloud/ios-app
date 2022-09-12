//
//  ClientSpacesTableViewController.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 03.03.22.
//  Copyright © 2022 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2022, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import UIKit
import ownCloudSDK

public class ClientSpacesTableViewController: StaticTableViewController {
	public weak var core : OCCore?
	public weak var rootViewController: UIViewController?

	public override func viewDidLoad() {
		super.viewDidLoad()

		addSection(driveRowsSection)

		updateFromDrives()
	}

	var driveListObserver : NSKeyValueObservation?
	var driveRowsSection : StaticTableViewSection

	public init(core inCore: OCCore, rootViewController inRootViewController: UIViewController) {
		driveRowsSection = StaticTableViewSection(headerTitle: nil, footerTitle: nil, identifier: "drive-rows", rows: [])

		super.init(style: .plain)

		core = inCore
		rootViewController = inRootViewController

		self.navigationItem.title = inCore.bookmark.shortName

		driveListObserver = core?.observe(\OCCore.drives, changeHandler: { [weak self] core, change in
			OnMainThread {
				self?.updateFromDrives()
			}
		})
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	func updateFromDrives() {
		if let drives = core?.drives {
			var driveRows : [StaticTableViewRow] = []

			let sortedDrives = drives.sorted { drive1, drive2 in
				let name1 = drive1.name ?? drive1.identifier
				let name2 = drive2.name ?? drive2.identifier

				return name1.caseInsensitiveCompare(name2) == .orderedAscending
			}

			for drive in sortedDrives {
				driveRows.append(StaticTableViewRow(rowWithAction: { [weak self] (staticRow, sender) in
					if let core = self?.core, let rootViewController = self?.rootViewController {
					   	let query = OCQuery(for: drive.rootLocation)
					   	let rootFolderViewController = ClientQueryViewController(core: core, drive: drive, query: query, rootViewController: rootViewController)

						self?.navigationController?.pushViewController(rootFolderViewController, animated: true)
					}
				}, title: drive.name ?? drive.identifier, subtitle: drive.type.rawValue, accessoryType: .disclosureIndicator))
			}

			removeSection(driveRowsSection)
			driveRowsSection.rows = driveRows
			addSection(driveRowsSection)
		}
	}
}
