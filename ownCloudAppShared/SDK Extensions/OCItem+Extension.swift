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
import ownCloudApp
import CoreServices
import UniformTypeIdentifiers

extension OCItem {

	public var isPlayable: Bool {
		guard let mime = self.mimeType else { return false }

		guard let uti = UTType(mimeType: mime) else {
			return false
		}

		return uti.conforms(to: .audiovisualContent)
	}

	static private let iconNamesByMIMEType : [String:String] = {
		var mimeTypeToIconMap: [String:String] = OCItem.mimeTypeToAliasesMap

		mimeTypeToIconMap.keys.forEach { mimeTypeKey in
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
		"text-uri-list",
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
				if isRoot, driveID != nil {
					iconName = "space"
				} else {
					iconName = "folder"
				}
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

	public var lastModifiedLocalizedCompact: String {
		guard let lastModified = self.lastModified else { return "" }

		return OCItem.compactDateFormatter.string(from: lastModified)
	}

	public var lastModifiedLocalizedAccessible: String {
		guard let lastModified = self.lastModified else { return "" }

		return OCItem.accessibilityDateFormatter.string(from: lastModified)
	}

	static private let byteCounterFormatter: ByteCountFormatter = {
		let byteCounterFormatter = ByteCountFormatter()
		byteCounterFormatter.allowsNonnumericFormatting = false
		return byteCounterFormatter
	}()

	static public let dateFormatter: DateFormatter = {
		let dateFormatter: DateFormatter =  DateFormatter()
		dateFormatter.timeStyle = .short
		dateFormatter.dateStyle = .medium
		dateFormatter.locale = Locale.current
		dateFormatter.doesRelativeDateFormatting = true
		return dateFormatter
	}()

	static public let compactDateFormatter: DateFormatter = {
		let dateFormatter: DateFormatter =  DateFormatter()
		dateFormatter.timeStyle = .short
		dateFormatter.dateStyle = .short
		dateFormatter.locale = Locale.current
		dateFormatter.doesRelativeDateFormatting = true
		return dateFormatter
	}()

	static public let accessibilityDateFormatter: DateFormatter = {
		let dateFormatter: DateFormatter =  DateFormatter()
		dateFormatter.timeStyle = .short
		dateFormatter.dateStyle = .long
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

					database?.retrieveCacheItems(at: OCLocation(driveID: self.driveID, path: parentPath), itemOnly: true, completionHandler: { (_, error, _, items) in
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
				if parentItem == nil, let parentLocation = self.location?.parent {
					parentItem = try? core.cachedItem(at: parentLocation)
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
