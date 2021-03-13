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

public class OCItemTracker: NSObject, OCCoreDelegate {
	var itemTracking : OCCoreItemTracking?
	var startedTracking : Bool = false
	var completionHandler : CompletionHandler?
	var bookmark : OCBookmark?
	weak var requestedCore : OCCore?

	var connectionStatusObservation : NSKeyValueObservation?

	public typealias CompletionHandler = (_ error: Error?, _ core: OCCore?, _ item: OCItem?) -> Void

	@discardableResult
	public init(for bookmark: OCBookmark, at path: String, withErrorHandler: Bool = true, waitOnlineTimeout : TimeInterval? = nil, completionHandler: @escaping CompletionHandler) {
		super.init()

		self.bookmark = bookmark
		self.completionHandler = completionHandler

		OCCoreManager.shared.requestCore(for: bookmark, setup: { (core, error) in
			if withErrorHandler {
				core?.delegate = self
			}
		}, completionHandler: { (core, error) in
			if error == nil, let core = core {
				self.requestedCore = core

				if let timeout = waitOnlineTimeout {
					// Force-start tracking after timeout …
					OnMainThread(after: timeout) {
						self.beginTracking(at: path)
					}

					// … or start tracking when the connection status flips to online
					self.connectionStatusObservation = core.observe(\OCCore.connectionStatus, changeHandler: { (core, _) in
						if core.connectionStatus == .online {
							self.beginTracking(at: path)
						}
					})
				} else {
					self.beginTracking(at: path)
				}
			} else {
				self.completeWith(error: error)
			}
		})
	}

	func beginTracking(at path: String) {
		var startTracking = false

		OCSynchronized(self) {
			if !startedTracking {
				startedTracking = true
				startTracking = true
			}
		}

		if startTracking, let core = self.requestedCore {
			self.itemTracking = core.trackItem(atPath: path, trackingHandler: { [weak core] (error, item, isInitial) in
				if isInitial {
					self.itemTracking = nil
					self.completeWith(error: error, core: core, item: item)
				}
			})
		}
	}

	public func core(_ core: OCCore, handleError inError: Error?, issue: OCIssue?) {
		var error : Error? = inError

		if error == nil, let authError = issue?.authenticationError {
			error = authError
		}

		if let error = error {
			self.completeWith(error: error, core: core)
		}
	}

	func completeWith(error: Error? = nil, core: OCCore? = nil, item: OCItem? = nil) {
		var completion : CompletionHandler?
		var returnCore : Bool = false

		OCSynchronized(self) {
			if completionHandler != nil {
				completion = completionHandler
				completionHandler = nil
			}

			if requestedCore != nil {
				returnCore = true
				requestedCore = nil
			}
		}

		completion?(error, core, item)

		if returnCore, let bookmark = bookmark {
			connectionStatusObservation?.invalidate()
			connectionStatusObservation = nil

			OCCoreManager.shared.returnCore(for: bookmark, completionHandler: nil)
		}
	}
}
