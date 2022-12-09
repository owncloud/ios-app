//
//  AccountControllerSection.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 15.11.22.
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

public class AccountControllerSection: CollectionViewSection {
	open var accountController: AccountController

	public init(with accountController: AccountController) {
		self.accountController = accountController
		let uuid = accountController.connection?.bookmark.uuid.uuidString ?? "_missing_bookmark_"
		super.init(identifier: "account.\(uuid)", dataSource: accountController.accountSectionDataSource, cellStyle: CollectionViewCellStyle(with: .sideBar), cellLayout: .list(appearance: accountController.configuration.sectionAppearance), clientContext: accountController.clientContext)
		accountController.accountControllerSection = self
	}
}
