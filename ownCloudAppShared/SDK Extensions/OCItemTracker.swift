//
//  OCItemTracker.swift
//  ownCloudAppShared
//
//  Created by Matthias Hühne on 26.09.19.
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
import ownCloudSDK

public class OCItemTracker: NSObject {

	var itemTracking : OCCoreItemTracking?

	public func item(for bookmark: OCBookmark, at path: String, completionHandler: @escaping (_ error: Error?, _ core: OCCore?, _ item: OCItem?) -> Void) {

		OCCoreManager.shared.requestCore(for: bookmark, setup: nil, completionHandler: { (core, error) in
			if error == nil, let core = core {
				self.itemTracking = core.trackItem(atPath: path, trackingHandler: { (error, item, isInitial) in
					if isInitial {
						self.itemTracking = nil
					}
					completionHandler(error, core, item)
				})
			} else {
				completionHandler(error, nil, nil)
			}
		})
	}
}
