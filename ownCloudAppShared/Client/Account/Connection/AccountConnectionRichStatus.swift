//
//  AccountConnectionRichStatus.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 18.11.22.
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

public class AccountConnectionRichStatus: NSObject {
	public enum Kind {
		case status
		case error
	}

	public typealias Interaction = (_ viewControllerToPresentOn: UIViewController) -> Void

	public var kind: Kind

	public var icon: UIImage?
	public var text: String?
	public var progress: Progress?
	public var progressSummary: ProgressSummary?

	public var status: AccountConnection.Status?

	public var interaction: Interaction?
	public var interactionLabel: String?

	init(kind: Kind, icon: UIImage? = nil, text: String? = nil, progress: Progress? = nil, progressSummary: ProgressSummary? = nil, status: AccountConnection.Status? = nil, interaction: Interaction? = nil, interactionLabel: String? = nil) {
		self.kind = kind
		self.icon = icon
		self.text = text
		self.progress = progress
		self.progressSummary = progressSummary
		self.status = status
		self.interaction = interaction

		if text == nil, let progress = progress, let localizedProgressDescription = progress.localizedDescription {
			self.text = localizedProgressDescription
		}

		if let progressSummary = progressSummary {
			if text == nil, let message = progressSummary.message {
				self.text = message
			}

			if progress == nil {
				if progressSummary.indeterminate {
					self.progress = .indeterminate()
				} else if progressSummary.progressCount > 0 {
					let percentageProgress = Progress()
					percentageProgress.totalUnitCount = 100
					percentageProgress.completedUnitCount = Int64(progressSummary.progress * 100)
					self.progress = percentageProgress
				}
			}
		}
	}
}
