//
//  INIFile+URLFile.swift
//  ownCloud
//
//  Created by Felix Schwarz on 08.04.24.
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

public extension INIFile {
	static func URLFile(with targetURL: URL) -> INIFile {
		return INIFile(with: [INISection(title: "InternetShortcut", keyValuePairs: [("URL", targetURL.absoluteString)])])
	}

	var url: URL? {
		if let urlString =  firstSection(titled: "InternetShortcut")?.value(forFirst: "URL") {
			return URL(string: urlString)
		}

		return nil
	}
}
