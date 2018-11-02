//
//  UtilsTests.swift
//  ownCloudTests
//
//  Created by Javier Gonzalez on 02/11/2018.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

import ownCloudSDK

class UtilsTests {
	static func deleteAllBookmarks() {

		if let bookmarks:[OCBookmark] = OCBookmarkManager.shared?.bookmarks as? [OCBookmark] {
			for bookmark:OCBookmark in bookmarks {
				OCCoreManager.shared.scheduleOfflineOperation({ (inBookmark, completionHandler) in
					if let bookmark = inBookmark {
						let vault : OCVault = OCVault(bookmark: bookmark)

						vault.erase(completionHandler: { (_, error) in
							DispatchQueue.main.async {
								if error == nil {
									OCBookmarkManager.shared.removeBookmark(bookmark)
								} else {
									print("Error deleting bookmarks")
								}
							}
						})
					}
				}, for: bookmark)
			}
		}
	}
}
