//
//  SaveFileIntentHandler.swift
//  ownCloudAppShared
//
//  Created by Matthias Hühne on 30.07.19.
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

public class SaveFileIntentHandler: NSObject, SaveFileIntentHandling {

	var itemTracking : OCCoreItemTracking?

	public func handle(intent: SaveFileIntent, completion: @escaping (SaveFileIntentResponse) -> Void) {
		if let path = intent.path, let uuid = intent.accountUUID, let file = intent.file, let fileURL = file.fileURL {
			let accountBookmark = OCBookmarkManager.shared.bookmark(for: uuid)

			if let bookmark = accountBookmark {
				OCCoreManager.shared.requestCore(for: bookmark, setup: nil, completionHandler: { (core, error) in
					if error == nil, let core = core {
						self.itemTracking = core.trackItem(atPath: path, trackingHandler: { (error, item, isInitial) in
							if let targetItem = item {
								if core.importFileNamed(file.filename,
											 at: targetItem,
											 from: fileURL,
											 isSecurityScoped: true,
											 options: [OCCoreOption.importByCopying : true],
											 placeholderCompletionHandler: { (error, item) in
												if error != nil {
													completion(SaveFileIntentResponse(code: .failure, userActivity: nil))
												}
											 },
											 resultHandler: { (error, _ core, _ item, _) in
												if error != nil {
													completion(SaveFileIntentResponse(code: .failure, userActivity: nil))
												} else {
													completion(SaveFileIntentResponse(code: .success, userActivity: nil))
												}
											}
									) == nil {
										completion(SaveFileIntentResponse(code: .failure, userActivity: nil))
								}
							}

							if isInitial {
								self.itemTracking = nil
							}
						})

					}
				})
			} else {
				completion(SaveFileIntentResponse(code: .failure, userActivity: nil))
			}
		} else {
			completion(SaveFileIntentResponse(code: .failure, userActivity: nil))
		}
	}

	public func resolveAccountUUID(for intent: SaveFileIntent, with completion: @escaping (INStringResolutionResult) -> Void) {
		if let accountUUID = intent.accountUUID {
			completion(INStringResolutionResult.success(with: accountUUID))
		} else {
			completion(INStringResolutionResult.needsValue())
		}
	}

	public func resolvePath(for intent: SaveFileIntent, with completion: @escaping (INStringResolutionResult) -> Void) {
		if let path = intent.path {
			completion(INStringResolutionResult.success(with: path))
		} else {
			completion(INStringResolutionResult.needsValue())
		}
	}

	public func resolveFile(for intent: SaveFileIntent, with completion: @escaping (INFileResolutionResult) -> Void) {
		if let file = intent.file {
			completion(INFileResolutionResult.success(with: file))
		} else {
			completion(INFileResolutionResult.needsValue())
		}
	}
}
