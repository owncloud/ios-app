//
//  UIView+OCDataItem.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 31.05.22.
//  Copyright © 2022 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2022, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import UIKit
import ownCloudSDK

extension UIView : OCDataItem, OCDataItemVersioning {
	public var dataItemType: OCDataItemType {
		return .view
	}

	public var dataItemReference: OCDataItemReference {
		return NSString(format: "%p", self)
	}

	public var dataItemVersion: OCDataItemVersion {
		return NSString(format: "%p", self)
	}
}
