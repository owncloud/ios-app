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

import UIKit
import ownCloudSDK

class BookmarkManager: NSObject
{
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
		var loadedBookmarks : NSMutableArray?

		do {
			loadedBookmarks = try NSKeyedUnarchiver.unarchiveObject(with: Data.init(contentsOf: self.bookmarkStoreURL())) as! NSMutableArray?
			
			if (loadedBookmarks != nil) {
				bookmarks = loadedBookmarks!
			}
		} catch {
			Log.debug("Loading bookmarks failed with \(error)")
		}
	}
	
	func saveBookmarks() {
		do {
			try NSKeyedArchiver.archivedData(withRootObject: bookmarks as Any).write(to: self.bookmarkStoreURL())
		} catch {
			Log.error("Loading bookmarks failed with \(error)")
		}
	}
	
	// MARK: - Administration
	func addBookmark(_ bookmark: OCBookmark) {
		bookmarks.add(bookmark)

		saveBookmarks()
	}
	
	func removeBookmark(_ bookmark: OCBookmark) {
		bookmarks.remove(bookmark)

		saveBookmarks()
	}

	func moveBookmark(from: Int, to: Int) {
		let bookmark = bookmarks.object(at: from)

		bookmarks.removeObject(at: from)
		bookmarks.insert(bookmark, at: to)

		saveBookmarks()
	}
	
	func bookmark(at index: Int) -> OCBookmark {
		return (bookmarks.object(at: index) as! OCBookmark)
	}
}
