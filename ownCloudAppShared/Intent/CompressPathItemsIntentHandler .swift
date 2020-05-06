//
//  CompressPathItemsIntentHandler.swift
//  ownCloudAppShared
//
//  Created by Matthias Hühne on 30.08.19.
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

@available(iOS 13.0, *)
public class CompressPathItemsIntentHandler: NSObject, CompressPathItemsIntentHandling {

	let defaultZipName = "Archive.zip".localized

	public func handle(intent: CompressPathItemsIntent, completion: @escaping (CompressPathItemsIntentResponse) -> Void) {

		guard IntentSettings.shared.isEnabled else {
			completion(CompressPathItemsIntentResponse(code: .disabled, userActivity: nil))
			return
		}

		guard !AppLockHelper().isPassCodeEnabled else {
			completion(CompressPathItemsIntentResponse(code: .authenticationRequired, userActivity: nil))
			return
		}

		guard let pathItems = intent.pathItems, let uuid = intent.account?.uuid else {
			completion(CompressPathItemsIntentResponse(code: .failure, userActivity: nil))
			return
		}

		guard let bookmark = OCBookmarkManager.shared.bookmark(for: uuid) else {
			completion(CompressPathItemsIntentResponse(code: .accountFailure, userActivity: nil))
			return
		}

		guard IntentSettings.shared.isLicensedFor(bookmark: bookmark) else {
			completion(CompressPathItemsIntentResponse(code: .unlicensed, userActivity: nil))
			return
		}

		var unifiedItems : [DownloadItem] = []
		let dispatchGroup = DispatchGroup()

		for path in pathItems {
			dispatchGroup.enter()
			OCItemTracker().item(for: bookmark, at: path) { (error, core, item) in
				if error == nil, let item = item, let core = core {
					if item.type == .file {
						core.localFile(for: item) { (downloadItem) in
							if let downloadItem = downloadItem {
								unifiedItems.append(downloadItem)
							}
							dispatchGroup.leave()
						}
					} else {
						unifiedItems.append(DownloadItem(file: OCFile(), item: item))

						core.retrieveSubItems(for: item) { (items) in
							for item in items! {
								if item.type == .file {
									dispatchGroup.enter()
									core.localFile(for: item) { (downloadItem) in
										if let downloadItem = downloadItem {
											unifiedItems.append(downloadItem)
										}
										dispatchGroup.leave()
									}
								} else {
									unifiedItems.append(DownloadItem(file: OCFile(), item: item))
								}
							}
							dispatchGroup.leave()
						}
					}
				} else if core != nil {
					completion(CompressPathItemsIntentResponse(code: .pathFailure, userActivity: nil))
				} else {
					completion(CompressPathItemsIntentResponse(code: .failure, userActivity: nil))
				}
			}
		}
		dispatchGroup.wait()

		if unifiedItems.count > 0 {
			var zipFileName = defaultZipName
			if let filename = intent.filename, filename.count > 0 {
				zipFileName = filename
			} else if unifiedItems.count == 1, let item = unifiedItems.first?.item {
				zipFileName = String(format: "%@.zip", item.name ?? defaultZipName)
			}

			let zipURL = FileManager.default.temporaryDirectory.appendingPathComponent(zipFileName)
			let error = ZIPArchive.compressContents(of: unifiedItems, fromBasePath: "/", asZipFile: zipURL, withPassword: nil)

			let file = INFile(fileURL: zipURL, filename: zipFileName, typeIdentifier: nil)
			completion(CompressPathItemsIntentResponse.success(file: file))
		} else {
			completion(CompressPathItemsIntentResponse(code: .failure, userActivity: nil))
		}
	}

	public func resolveAccount(for intent: CompressPathItemsIntent, with completion: @escaping (AccountResolutionResult) -> Void) {
		if let account = intent.account {
			completion(AccountResolutionResult.success(with: account))
		} else {
			completion(AccountResolutionResult.needsValue())
		}
	}

	public func provideAccountOptions(for intent: CompressPathItemsIntent, with completion: @escaping ([Account]?, Error?) -> Void) {
		completion(OCBookmarkManager.shared.accountList, nil)
	}

	public func resolvePathItems(for intent: CompressPathItemsIntent, with completion: @escaping ([INStringResolutionResult]) -> Void) {
		if let pathItems = intent.pathItems {

			var resolutionResults = [INStringResolutionResult]()
			for pathItem in pathItems {
				if pathItem.count > 0 {
					resolutionResults.append(INStringResolutionResult.success(with: pathItem))
				} else {
					resolutionResults.append(INStringResolutionResult.needsValue())
				}
			}
			completion(resolutionResults)
		} else {
			completion([INStringResolutionResult.needsValue()])
		}
	}

	public func resolveFilename(for intent: CompressPathItemsIntent, with completion: @escaping (INStringResolutionResult) -> Void) {
		completion(INStringResolutionResult.success(with: intent.filename ?? ""))
	}
}

@available(iOS 13.0, *)
extension CompressPathItemsIntentResponse {

    public static func success(file: INFile) -> CompressPathItemsIntentResponse {
        let intentResponse = CompressPathItemsIntentResponse(code: .success, userActivity: nil)
        intentResponse.file = file
        return intentResponse
    }
}
