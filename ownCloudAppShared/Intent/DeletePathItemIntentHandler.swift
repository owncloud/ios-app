//
//  DeletePathItemIntentHandler.swift
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

@available(iOS 13.0, *)
public class DeletePathItemIntentHandler: NSObject, DeletePathItemIntentHandling {

	public func handle(intent: DeletePathItemIntent, completion: @escaping (DeletePathItemIntentResponse) -> Void) {

		guard IntentSettings.shared.isEnabled else {
			completion(DeletePathItemIntentResponse(code: .disabled, userActivity: nil))
			return
		}

		guard !AppLockHelper().isPassCodeEnabled else {
			completion(DeletePathItemIntentResponse(code: .authenticationRequired, userActivity: nil))
			return
		}

		guard let path = intent.path, let uuid = intent.account?.uuid else {
			completion(DeletePathItemIntentResponse(code: .failure, userActivity: nil))
			return
		}

		guard let bookmark = OCBookmarkManager.shared.bookmark(for: uuid) else {
			completion(DeletePathItemIntentResponse(code: .accountFailure, userActivity: nil))
			return
		}

		guard IntentSettings.shared.isLicensedFor(bookmark: bookmark) else {
			completion(DeletePathItemIntentResponse(code: .unlicensed, userActivity: nil))
			return
		}

		OCItemTracker().item(for: bookmark, at: path) { (error, core, item) in
			if error == nil, let targetItem = item, let core = core {
				let progress = core.delete(targetItem, requireMatch: true, resultHandler: { (error, _, _, _) in
					if error != nil {
						completion(DeletePathItemIntentResponse(code: .failure, userActivity: nil))
					} else {
						completion(DeletePathItemIntentResponse(code: .success, userActivity: nil))
					}
				})

				if progress == nil {
					completion(DeletePathItemIntentResponse(code: .failure, userActivity: nil))
				}
			} else if core != nil {
				completion(DeletePathItemIntentResponse(code: .pathFailure, userActivity: nil))
			} else {
				completion(DeletePathItemIntentResponse(code: .failure, userActivity: nil))
			}
		}
	}

	public func resolveAccount(for intent: DeletePathItemIntent, with completion: @escaping (AccountResolutionResult) -> Void) {
		if let account = intent.account {
			completion(AccountResolutionResult.success(with: account))
		} else {
			completion(AccountResolutionResult.needsValue())
		}
	}

	public func provideAccountOptions(for intent: DeletePathItemIntent, with completion: @escaping ([Account]?, Error?) -> Void) {
		completion(OCBookmarkManager.shared.accountList, nil)
	}

	public func resolvePath(for intent: DeletePathItemIntent, with completion: @escaping (INStringResolutionResult) -> Void) {
		if let path = intent.path {
			completion(INStringResolutionResult.success(with: path))
		} else {
			completion(INStringResolutionResult.needsValue())
		}
	}
}
