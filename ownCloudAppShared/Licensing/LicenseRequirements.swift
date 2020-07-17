//
//  LicenseRequirements.swift
//  ownCloud
//
//  Created by Felix Schwarz on 05.12.19.
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

import UIKit
import ownCloudApp

public struct LicenseRequirements {
	public var feature : OCLicenseFeatureIdentifier

	public func isUnlocked(for core: OCCore) -> Bool {
		return OCLicenseManager.shared.authorizationStatus(forFeature: self.feature, in: core.licenseEnvironment) == .granted
	}

	public init(feature: OCLicenseFeatureIdentifier) {
		self.feature = feature
	}
}
