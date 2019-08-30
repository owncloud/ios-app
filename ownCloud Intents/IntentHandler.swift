//
//  IntentHandler.swift
//  SiriKit
//
//  Created by Matthias Hühne on 23.07.19.
//  Copyright © 2019 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2019, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import Intents
import ownCloudAppShared

class IntentHandler: INExtension {

	override func handler(for intent: INIntent) -> Any {
		if intent is GetAccountsIntent {
			return GetAccountsIntentHandler()
		} else if intent is GetDirectoryListingIntent {
			return GetDirectoryListingIntentHandler()
		} else if intent is GetFileIntent {
			return GetFileIntentHandler()
		} else if intent is SaveFileIntent {
			return SaveFileIntentHandler()
		} else if intent is CreateFolderIntent {
			return CreateFolderIntentHandler()
		} else if intent is GetFileInfoIntent {
			return GetFileInfoIntentHandler()
		} else if intent is PathExistsIntent {
			return PathExistsIntentHandler()
		}

		fatalError("Unhandled intent type: \(intent)")
    }
}
