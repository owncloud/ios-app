//
//  OCIssue+Extension.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 12.03.21.
//  Copyright © 2021 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2021, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import UIKit
import ownCloudSDK

extension Error {
	public var isAuthenticationError : Bool {
		if let issueNSError = self as NSError? {
			return 	issueNSError.isOCError(withCode: .authorizationFailed) ||
			   	issueNSError.isOCError(withCode: .authorizationMethodNotAllowed) ||
			   	issueNSError.isOCError(withCode: .authorizationMethodUnknown) ||
			   	issueNSError.isOCError(withCode: .authorizationNoMethodData) ||
			   	issueNSError.isOCError(withCode: .authorizationNotMatchingRequiredUserID) ||
			   	issueNSError.isOCError(withCode: .authorizationMissingData)
		}

		return false
	}
}

extension OCIssue {
	public var authenticationError : NSError? {
		var nsError : NSError?

		if let issueNSError = self.error as NSError?, issueNSError.isAuthenticationError {
			nsError = issueNSError
		}

		return nsError
	}
}
