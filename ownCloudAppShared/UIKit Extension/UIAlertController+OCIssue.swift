//
//  UIAlertController+OCIssue.swift
//  ownCloud
//
//  Created by Felix Schwarz on 18.06.18.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
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

public extension OCIssueChoice {
	var alertActionStyle : UIAlertAction.Style {
		switch type {
			case .cancel:
				return .cancel

			case .regular, .default:
				return .default

			case .destructive:
				return .destructive
		}
	}
}

public extension UIAlertController {
	convenience init(with issue: OCIssue, completion: (() -> Void)? = nil) {
		self.init(title: issue.localizedTitle, message: issue.localizedDescription, preferredStyle: .alert)

		if let choices = issue.choices {
			for choice in choices {
				self.addAction(UIAlertAction.init(title: choice.label, style: choice.alertActionStyle, handler: { (_) in
					issue.selectChoice(choice)
					completion?()
				}))
			}
		}
	}

	convenience init(with title: String, message: String, cancelLabel: String = OCLocalizedString("Cancel", nil), destructiveLabel: String, preferredStyle: UIAlertController.Style, destructiveAction action: @escaping () -> Void) {

		self.init(title: title, message: message, preferredStyle: preferredStyle)

		let cancelAction = UIAlertAction(title: cancelLabel, style: .cancel, handler: nil)
		let destructiveAction = UIAlertAction(title: destructiveLabel, style: .destructive) { (_) in
			action()
		}

		self.addAction(destructiveAction)
		self.addAction(cancelAction)
	}

	convenience init(with title: String, message: String, okLabel: String = OCLocalizedString("OK", nil), action: (() -> Void)? = nil) {
		self.init(title: title, message: message, preferredStyle: UIDevice.current.isIpad ? .alert : .actionSheet)

		let okAction: UIAlertAction = UIAlertAction(title: okLabel, style: .default, handler: { (_) in
			action?()
		})

		self.addAction(okAction)
	}
}
