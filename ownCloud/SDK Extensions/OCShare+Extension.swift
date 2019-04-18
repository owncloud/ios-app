//
//  OCItem+Extension.swift
//  ownCloud
//
//  Created by Felix Schwarz on 13.04.18.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
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

extension OCShare {

	func permissionDescription() -> String {
		var permissionsDescription : [String] = []
		if self.canRead {
			permissionsDescription.append("Read")
		}
		if self.canShare {
			permissionsDescription.append("Share")
		}
		if self.canReadWrite {
			permissionsDescription.append("Create")
		}
		if self.canUpdate {
			permissionsDescription.append("Change")
			permissionsDescription.append("Edit")
		}
		if self.canDelete {
			permissionsDescription.append("Delete")
		}

		return permissionsDescription.joined(separator:", ")
	}
}
