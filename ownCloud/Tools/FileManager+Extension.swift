//
//  FileManager+Extension.swift
//  ownCloud
//
//  Created by Michael Neuwert on 08.05.2019.
//  Copyright © 2019 ownCloud GmbH. All rights reserved.
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

extension FileManager {
	func calculateDirectorySize(at url:URL, completion:@escaping (_ sizeInBytes:Int64?) -> Void) {
		DispatchQueue.global(qos: .background).async {
			let enumerator = self.enumerator(at: url, includingPropertiesForKeys: [URLResourceKey.fileSizeKey], options: [.skipsHiddenFiles])

			var totalSize:Int64?
			if enumerator != nil {
				totalSize = 0
				for case let fileURL as URL in enumerator! {
					if let fileAttrs = try? self.attributesOfItem(atPath: fileURL.path) {
						if let size = (fileAttrs[FileAttributeKey.size] as? NSNumber)?.int64Value {
							totalSize! += size
						}
					}
				}
			}

			OnMainThread {
				completion(totalSize)
			}
		}
	}

	func availableFreeStorageSpace() -> Int64 {
		var bytesAvailable: Int64 = -1
		if let attributes = try? self.attributesOfFileSystem(forPath: "/") {
			if let value = attributes[FileAttributeKey.systemFreeSize] as? NSNumber {
				bytesAvailable = value.int64Value
			}
		}
		return bytesAvailable
	}
}
