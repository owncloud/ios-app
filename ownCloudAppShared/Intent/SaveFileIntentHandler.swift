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

@available(iOS 13.0, watchOS 6.0, *)
public class SaveFileIntentHandler: NSObject, SaveFileIntentHandling {

	var itemTracking : OCCoreItemTracking?

	public func handle(intent: SaveFileIntent, completion: @escaping (SaveFileIntentResponse) -> Void) {
		if AppLockHelper().isPassCodeEnabled {
			completion(SaveFileIntentResponse(code: .authenticationRequired, userActivity: nil))
		} else {
			if let path = intent.path, let uuid = intent.account?.uuid, let file = intent.file, let fileURL = file.fileURL {
				let accountBookmark = OCBookmarkManager.shared.bookmark(for: uuid)

				if let bookmark = accountBookmark {
					OCCoreManager.shared.requestCore(for: bookmark, setup: nil, completionHandler: { (core, error) in
						if error == nil, let core = core {
							self.itemTracking = core.trackItem(atPath: path, trackingHandler: { (error, item, isInitial) in
								if let targetItem = item {
									var newFilename = file.filename
									if let filename = intent.filename as NSString?, filename.length > 0, let defaultFilename = file.filename as NSString? {
										var pathExtention = defaultFilename.pathExtension
										if let fileExtension = intent.fileextension, fileExtension.count > 0 {
											pathExtention = fileExtension
										}
										if let changedFilename = filename.appendingPathExtension(pathExtention) {
											newFilename = changedFilename
										}
									} else if let fileExtension = intent.fileextension, fileExtension.count > 0, let defaultFilename = file.filename as NSString? {
										let filename = defaultFilename.deletingPathExtension as NSString
										if let changedFilename = filename.appendingPathExtension(fileExtension) {
											newFilename = changedFilename
										}
									}

									if core.importFileNamed(newFilename,
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
																	completion(SaveFileIntentResponse.success(filePath: item?.path ?? ""))
																}
									}
										) == nil {
										completion(SaveFileIntentResponse(code: .failure, userActivity: nil))
									}
								} else {
									completion(SaveFileIntentResponse(code: .pathFailure, userActivity: nil))
								}

								if isInitial {
									self.itemTracking = nil
								}
							})

						} else {
							completion(SaveFileIntentResponse(code: .failure, userActivity: nil))
						}
					})
				} else {
					completion(SaveFileIntentResponse(code: .accountFailure, userActivity: nil))
				}
			} else {
				completion(SaveFileIntentResponse(code: .failure, userActivity: nil))
			}
		}
	}

	public func provideAccountOptions(for intent: SaveFileIntent, with completion: @escaping ([Account]?, Error?) -> Void) {
		completion(OCBookmarkManager.shared.accountList, nil)
	}

	public func resolveAccount(for intent: SaveFileIntent, with completion: @escaping (AccountResolutionResult) -> Void) {
		if let account = intent.account {
			completion(AccountResolutionResult.success(with: account))
		} else {
			completion(AccountResolutionResult.needsValue())
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

	public func resolveFilename(for intent: SaveFileIntent, with completion: @escaping (INStringResolutionResult) -> Void) {
		if let filename = intent.filename {
			completion(INStringResolutionResult.success(with: filename))
		} else {
			completion(INStringResolutionResult.needsValue())
		}
	}

	public func resolveFileextension(for intent: SaveFileIntent, with completion: @escaping (INStringResolutionResult) -> Void) {
		if let fileExtension = intent.fileextension {
			completion(INStringResolutionResult.success(with: fileExtension))
		} else {
			completion(INStringResolutionResult.needsValue())
		}
	}
}

@available(iOS 13.0, watchOS 6.0, *)
extension SaveFileIntentResponse {

    public static func success(filePath: String) -> SaveFileIntentResponse {
        let intentResponse = SaveFileIntentResponse(code: .success, userActivity: nil)
        intentResponse.filePath = filePath
        return intentResponse
    }
}
