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

@available(iOS 13.0, *)
class MediaEditingAction : MarkupAction {
	override class var identifier : OCExtensionIdentifier? { return OCExtensionIdentifier("com.owncloud.action.mediaediting") }
	override class var name : String? { return "Crop or Rotate".localized }

	// MARK: - Extension matching
	override class func applicablePosition(forContext: ActionContext) -> ActionPosition {
		let supportedMimeTypes = ["video"]
		if forContext.items.contains(where: {$0.type == .collection}) {
			return .none
		} else if forContext.items.count > 1 {
			return .none
		} else if let item = forContext.items.first {
			if let mimeType = item.mimeType {
				if supportedMimeTypes.filter({
					return mimeType.contains($0)
				}).count == 0 {
					return .none
				}
			} else {
				return .none
			}
		}
		// Examine items in context
		return .middle
	}

	override class func iconForLocation(_ location: OCExtensionLocationIdentifier) -> UIImage? {
		if location == .moreItem || location == .moreFolder {
			if #available(iOS 13.0, *) {
				return UIImage(systemName: "crop.rotate")?.tinted(with: Theme.shared.activeCollection.tintColor)
			} else {
				return UIImage(named: "folder")
			}
		}

		return nil
	}
}
