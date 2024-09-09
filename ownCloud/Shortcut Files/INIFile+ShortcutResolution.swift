//
//  INIFile+ShortcutResolution.swift
//  ownCloud
//
//  Created by Felix Schwarz on 16.04.24.
//  Copyright © 2024 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2024, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import Foundation
import ownCloudSDK
import ownCloudAppShared

public extension INIFile {
	static func resolveShortcutFile(at fileURL: URL, core: OCCore, result handler: @escaping (_ error: Error?, _ url: URL?, _ item: OCItem?) -> Void) {
		if let data = try? Data(contentsOf: fileURL) {
			if let url = INIFile(with: data).url {
				if url.privateLinkItemID != nil {
					core.retrieveItem(forPrivateLink: url, completionHandler: { error, item in
						var effectiveError = error

						if let nsError = error as? NSError, nsError.isOCError(withCode: .itemDestinationNotFound) {
							effectiveError = NSError(domain: OCErrorDomain, code: Int(OCError.itemDestinationNotFound.rawValue), userInfo: [NSLocalizedDescriptionKey : OCLocalizedString("The destination this shortcut points to could not be found. It may have been deleted or you may not have access to it.", nil)])
						}

						if effectiveError == nil, item != nil {
							switch OpenShortcutFileAction.openShortcutMode {
								case .linksOnly, .none:
									effectiveError = NSError(domain: OCErrorDomain, code: Int(OCError.itemDestinationNotFound.rawValue), userInfo: [NSLocalizedDescriptionKey : OCLocalizedString("The shortcut points to another item, but the configuration of this app prohibits opening it.", nil)])

								default: break
							}
						}

						OnMainThread {
							handler(effectiveError, (item != nil) ? nil : url, item)
						}
					})
				} else {
					var effectiveError: Error?

					switch OpenShortcutFileAction.openShortcutMode {
						case .itemsOnly, .none:
							effectiveError = NSError(domain: OCErrorDomain, code: Int(OCError.itemDestinationNotFound.rawValue), userInfo: [NSLocalizedDescriptionKey : OCLocalizedString("The shortcut points to a URL, but the configuration of this app prohibits opening it.", nil)])

						default: break
					}

					OnMainThread {
						handler(effectiveError, url, nil)
					}
				}
			} else {
				handler(NSError(ocError: .privateLinkInvalidFormat), nil, nil)
			}
		} else {
			handler(NSError(ocError: .fileNotFound), nil, nil)
		}
	}
}
