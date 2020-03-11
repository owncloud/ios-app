//
//  OCLogLevel+Extension.swift
//  ownCloudAppShared
//
//  Created by Matthias Hühne on 10.03.20.
//  Copyright © 2020 ownCloud GmbH. All rights reserved.
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

import ownCloudSDK

extension OCLogLevel {
	public var label : String {
		switch self {
			case .debug:
				return "Debug".localized
			case .info:
				return "Info".localized
			case .warning:
				return "Warning".localized
			case .error:
				return "Error".localized
			case .off:
				return "Off".localized
		}
	}
}
