//
//  FileProviderInterfaceManager.swift
//  ownCloud
//
//  Created by Felix Schwarz on 08.06.18.
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

import UIKit
import ownCloudSDK

class FileProviderInterfaceManager: NSObject {
	static let shared : FileProviderInterfaceManager = {
		var manager = FileProviderInterfaceManager()

		return (manager)
	}()

	override init() {
		super.init()

		NotificationCenter.default.addObserver(self, selector: #selector(self.bookmarksChanged), name: Notification.Name.OCBookmarkManagerListChanged, object: nil)
	}

	deinit {
		NotificationCenter.default.removeObserver(self, name: Notification.Name.OCBookmarkManagerListChanged, object: nil)
	}

	@objc func bookmarksChanged() {
		OnMainThread {
			self.updateDomainsFromBookmarks()
		}
	}

	func updateDomainsFromBookmarks() {
		NSFileProviderManager.getDomainsWithCompletionHandler { (fileProviderDomains, error) in
			OnMainThread {
				if error != nil {
					Log.error("Error getting domains: \(String(describing: error))")
					return
				}

				if let bookmarks = OCBookmarkManager.shared.bookmarks as? [OCBookmark] {
					var bookmarkUUIDStrings : [String] = []
					var bookmarksByUUIDString : [String:OCBookmark] = [:]
					let waitForManagerGroup = DispatchGroup()

					// Collect info on bookmarks
					for bookmark in bookmarks {
						bookmarkUUIDStrings.append(bookmark.uuid.uuidString)
						bookmarksByUUIDString[bookmark.uuid.uuidString] = bookmark
					}

					for domain in fileProviderDomains {
						let domainIdentifierString = domain.identifier.rawValue
						var removeDomain : Bool = false

						if let removeAtIndex = bookmarkUUIDStrings.index(of: domainIdentifierString) {
							// Domain is already registered for this bookmark -> check if name also still matches
							if bookmarksByUUIDString[domainIdentifierString]?.shortName == domain.displayName {
								// Identical -> no changes needed for this bookmark
								bookmarkUUIDStrings.remove(at: removeAtIndex)
							} else {
								// Different -> remove
								removeDomain = true
							}
						} else {
							// Domain is no longer backed by a bookmark -> remove
							removeDomain = true
						}

						if removeDomain {
							waitForManagerGroup.enter()

							NSFileProviderManager.remove(domain, completionHandler: { (error) in
								Log.error("Error removing domain: \(domain) error: \(String(describing: error))")
								waitForManagerGroup.leave()
							})
						}
					}

					// Wait for NSFileProviderManager operations to settle
					_ = waitForManagerGroup.wait(timeout: DispatchTime.distantFuture)

					// Add domains for bookmarks
					for bookmarkUUIDToAdd in bookmarkUUIDStrings {
						if let bookmark = bookmarksByUUIDString[bookmarkUUIDToAdd] {
							let newDomain = NSFileProviderDomain(identifier: NSFileProviderDomainIdentifier(rawValue: bookmark.uuid.uuidString),
											     displayName: bookmark.shortName,
											     pathRelativeToDocumentStorage: bookmark.uuid.uuidString)

							waitForManagerGroup.enter()

							NSFileProviderManager.add(newDomain, completionHandler: { (error) in
								Log.error("Error adding domain: \(newDomain) error: \(String(describing: error))")
								waitForManagerGroup.leave()
							})
						}
					}

					// Wait for NSFileProviderManager operations to settle
					_ = waitForManagerGroup.wait(timeout: DispatchTime.distantFuture)
				}
			}
		}
	}
}
