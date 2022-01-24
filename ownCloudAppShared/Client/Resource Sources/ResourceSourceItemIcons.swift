//
//  ResourceSourceItemIcons.swift
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

public class ResourceSourceItemIcons: OCResourceSource {
	static public let identifier : OCResourceSourceIdentifier = OCResourceSourceIdentifier(rawValue: "app.item-icons")

	public override var identifier: OCResourceSourceIdentifier {
		return ResourceSourceItemIcons.identifier
	}

	public override var type: OCResourceType {
		return .itemThumbnail
	}

	public override func priority(forType type: OCResourceType) -> OCResourceSourcePriority {
		return .instant
	}

	public override func quality(for request: OCResourceRequest) -> OCResourceQuality {
		return .fallback
	}

	public override func provideResource(for request: OCResourceRequest, resultHandler: @escaping OCResourceSourceResultHandler) {
		if let thumbnailRequest = request as? OCResourceRequestItemThumbnail,
		   let iconName = thumbnailRequest.item.iconName {
			let resource = ResourceItemIcon(request: request)

			resource.iconName = iconName
			resource.mimeType = OCResourceMIMEType(rawValue: "image/tvg")
			resource.quality = .fallback

			resultHandler(nil, resource)
		} else {
			resultHandler(nil, nil)
		}
	}
}
