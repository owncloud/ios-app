//
//  CoreManager.swift
//  ownCloud
//
//  Created by Felix Schwarz on 06.04.18.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2018, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import Foundation
import ownCloudSDK

class CoreManager: NSObject {
	var coresByUUID: [UUID : OCCore] = Dictionary()
	var requestCountByUUID: [UUID : Int] = Dictionary()

	static var shared : CoreManager = {
		let sharedInstance = CoreManager()

		return (sharedInstance)
	}()

	func requestCoreForBookmark(_ bookmark: OCBookmark, completion: ((_ core: OCCore, _ error: Error?) -> Void)?) -> OCCore? {
		var returnCore : OCCore? = nil

		OCSynchronized(self) {
			let requestCount =  (requestCountByUUID[bookmark.uuid] ?? 0) + 1

			requestCountByUUID[bookmark.uuid] = requestCount

			if requestCount==1 {
				// Create and start core
				if let core = OCCore(bookmark: bookmark) {
					returnCore = core

					coresByUUID[bookmark.uuid] = core

					core.start(completionHandler: { (_, error) in
						completion?(core, error)
					})
				}
			} else {
				if let core = coresByUUID[bookmark.uuid] {
					returnCore = core

					if core.state != .running {
						core.start(completionHandler: { (_, error) in
							completion?(core, error)
						})
					}
				}
			}
		}

		return returnCore
	}

	func returnCoreForBookmark(_ bookmark: OCBookmark, completion: (() -> Void)?) {
		OCSynchronized(self) {
			var requestCount = (requestCountByUUID[bookmark.uuid] ?? 0)

			if requestCount>0 {
				requestCount -= 1
				requestCountByUUID[bookmark.uuid] = requestCount
			}

			if requestCount==0 {
				// Stop and release core
				if let core = coresByUUID[bookmark.uuid] {
					core.stop(completionHandler: { (_, _) in
						completion?()
					})
					return
				}
			}

			completion?()
		}
	}

	func runVaultOperationForBookmark(_ bookmark: OCBookmark, operation: (_ vault: OCVault) -> Void) {

	}
}
