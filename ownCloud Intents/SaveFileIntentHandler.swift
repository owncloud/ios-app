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
import ownCloudApp
import ownCloudAppShared

@available(iOS 13.0, *)
typealias SaveFileCompletionHandler = (SaveFileIntentResponse) -> Void

@available(iOS 13.0, *)
public class SaveFileIntentHandler: NSObject, SaveFileIntentHandling, OCCoreDelegate {
	weak var core : OCCore?
	var completionHandler: SaveFileCompletionHandler?

	func complete(with response: SaveFileIntentResponse) {
		if let completionHandler = completionHandler {
			self.completionHandler = nil

			if let bookmark = core?.bookmark {
				core = nil

				OCCoreManager.shared.returnCore(for: bookmark, completionHandler: {
					completionHandler(response)
				})
			} else {
				completionHandler(response)
			}
		}
	}

	public func core(_ core: OCCore, handleError error: Error?, issue: OCIssue?) {
		if issue?.authenticationError != nil {
			self.complete(with: SaveFileIntentResponse(code: .authenticationFailed, userActivity: nil))
		} else if let error = error, error.isAuthenticationError {
			self.complete(with: SaveFileIntentResponse(code: .authenticationFailed, userActivity: nil))
		}
	}

	var fpServiceSession : OCFileProviderServiceSession?

	func handle(intent: SaveFileIntent, completion: @escaping (SaveFileIntentResponse) -> Void) {
		completionHandler = completion

		guard IntentSettings.shared.isEnabled else {
			complete(with: SaveFileIntentResponse(code: .disabled, userActivity: nil))
			return
		}

		guard !AppLockManager.isPassCodeEnabled else {
			complete(with: SaveFileIntentResponse(code: .authenticationRequired, userActivity: nil))
			return
		}

		guard let path = intent.path?.pathRepresentation, let uuid = intent.account?.uuid, let file = intent.file, let fileURL = file.fileURL else {
			complete(with: SaveFileIntentResponse(code: .failure, userActivity: nil))
			return
		}

		guard let bookmark = OCBookmarkManager.shared.bookmark(for: uuid) else {
			complete(with: SaveFileIntentResponse(code: .accountFailure, userActivity: nil))
			return
		}

		guard IntentSettings.shared.isLicensedFor(bookmark: bookmark) else {
			complete(with: SaveFileIntentResponse(code: .unlicensed, userActivity: nil))
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
		let waitForCompletion = (intent.waitForCompletion as? Bool) ?? false
		let shouldOverwrite = (intent.shouldOverwrite as? Bool) ?? false

		let completeWithCode = { (code: SaveFileIntentResponseCode) in
			self.complete(with: SaveFileIntentResponse(code: code, userActivity: nil))
		}

		let failWithError = { (error: Error?) in
			if error?.isAuthenticationError == true {
				completeWithCode(.authenticationFailed)
			} else {
				completeWithCode(.failure)
			}
		}

		let completeWithResult = { (error : Error?, path : String?) in
			if error != nil {
				failWithError(error)
			} else {
				self.complete(with: SaveFileIntentResponse.success(filePath: path ?? ""))
			}
		}

		// Check if given save path exists
		OCItemTracker(for: bookmark, at: path, waitOnlineTimeout: 5) { (error, core, item) in
			if error == nil, let targetItem = item {
				// Check if file already exists
				OCItemTracker(for: bookmark, at: filePath, waitOnlineTimeout: 5) { (error, core, fileItem) in
					if let core = core {
						if error == nil, let fileItem = fileItem {
							// File already exists
							if !shouldOverwrite {
								self.complete(with: SaveFileIntentResponse(code: .overwriteFailure, userActivity: nil))
							} else {
								// => overwrite
								OCCoreManager.shared.requestCore(for: bookmark, setup: { (core, error) in
									core?.delegate = self
								}, completionHandler: { (core, error) in
									if let core = core {
										self.core = core

										OnBackgroundQueue {
											if let parentItem = fileItem.parentItem(from: core) {
												if waitForCompletion {
													// Wait for completion: report local modification from extension
													core.reportLocalModification(of: fileItem, parentItem: parentItem, withContentsOfFileAt: fileURL, isSecurityScoped: true, options: [OCCoreOption.importByCopying : true], placeholderCompletionHandler: nil, resultHandler: { (error, _, item, _) in
														completeWithResult(error, item?.path)
													})
												} else {
													// Delegate local modification report to File Provider
													let fpServiceSession = OCFileProviderServiceSession(vault: core.vault)
													self.fpServiceSession = fpServiceSession

													let didStartSecurityScopedResource = fileURL.startAccessingSecurityScopedResource()

													fpServiceSession.reportModificationThroughFileProvider(url: fileURL, as: fileItem.name, for: fileItem, to: parentItem, lastModifiedDate: nil, completion: { (error) in
														completeWithResult(error, fileItem.path)

														if didStartSecurityScopedResource {
															fileURL.stopAccessingSecurityScopedResource()
														}
													})
												}
											} else {
												completeWithCode(.pathFailure)
											}
										}
									} else {
										completeWithCode(.accountFailure)
									}
								})
							}
						} else {
							// File does NOT exist => import file
							if waitForCompletion {
								// Wait for completion: import from extension
								OCCoreManager.shared.requestCore(for: bookmark, setup: { (core, error) in
									core?.delegate = self
								}, completionHandler: { (core, error) in
									if let core = core {
										self.core = core

										OnBackgroundQueue {
											core.importFileNamed(newFilename, at: targetItem, from: fileURL, isSecurityScoped: true, options: [OCCoreOption.importByCopying : true], placeholderCompletionHandler: nil, resultHandler: { (error, _, item, _) in
												completeWithResult(error, item?.path)
											})
										}
									} else {
										completeWithResult(error, nil)
									}
								})
							} else {
								// Delegate import to File Provider
								let fpServiceSession = OCFileProviderServiceSession(vault: core.vault)
								self.fpServiceSession = fpServiceSession

								let didStartSecurityScopedResource = fileURL.startAccessingSecurityScopedResource()

								fpServiceSession.importThroughFileProvider(url: fileURL, as: newFilename, to: targetItem, completion: { (error) in
									let itemPath = (targetItem.path as NSString? ?? path as NSString?)?.appendingPathComponent(newFilename)
									completeWithResult(error, itemPath)

									if didStartSecurityScopedResource {
										fileURL.stopAccessingSecurityScopedResource()
									}
								})
							}
						}
					} else {
						failWithError(error)
					}
				}
			} else if core != nil {
				if let error = error {
					failWithError(error)
				} else if item == nil {
					self.complete(with: SaveFileIntentResponse(code: .pathFailure, userActivity: nil))
				}
			} else {
				failWithError(error)
			}
		}
	}

	func provideAccountOptions(for intent: SaveFileIntent, with completion: @escaping ([Account]?, Error?) -> Void) {
		completion(OCBookmarkManager.shared.accountList, nil)
	}

	@available(iOSApplicationExtension 14.0, *)
	func provideAccountOptionsCollection(for intent: SaveFileIntent, with completion: @escaping (INObjectCollection<Account>?, Error?) -> Void) {
		completion(INObjectCollection(items: OCBookmarkManager.shared.accountList), nil)
	}

	func resolveAccount(for intent: SaveFileIntent, with completion: @escaping (AccountResolutionResult) -> Void) {
		if let account = intent.account {
			completion(AccountResolutionResult.success(with: account))
		} else {
			completion(AccountResolutionResult.needsValue())
		}
	}

	func resolvePath(for intent: SaveFileIntent, with completion: @escaping (INStringResolutionResult) -> Void) {
		if let path = intent.path {
			completion(INStringResolutionResult.success(with: path))
		} else {
			completion(INStringResolutionResult.needsValue())
		}
	}

	func resolveFile(for intent: SaveFileIntent, with completion: @escaping (INFileResolutionResult) -> Void) {
		if let file = intent.file {
			completion(INFileResolutionResult.success(with: file))
		} else {
			completion(INFileResolutionResult.needsValue())
		}
	}

	func resolveFilename(for intent: SaveFileIntent, with completion: @escaping (INStringResolutionResult) -> Void) {
		completion(INStringResolutionResult.success(with: intent.filename ?? ""))
	}

	func resolveFileextension(for intent: SaveFileIntent, with completion: @escaping (INStringResolutionResult) -> Void) {
		completion(INStringResolutionResult.success(with: intent.fileextension ?? ""))
	}

	func resolveShouldOverwrite(for intent: SaveFileIntent, with completion: @escaping (INBooleanResolutionResult) -> Void) {
		var shouldOverwrite = false
		if let overwrite = intent.shouldOverwrite?.boolValue {
			shouldOverwrite = overwrite
		}
		completion(INBooleanResolutionResult.success(with: shouldOverwrite))
	}

	func resolveWaitForCompletion(for intent: SaveFileIntent, with completion: @escaping (INBooleanResolutionResult) -> Void) {
		var waitForCompletion = false
		if let doWait = intent.waitForCompletion?.boolValue {
			waitForCompletion = doWait
		}
		completion(INBooleanResolutionResult.success(with: waitForCompletion))
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
