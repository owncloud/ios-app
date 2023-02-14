//
//  AppStateAction.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 07.02.23.
//  Copyright © 2023 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2023, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import Foundation

import UIKit
import ownCloudSDK

public protocol ClientContextProvider {
	func provideClientContext(for bookmarkUUID: UUID, completion: (Error?, ClientContext?) -> Void)
}

open class AppStateAction: NSObject, NSSecureCoding, UserActivityCapture, UserActivityRestoration {
	weak open var parent: AppStateAction?
	open var children: [AppStateAction]? {
		didSet {
			rewireChildren()
		}
	}

	public typealias Completion = (_ error: Error?, _ clientContext: ClientContext) -> Void

	public init(with childActions: [AppStateAction]? = nil) {
		super.init()
		children = childActions
		rewireChildren()
	}

	public func run(in clientContext: ClientContext, completion: @escaping Completion) {
		perform(in: clientContext, completion: { (error, clientContext) in
			if error == nil, let children = self.children, children.count > 0 {
				let dispatchGroup = DispatchGroup()
				var lastChildError: Error?

				for child in children {
					dispatchGroup.enter()
					child.run(in: clientContext, completion: { error, clientContext in
						if let error {
							Log.debug("Execution of AppStateAction \(self) child \(child) failed with error \(error)")
							lastChildError = error
						}

						dispatchGroup.leave()
					})
				}

				dispatchGroup.notify(queue: .main, execute: {
					completion(lastChildError, clientContext)
				})
			} else {
				if let error {
					Log.debug("Execution of AppStateAction \(self) failed with error \(error)")
				}
				completion(error, clientContext)
			}
		})
	}

	func rewireChildren() {
		guard let children else { return }

		for child in children {
			child.parent = self
		}
	}

	// MARK: - Subclassing points
	open class var supportsSecureCoding: Bool {	// Needs to be subclassed for every subclass implementing NSSecureCoding - or otherwise NSKeyedArchiver will raise an exception
		return true
	}

	open func encode(with coder: NSCoder) {
		if let children = children as? NSArray {
			coder.encode(children, forKey: "children")
		}
		// In subclasses, call super and encode action contents
	}

	public required init?(coder: NSCoder) {
		super.init()
		children = coder.decodeArrayOfObjects(ofClass: AppStateAction.self, forKey: "children")
		rewireChildren()
		// In subclasses, call super and decode action contents
 	}

	open func perform(in clientContext: ClientContext, completion: @escaping Completion) {
		// Perform your action here, call completion when done

		// Default implementation just calls the completion handler, allowing it to be used as a container
		completion(nil, clientContext)
	}

	// MARK: - UserActivityCapture
	public func captureUserActivityData(with options: [UserActivityOption : NSObject]?) -> Data? {
		if let data = try? NSKeyedArchiver.archivedData(withRootObject: self, requiringSecureCoding: false) {
			return data
		}

		return nil
	}

	// MARK: - UserActivityRestoration
	public static func restoreFromUserActivity(with data: Data?, options: [UserActivityOption.RawValue : NSObject]?, completion: NSUserActivity.RestoreCompletionHandler?) {
		if let context = options?[UserActivityOption.clientContext.rawValue] as? ClientContext,
		   let actionData = data {
			do {
				if let action = try NSKeyedUnarchiver.unarchivedObject(ofClass: AppStateAction.self, from: actionData) {
					action.run(in: context, completion: { error, clientContext in
						completion?(error)
					})
				} else {
					completion?(NSError(ocError: .invalidType))
				}
			} catch {
				completion?(error)
			}

		} else {
			completion?(NSError(ocError: .invalidParameter))
		}
	}

	// MARK: - User activities
	open func userActivity(with clientContext: ClientContext?) -> NSUserActivity? {
		if let clientContext {
			return NSUserActivity.capture(from: self, with: [
				.clientContext : clientContext
			])
		}

		return NSUserActivity.capture(from: self)
	}
}
