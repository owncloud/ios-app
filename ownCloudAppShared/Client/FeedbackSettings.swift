//
//  FeedbackSettings.swift
//  ownCloudAppShared
//
//  Created by Matthias Hühne on 15.07.20.
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

import ownCloudApp
import ownCloudSDK

public class FeedbackSettings: NSObject {
	static let shared = {
		FeedbackSettings()
	}()
}

// MARK: - OCClassSettings support
extension OCClassSettingsIdentifier {
	static let feedback = OCClassSettingsIdentifier("feedback")
}

extension OCClassSettingsKey {
	public static let appStoreLink = OCClassSettingsKey("app-store-link")
	public static let feedbackEmail = OCClassSettingsKey("feedback-email")
	public static let recommendToFriendEnabled = OCClassSettingsKey("recommend-to-friend-enabled")
	public static let sendFeedbackEnabled = OCClassSettingsKey("send-feedback-enabled")
}

extension FeedbackSettings : OCClassSettingsSupport {
	public static let classSettingsIdentifier : OCClassSettingsIdentifier = .feedback

	public static func defaultSettings(forIdentifier identifier: OCClassSettingsIdentifier) -> [OCClassSettingsKey : Any]? {
		if identifier == .feedback {
			return [ .appStoreLink : "https://itunes.apple.com/app/id1359583808?mt=8",
					 .feedbackEmail: "ios-app@owncloud.com",
					 .recommendToFriendEnabled: !VendorServices.shared.isBranded,
					 .sendFeedbackEnabled: (VendorServices.shared.feedbackMailEnabled)
			]
		}

		return nil
	}
}

