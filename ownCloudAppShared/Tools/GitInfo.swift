//
//  GitInfo.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 05.05.23.
//  Copyright © 2023 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2023, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import UIKit
import ownCloudSDK

public class GitInfo: NSObject {
	public var bundle: Bundle

	public lazy var lastCommit: String? = bundle.object(forInfoDictionaryKey: "LastGitCommit") as? String
	public lazy var tags: String? = bundle.object(forInfoDictionaryKey: "GitTags") as? String
	public lazy var branch: String? = bundle.object(forInfoDictionaryKey: "GitBranch") as? String
	public lazy var buildDate: String? = bundle.object(forInfoDictionaryKey: "BuildDate") as? String
	public lazy var versionInfo: String = {
		return "\(tags ?? "untagged") - \(branch ?? "?")@\(lastCommit ?? "?")"
	}()

	public init(bundle: Bundle) {
		self.bundle = bundle
	}

	public static var app = GitInfo(bundle: .main)
	public static var sdk = GitInfo(bundle: Bundle(for: OCCore.self))
}
