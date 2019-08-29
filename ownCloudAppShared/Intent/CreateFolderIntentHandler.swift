//
//  CreateFolderIntentHandler.swift
//  ownCloudAppShared
//
//  Created by Matthias Hühne on 31.07.19.
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
import Intents
import ownCloudSDK

public class CreateFolderIntentHandler: NSObject, CreateFolderIntentHandling {

	var itemTracking : OCCoreItemTracking?

	public func handle(intent: CreateFolderIntent, completion: @escaping (CreateFolderIntentResponse) -> Void) {
		if let path = intent.path, let uuid = intent.accountUUID, let name = intent.name {

			let accountBookmark = OCBookmarkManager.shared.bookmark(for: uuid)

			if let bookmark = accountBookmark {
				OCCoreManager.shared.requestCore(for: bookmark, setup: nil, completionHandler: { (core, error) in
					if error == nil, let core = core {
						self.itemTracking = core.trackItem(atPath: path, trackingHandler: { (error, item, isInitial) in
							if let targetItem = item {
								if core.createFolder(name, inside: targetItem, options: nil, resultHandler: { (error, _, _, _) in
									if error != nil {
										completion(CreateFolderIntentResponse(code: .failure, userActivity: nil))
									} else {
										completion(CreateFolderIntentResponse(code: .success, userActivity: nil))
									}
								}) == nil {
									completion(CreateFolderIntentResponse(code: .failure, userActivity: nil))
								}
							}

							if isInitial {
								self.itemTracking = nil
							}
						})

					}
				})
			}
		}
	}

	public func resolveName(for intent: CreateFolderIntent, with completion: @escaping (INStringResolutionResult) -> Void) {
		if let name = intent.name {
			completion(INStringResolutionResult.success(with: name))
		} else {
			completion(INStringResolutionResult.needsValue())
		}
	}

	public func resolveAccountUUID(for intent: CreateFolderIntent, with completion: @escaping (INStringResolutionResult) -> Void) {
		if let accountUUID = intent.accountUUID {
			completion(INStringResolutionResult.success(with: accountUUID))
		} else {
			completion(INStringResolutionResult.needsValue())
		}
	}

	public func resolvePath(for intent: CreateFolderIntent, with completion: @escaping (INStringResolutionResult) -> Void) {
		if let path = intent.path {
			completion(INStringResolutionResult.success(with: path))
		} else {
			completion(INStringResolutionResult.needsValue())
		}
	}
}
