//
//  UserDefaults+Extension.swift
//  ownCloud Share Extension
//
//  Created by Matthias Hühne on 11.03.20.
//  Copyright © 2020 ownCloud GmbH. All rights reserved.
//

/*
* Copyright (C) 2020, ownCloud GmbH.
*
* This code is covered by the GNU Public License Version 3.
*
* For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
* You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
*
*/

import Foundation

extension UserDefaults {

	enum MediaFilesKeys : String {
		case EnableStreamingKey = "media-enable-streaming"
	}

	public var streamingEnabled: Bool {
		set {
			self.set(newValue, forKey: MediaFilesKeys.EnableStreamingKey.rawValue)
		}

		get {
			return self.bool(forKey: MediaFilesKeys.EnableStreamingKey.rawValue)
		}
	}

	enum MediaUploadKeys : String {
		case ConvertHEICtoJPEGKey = "convert-heic-to-jpeg"
		case ConvertVideosToMP4Key = "convert-videos-to-mp4"
		case InstantUploadPhotosKey = "instant-upload-photos"
		case InstantUploadVideosKey = "instant-upload-videos"
		case InstantUploadBookmarkUUIDKey = "instant-upload-bookmark-uuid"
		case InstantUploadPathKey = "instant-upload-path"
		case InstantUploadPhotosAfterDateKey = "instant-upload-photos-after-date"
		case InstantUploadVideosAfterDateKey = "instant-upload-videos-after-date"
	}

	public static let MediaUploadSettingsChangedNotification = NSNotification.Name("settings.media-upload-settings-changed")

	public var convertHeic: Bool {
		set {
			self.set(newValue, forKey: MediaUploadKeys.ConvertHEICtoJPEGKey.rawValue)
		}

		get {
			return self.bool(forKey: MediaUploadKeys.ConvertHEICtoJPEGKey.rawValue)
		}
	}

	public var convertVideosToMP4: Bool {
		set {
			self.set(newValue, forKey: MediaUploadKeys.ConvertVideosToMP4Key.rawValue)
		}

		get {
            // TODO: MPEG-4 conversion is broken in iOS13, revisit it again in later releases
            //return self.bool(forKey: MediaUploadKeys.ConvertVideosToMP4Key.rawValue)
            return false
		}
	}

	public var instantUploadPhotos: Bool {
		set {
			self.set(newValue, forKey: MediaUploadKeys.InstantUploadPhotosKey.rawValue)
		}

		get {
			return self.bool(forKey: MediaUploadKeys.InstantUploadPhotosKey.rawValue)
		}
	}

	public var instantUploadVideos: Bool {
		set {
			self.set(newValue, forKey: MediaUploadKeys.InstantUploadVideosKey.rawValue)
		}

		get {
			return self.bool(forKey: MediaUploadKeys.InstantUploadVideosKey.rawValue)
		}
	}

	public var instantUploadBookmarkUUID: UUID? {
		set {
			self.set(newValue?.uuidString, forKey: MediaUploadKeys.InstantUploadBookmarkUUIDKey.rawValue)
		}

		get {
			if let uuidString = self.string(forKey: MediaUploadKeys.InstantUploadBookmarkUUIDKey.rawValue) {
				return UUID(uuidString: uuidString)
			} else {
				return nil
			}
		}
	}

	public var instantUploadPath: String? {

		set {
			self.set(newValue, forKey: MediaUploadKeys.InstantUploadPathKey.rawValue)
		}

		get {
			return self.string(forKey: MediaUploadKeys.InstantUploadPathKey.rawValue)
		}
	}

	public var instantUploadPhotosAfter: Date? {
		set {
			self.set(newValue, forKey: MediaUploadKeys.InstantUploadPhotosAfterDateKey.rawValue)
		}

		get {
			return self.value(forKey: MediaUploadKeys.InstantUploadPhotosAfterDateKey.rawValue) as? Date
		}
	}

	public var instantUploadVideosAfter: Date? {
		set {
			self.set(newValue, forKey: MediaUploadKeys.InstantUploadVideosAfterDateKey.rawValue)
		}

		get {
			return self.value(forKey: MediaUploadKeys.InstantUploadVideosAfterDateKey.rawValue) as? Date
		}
	}

	public func resetInstantUploadConfiguration() {
		self.instantUploadBookmarkUUID = nil
		self.instantUploadPath = nil
		self.instantUploadPhotos = false
		self.instantUploadVideos = false
	}
}
