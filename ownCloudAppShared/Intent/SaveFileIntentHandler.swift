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

@available(iOS 13.0, *)
public class SaveFileIntentHandler: NSObject, SaveFileIntentHandling {

	public func handle(intent: SaveFileIntent, completion: @escaping (SaveFileIntentResponse) -> Void) {

		guard IntentSettings.shared.isEnabled else {
			completion(SaveFileIntentResponse(code: .disabled, userActivity: nil))
			return
		}

		guard !AppLockHelper().isPassCodeEnabled else {
			completion(SaveFileIntentResponse(code: .authenticationRequired, userActivity: nil))
			return
		}

		guard let path = intent.path?.pathRepresentation, let uuid = intent.account?.uuid, let file = intent.file, let fileURL = file.fileURL else {
			completion(SaveFileIntentResponse(code: .failure, userActivity: nil))
			return
		}

		guard let bookmark = OCBookmarkManager.shared.bookmark(for: uuid) else {
			completion(SaveFileIntentResponse(code: .accountFailure, userActivity: nil))
			return
		}

		guard IntentSettings.shared.isLicensedFor(bookmark: bookmark) else {
			completion(SaveFileIntentResponse(code: .unlicensed, userActivity: nil))
			return
		}

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
		let filePath = path + newFilename
		
		// Check if given save path exists
		OCItemTracker().item(for: bookmark, at: path) { (error, core, item) in
			if error == nil, let targetItem = item {
				// Check if file already exists
				OCItemTracker().item(for: bookmark, at: filePath) { (error, core, fileItem) in
					OnBackgroundQueue {
						if error == nil, let core = core, let fileItem = fileItem, let parentItem = fileItem.parentItem(from: core) {
							// File already exists
							core.reportLocalModification(of: fileItem, parentItem: parentItem, withContentsOfFileAt: fileURL, isSecurityScoped: true, options: [OCCoreOption.importByCopying : true], placeholderCompletionHandler: nil,
														 resultHandler: { (error, _ core, _ item, _) in
															if error != nil {
																completion(SaveFileIntentResponse(code: .failure, userActivity: nil))
															} else {	completion(SaveFileIntentResponse.success(filePath: item?.path ?? ""))
															}
							})
						} else if core != nil {
							// File does NOT exists => import file
							core?.importFileNamed(newFilename,
												  at: targetItem,
												  from: fileURL,
												  isSecurityScoped: true,
												  options: [OCCoreOption.importByCopying : true],
												  placeholderCompletionHandler: nil,
												  resultHandler: { (error, _ core, _ item, _) in
													if error != nil {
														completion(SaveFileIntentResponse(code: .failure, userActivity: nil))
													} else {	completion(SaveFileIntentResponse.success(filePath: item?.path ?? ""))
													}
							}
							)
						} else {
							completion(SaveFileIntentResponse(code: .failure, userActivity: nil))
						}
					}
				}
			} else if core != nil {
				completion(SaveFileIntentResponse(code: .pathFailure, userActivity: nil))
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
		completion(INStringResolutionResult.success(with: intent.filename ?? ""))
	}

	public func resolveFileextension(for intent: SaveFileIntent, with completion: @escaping (INStringResolutionResult) -> Void) {
		completion(INStringResolutionResult.success(with: intent.fileextension ?? ""))
	}
}

@available(iOS 13.0, *)
extension SaveFileIntentResponse {

	public static func success(filePath: String) -> SaveFileIntentResponse {
		let intentResponse = SaveFileIntentResponse(code: .success, userActivity: nil)
		intentResponse.filePath = filePath
		return intentResponse
	}
}
