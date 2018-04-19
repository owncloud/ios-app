//
//  BookmarkManager.swift
//  ownCloud
//
//  Created by Felix Schwarz on 08.03.18.
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

import Foundation
import ownCloudSDK

class BookmarkManager: NSObject {
	public var bookmarks : NSMutableArray

	static var sharedBookmarkManager : BookmarkManager = {
		let sharedInstance = BookmarkManager()

		sharedInstance.loadBookmarks()

		return (sharedInstance)
	}()

	public override init() {
		bookmarks = NSMutableArray()

		super.init()
	}

	// MARK: - Storage Location
	func bookmarkStoreURL() -> URL {
		return OCAppIdentity.shared().appGroupContainerURL.appendingPathComponent("bookmarks.dat")
	}

	// MARK: - Loading and Saving
	func loadBookmarks() {
		OCSynchronized(self) {
			var loadedBookmarks : NSMutableArray?

			do {
				loadedBookmarks = try NSKeyedUnarchiver.unarchiveObject(with: Data(contentsOf: self.bookmarkStoreURL())) as? NSMutableArray

				if loadedBookmarks != nil {
					bookmarks = loadedBookmarks!
				}
			} catch {
				Log.debug("Loading bookmarks failed with \(error)")
			}
		}
	}

	func saveBookmarks() {
		OCSynchronized(self) {
			do {
				try NSKeyedArchiver.archivedData(withRootObject: bookmarks as Any).write(to: self.bookmarkStoreURL())
			} catch {
				Log.error("Loading bookmarks failed with \(error)")
			}
		}
	}

	// MARK: - Change Notifications
	func postChangeNotification() {
		NotificationCenter.default.post(Notification(name: Notification.Name.BookmarkManagerListChanged))
	}

	// MARK: - Bookmark list administration
	func addBookmark(_ bookmark: OCBookmark) {
		OCSynchronized(self) {
			bookmarks.add(bookmark)
		}

		postChangeNotification()
		saveBookmarks()
	}

	func removeBookmark(_ bookmark: OCBookmark) {
		OCSynchronized(self) {
			bookmarks.remove(bookmark)
		}

		postChangeNotification()
		saveBookmarks()
	}

	func moveBookmark(from: Int, to: Int) {
		OCSynchronized(self) {
			let bookmark = bookmarks.object(at: from)

			bookmarks.removeObject(at: from)
			bookmarks.insert(bookmark, at: to)
		}

		postChangeNotification()
		saveBookmarks()
	}

	func bookmark(at index: Int) -> OCBookmark? {
		var bookmark : OCBookmark? = nil

		OCSynchronized(self) {
			bookmark = bookmarks.object(at: index) as? OCBookmark
		}

		return bookmark
	}

    func removeAuthDataOfBookmark(_ bookmark: OCBookmark) -> OCBookmark {
        
        if bookmark.authenticationMethodIdentifier == OCAuthenticationMethodBasicAuthIdentifier {
            let username = OCAuthenticationMethodBasicAuth.userName(fromAuthenticationData: bookmark.authenticationData)
            let password = ""
            
            do {
                try bookmark.authenticationData = OCAuthenticationMethodBasicAuth.authenticationData(forUsername: username, passphrase: password, authenticationHeaderValue: nil)
            } catch {
                Log.error("Error removing AuthDataOfBookmark on Basic Auth \(error)")
            }
        } else {
            bookmark.authenticationData = nil
        }
        
        saveBookmarks()
        
        return bookmark
    }
}

public extension Notification.Name {
	static let BookmarkManagerListChanged = Notification.Name("BookmarkManagerListChanged")
}
