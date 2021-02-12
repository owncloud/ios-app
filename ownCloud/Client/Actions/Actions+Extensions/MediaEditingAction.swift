//
//  MediaEditingAction.swift
//  ownCloud
//
//  Created by Matthias Hühne on 23/01/2020.
//  Copyright © 2020 ownCloud GmbH. All rights reserved.
//

/*
* Copyright (C) 2020, ownCloud GmbH.
*
* This code is covered by the GNU Public License Version 3.
*
* For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
* You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
*
*/

import ownCloudSDK
import ownCloudAppShared

@available(iOS 13.0, *)
class MediaEditingAction : DocumentEditingAction {
	override class var identifier : OCExtensionIdentifier? { return OCExtensionIdentifier("com.owncloud.action.mediaediting") }
	override class var name : String? { return "Crop or Rotate".localized }
	override class var supportedMimeTypes : [String] { return ["video"] }

	override class func iconForLocation(_ location: OCExtensionLocationIdentifier) -> UIImage? {
		if location == .moreItem || location == .moreDetailItem || location == .moreFolder {
			return UIImage(systemName: "crop.rotate")?.withRenderingMode(.alwaysTemplate)
		}

		return nil
	}
}
