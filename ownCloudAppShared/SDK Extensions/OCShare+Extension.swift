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
				permissionsDescription.append(OCLocalizedString("Download / View", nil))
			}
			if self.canReadWrite {
				permissionsDescription.append(OCLocalizedString("Create", nil))
			}
			if self.canUpdate {
				permissionsDescription.append(OCLocalizedString("Upload", nil))
				permissionsDescription.append(OCLocalizedString("Edit", nil))
			}
			if self.canDelete {
				permissionsDescription.append(OCLocalizedString("Delete", nil))
			}
			if self.canCreate, self.canUpdate == false {
				permissionsDescription.append(OCLocalizedString("Upload (File Drop)", nil))
			}
			if self.expirationDate != nil {
				permissionsDescription.append(OCLocalizedString("Expiration date", nil))
			}
			if self.protectedByPassword {
				permissionsDescription.append(OCLocalizedString("Password", nil))
			}
		} else {
			if self.canRead {
				permissionsDescription.append(OCLocalizedString("Read", nil))
			}
			if self.canShare, capabilities?.sharingResharing == true, capabilities?.sharingAPIEnabled == true, capabilities?.sharingAllowed == true {
				permissionsDescription.append(OCLocalizedString("Share", nil))
			}
			if self.canCreate {
				permissionsDescription.append(OCLocalizedString("Create", nil))
			}
			if self.canUpdate {
				permissionsDescription.append(OCLocalizedString("Change", nil))
			}
			if self.canDelete {
				permissionsDescription.append(OCLocalizedString("Delete", nil))
			}
		}

		return permissionsDescription.joined(separator:", ")
	}

	func copyToClipboard() -> Bool {
		if let url {
			UIPasteboard.general.url = url
			return true
		}
		return false
	}
}
