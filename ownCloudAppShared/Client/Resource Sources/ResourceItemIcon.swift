//
//  ResourceItemIcon.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 21.01.22.
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

public class ResourceItemIcon: OCResource, OCViewProvider {
	public var iconName : String?

	public static let folder : ResourceItemIcon = ResourceItemIcon(iconName: "folder")
	public static let file : ResourceItemIcon = ResourceItemIcon(iconName: "file")

	public static func iconFor(mimeType: String) -> ResourceItemIcon {
		return ResourceItemIcon(iconName: OCItem.iconName(for: mimeType) ?? "file")
	}

	public convenience init(iconName: String, identifier: String? = nil) {

		self.init()

		self.type = .itemThumbnail
		self.identifier = identifier ?? "icon:\(iconName)"

		self.iconName = iconName
	}

	public func provideView(for size: CGSize, in context: OCViewProviderContext?, completion completionHandler: @escaping (UIView?) -> Void) {
		if let iconName = iconName, let vectorImage = Theme.shared.tvgImage(for: iconName) {
			OnMainThread {
				let vectorView = VectorImageView()

				vectorView.translatesAutoresizingMaskIntoConstraints = false
				vectorView.vectorImage = vectorImage

				completionHandler(vectorView)
			}
		} else {
			completionHandler(nil)
		}
	}
}
