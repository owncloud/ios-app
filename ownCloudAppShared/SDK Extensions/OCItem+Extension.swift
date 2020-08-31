//
//  OCItem+Extension.swift
//  ownCloud
//
//  Created by Felix Schwarz on 13.04.18.
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

extension OCItem {
	static private let iconNamesByMIMEType : [String:String] = {
		var mimeTypeToIconMap :  [String:String] = [
			// List taken from https://github.com/owncloud/core/blob/master/core/js/mimetypelist.js
			"application/coreldraw": "image",
			"application/epub+zip": "text",
			"application/font-sfnt": "image",
			"application/font-woff": "image",
			"application/illustrator": "image",
			"application/javascript": "text/code",
			"application/json": "text/code",
			"application/msaccess": "file",
			"application/msexcel": "x-office/spreadsheet",
			"application/msonenote": "x-office/document",
			"application/mspowerpoint": "x-office/presentation",
			"application/msword": "x-office/document",
			"application/octet-stream": "file",
			"application/postscript": "image",
			"application/rss+xml": "application/xml",
			"application/vnd.android.package-archive": "package/x-generic",
			"application/vnd.lotus-wordpro": "x-office/document",
			"application/vnd.ms-excel": "x-office/spreadsheet",
			"application/vnd.ms-excel.addin.macroEnabled.12": "x-office/spreadsheet",
			"application/vnd.ms-excel.sheet.binary.macroEnabled.12": "x-office/spreadsheet",
			"application/vnd.ms-excel.sheet.macroEnabled.12": "x-office/spreadsheet",
			"application/vnd.ms-excel.template.macroEnabled.12": "x-office/spreadsheet",
			"application/vnd.ms-fontobject": "image",
			"application/vnd.ms-powerpoint": "x-office/presentation",
			"application/vnd.ms-powerpoint.addin.macroEnabled.12": "x-office/presentation",
			"application/vnd.ms-powerpoint.presentation.macroEnabled.12": "x-office/presentation",
			"application/vnd.ms-powerpoint.slideshow.macroEnabled.12": "x-office/presentation",
			"application/vnd.ms-powerpoint.template.macroEnabled.12": "x-office/presentation",
			"application/vnd.ms-word.document.macroEnabled.12": "x-office/document",
			"application/vnd.ms-word.template.macroEnabled.12": "x-office/document",
			"application/vnd.oasis.opendocument.presentation": "x-office/presentation",
			"application/vnd.oasis.opendocument.presentation-template": "x-office/presentation",
			"application/vnd.oasis.opendocument.spreadsheet": "x-office/spreadsheet",
			"application/vnd.oasis.opendocument.spreadsheet-template": "x-office/spreadsheet",
			"application/vnd.oasis.opendocument.text": "x-office/document",
			"application/vnd.oasis.opendocument.text-master": "x-office/document",
			"application/vnd.oasis.opendocument.text-template": "x-office/document",
			"application/vnd.oasis.opendocument.text-web": "x-office/document",
			"application/vnd.openxmlformats-officedocument.presentationml.presentation": "x-office/presentation",
			"application/vnd.openxmlformats-officedocument.presentationml.slideshow": "x-office/presentation",
			"application/vnd.openxmlformats-officedocument.presentationml.template": "x-office/presentation",
			"application/vnd.openxmlformats-officedocument.spreadsheetml.sheet": "x-office/spreadsheet",
			"application/vnd.openxmlformats-officedocument.spreadsheetml.template": "x-office/spreadsheet",
			"application/vnd.openxmlformats-officedocument.wordprocessingml.document": "x-office/document",
			"application/vnd.openxmlformats-officedocument.wordprocessingml.template": "x-office/document",
			"application/vnd.visio": "x-office/document",
			"application/vnd.wordperfect": "x-office/document",
			"application/x-7z-compressed": "package/x-generic",
			"application/x-bzip2": "package/x-generic",
			"application/x-cbr": "text",
			"application/x-compressed": "package/x-generic",
			"application/x-dcraw": "image",
			"application/x-deb": "package/x-generic",
			"application/x-font": "image",
			"application/x-gimp": "image",
			"application/x-gzip": "package/x-generic",
			"application/x-perl": "text/code",
			"application/x-photoshop": "image",
			"application/x-php": "text/code",
			"application/x-rar-compressed": "package/x-generic",
			"application/x-tar": "package/x-generic",
			"application/x-tex": "text",
			"application/xml": "text/html",
			"application/yaml": "text/code",
			"application/zip": "package/x-generic",
			"database": "file",
			"httpd/unix-directory": "dir",
			"message/rfc822": "text",
			"text/css": "text/code",
			"text/csv": "x-office/spreadsheet",
			"text/html": "text/code",
			"text/x-c": "text/code",
			"text/x-c++src": "text/code",
			"text/x-h": "text/code",
			"text/x-java-source": "text/code",
			"text/x-python": "text/code",
			"text/x-shellscript": "text/code",
			"web": "text/code"
		]

		mimeTypeToIconMap.keys.forEach {
			let mimeTypeKey = $0
			var mimeType : String? = mimeTypeToIconMap[mimeTypeKey]
			var referenceMIMEType : String? = mimeType

			while referenceMIMEType != nil {
				referenceMIMEType = mimeTypeToIconMap[referenceMIMEType!]

				if let validMIMEType = referenceMIMEType {
					mimeType = validMIMEType
				}
			}

			mimeTypeToIconMap[mimeTypeKey] = mimeType?.replacingOccurrences(of: "/", with: "-")
		}

		return mimeTypeToIconMap
	}()

	static public let validIconNames : [String] = [
		// List taken from https://github.com/owncloud/core/blob/master/core/js/mimetypelist.js
		"application",
		"application-pdf",
		"audio",
		"file",
		"folder",
		"folder-create",
		"folder-drag-accept",
		"folder-external",
		"folder-public",
		"folder-shared",
		"folder-starred",
		"image",
		"package-x-generic",
		"text",
		"text-calendar",
		"text-code",
		"text-vcard",
		"video",
		"x-office-document",
		"x-office-presentation",
		"x-office-spreadsheet",
		"icon-search"
	]

	static public func iconName(for MIMEType: String?) -> String? {
		var iconName : String?

		if let mimeType = MIMEType {
			iconName = self.iconNamesByMIMEType[mimeType]

			if iconName != nil {
				if !(self.validIconNames.contains(iconName!)) {
					iconName = nil
				}
			}

			if iconName == nil {
				let flatMIMEType = mimeType.replacingOccurrences(of: "/", with: "-")

				if self.validIconNames.contains(flatMIMEType) {
					iconName = flatMIMEType
				} else {
					if let mimeCategory = mimeType.components(separatedBy: "/").first {
						if mimeCategory != "application" {
							if self.validIconNames.contains(mimeCategory) {
								iconName = mimeCategory
							}
						}
					}
				}
			}
		}

		return iconName
	}

	public var iconName : String? {
		var iconName = OCItem.iconName(for: self.mimeType)

		if iconName == nil {
			if self.type == .collection {
				iconName = "folder"
			} else {
				iconName = "file"
			}
		}

		return iconName
	}

	public var fileExtension : String? {
		return (self.name as NSString?)?.pathExtension
	}

	public var baseName : String? {
		return (self.name as NSString?)?.deletingPathExtension
	}

	public var sizeLocalized: String {
		return OCItem.byteCounterFormatter.string(fromByteCount: Int64(self.size))
	}

	public var lastModifiedLocalized: String {
		guard let lastModified = self.lastModified else { return "" }

		return OCItem.dateFormatter.string(from: lastModified)
	}

	static private let byteCounterFormatter: ByteCountFormatter = {
		let byteCounterFormatter = ByteCountFormatter()
		byteCounterFormatter.allowsNonnumericFormatting = false
		return byteCounterFormatter
	}()

	static private let dateFormatter: DateFormatter = {
		let dateFormatter: DateFormatter =  DateFormatter()
		dateFormatter.timeStyle = .short
		dateFormatter.dateStyle = .medium
		dateFormatter.locale = Locale.current
		dateFormatter.doesRelativeDateFormatting = true
		return dateFormatter
	}()

	public var sharedByPublicLink : Bool {
		if self.shareTypesMask.contains(.link) {
			return true
		}
		return false
	}

	public var isShared : Bool {
		if self.shareTypesMask.isEmpty {
			return false
		}
		return true
	}

	public var sharedByUserOrGroup : Bool {
		if self.shareTypesMask.contains(.userShare) || self.shareTypesMask.contains(.groupShare) || self.shareTypesMask.contains(.remote) {
			return true
		}
		return false
	}

	public func shareRootItem(from core: OCCore) -> OCItem? {
		var shareRootItem : OCItem?

		if self.isSharedWithUser {
			shareRootItem = self

			let waitSemaphore = DispatchSemaphore(value: 0)

			// Wrap all requests into a single transaction to consolidate lookups
			// and avoid having to wait for available time multiple time, accumulating
			// idle/waiting time
			core.vault.database?.performBatchUpdates({ (database) -> Error? in
				var parentPath = self.path?.parentPath
				var lastParentPath = parentPath

				repeat {
					lastParentPath = parentPath

					database?.retrieveCacheItems(atPath: parentPath, itemOnly: true, completionHandler: { (_, error, _, items) in
						if error == nil, let parentItem = items?.first {
							parentPath = parentItem.path

							if parentItem.isSharedWithUser {
								shareRootItem = parentItem
							} else {
								parentPath = nil
							}
						} else {
							parentPath = nil
						}
					})
				} while ((parentPath != nil) && (lastParentPath != parentPath) && (parentPath != "/"))

				waitSemaphore.signal()

				return nil
			}, completionHandler: nil)

			waitSemaphore.wait()
		}

		return shareRootItem
	}

	public func parentItem(from core: OCCore, completionHandler: ((_ error: Error?, _ parentItem: OCItem?) -> Void)? = nil) -> OCItem? {
		var parentItem : OCItem?

		if let parentItemLocalID = self.parentLocalID {
			var waitSemaphore : DispatchSemaphore?

			if completionHandler == nil {
				waitSemaphore = DispatchSemaphore(value: 0)
			}

			core.retrieveItemFromDatabase(forLocalID: parentItemLocalID) { (error, _, item) in
				if parentItem == nil, let parentPath = self.path?.parentPath {
					parentItem = try? core.cachedItem(atPath: parentPath)
				}

				if completionHandler == nil {
					parentItem = item
				} else {
					completionHandler?(error, item)
				}
				waitSemaphore?.signal()
			}

			waitSemaphore?.wait()
		}

		return parentItem
	}

	public func displaysDifferent(than item: OCItem?, in core: OCCore? = nil) -> Bool {
		guard let item = item else {
			return true
		}

		return (
			// Different item
			(item.localID != localID) ||

			// Content deemed different
			contentDifferent(than: item, in: core) ||

			// File name differs
			(item.name != name) ||

			// Upload/Download status differs
			(item.syncActivity != syncActivity) ||
			(item.activeSyncRecordIDs != activeSyncRecordIDs) ||

			// Cloud status differs
			(item.cloudStatus != cloudStatus) ||

			// Available offline status differs
			(item.downloadTriggerIdentifier != downloadTriggerIdentifier) ||
			(core?.availableOfflinePolicyCoverage(of: item) != core?.availableOfflinePolicyCoverage(of: self)) ||

			// Sharing attributes differ
			(item.shareTypesMask != shareTypesMask) ||
			(item.permissions != permissions) // these contain sharing info, too
		)
	}

	public func contentDifferent(than item: OCItem?, in core: OCCore? = nil) -> Bool {
		guard let item = item else {
			return true
		}

		return (
			// Different item
			(item.localID != localID) ||

			// File contents (and therefore likely metadata) differs
			(item.itemVersionIdentifier != itemVersionIdentifier) 		|| // remote item
			(item.localCopyVersionIdentifier != localCopyVersionIdentifier) || // local copy

			// Size differs
			(item.size != size)
		)
	}
}
