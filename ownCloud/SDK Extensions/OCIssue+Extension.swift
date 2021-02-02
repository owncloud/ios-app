//
//  OCIssue+Extension.swift
//  ownCloud
//
//  Created by Felix Schwarz on 05.05.18.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
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

import UIKit
import ownCloudSDK

struct DisplayIssues {
	var targetIssue : OCIssue //!< The issue to send the approve or decline message to
	var displayLevel : OCIssueLevel //!< The issue level to be used for display
	var displayIssues: [OCIssue] //!< The selection of issues to be used for display
	var primaryCertificate : OCCertificate? //!< The first certificate found among the issues

	func isAtLeast(level minLevel: OCIssueLevel) -> Bool {
		return displayLevel.rawValue >= minLevel.rawValue
	}
}

extension OCIssue {
	func prepareForDisplay() -> DisplayIssues {
		var displayIssues: [OCIssue] = []
		var primaryCertificate: OCCertificate? = self.certificate

		switch self.type {
			case .group:
				if let filteredIssues = self.issuesWithLevelGreaterThanOrEqual(to: self.level) {
					displayIssues = filteredIssues
				}

				if let issues = self.issues {
					for issue in issues {
						if issue.type == .certificate {
							primaryCertificate = issue.certificate
							break
						}
					}
				}

			case .urlRedirection, .certificate, .error, .generic, .multipleChoice:
				displayIssues = [self]
		}

		return DisplayIssues(targetIssue: self, displayLevel: self.level, displayIssues: displayIssues, primaryCertificate: primaryCertificate)
	}
}
