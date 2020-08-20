//
//  OCMessage+Extension.swift
//  ownCloud
//
//  Created by Felix Schwarz on 17.06.20.
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

import UIKit
import ownCloudSDK
import ownCloudAppShared

extension OCMessage {
	func showInApp() {
		NotificationCenter.default.post(name: .NotificationMessagePresenterShowMessage, object: self)
	}
}
