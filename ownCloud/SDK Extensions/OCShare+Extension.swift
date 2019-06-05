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

	func permissionDescription(for capabilities: OCCapabilities?) -> String {
		var permissionsDescription : [String] = []

		if self.type == .link {
			if self.canRead {
				permissionsDescription.append("Download / View".localized)
			}
			if self.canReadWrite {
				permissionsDescription.append("Create".localized)
			}
			if self.canUpdate {
				permissionsDescription.append("Upload".localized)
				permissionsDescription.append("Edit".localized)
			}
			if self.canDelete {
				permissionsDescription.append("Delete".localized)
			}
			if self.canCreate, self.canUpdate == false {
				permissionsDescription.append("Upload (File Drop)".localized)
			}
			if self.expirationDate != nil {
				permissionsDescription.append("Expiration date".localized)
			}
			if self.protectedByPassword {
				permissionsDescription.append("Password".localized)
			}
		} else {
			if self.canRead {
				permissionsDescription.append("Read".localized)
			}
			if self.canShare, capabilities?.sharingResharing == true, capabilities?.sharingAPIEnabled == true, capabilities?.sharingAllowed == true {
				permissionsDescription.append("Share".localized)
			}
			if self.canCreate {
				permissionsDescription.append("Create".localized)
			}
			if self.canUpdate {
				permissionsDescription.append("Change".localized)
			}
			if self.canDelete {
				permissionsDescription.append("Delete".localized)
			}
		}

		return permissionsDescription.joined(separator:", ")
	}
}
