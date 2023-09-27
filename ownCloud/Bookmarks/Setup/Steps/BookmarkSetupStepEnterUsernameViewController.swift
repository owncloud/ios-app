//
//  BookmarkSetupStepEnterUsernameViewController.swift
//  ownCloud
//
//  Created by Felix Schwarz on 06.09.23.
//  Copyright © 2023 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2023, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import UIKit

class BookmarkSetupStepEnterUsernameViewController: BookmarkSetupStepViewController {
	var usernameField: UITextField?

	override func loadView() {
		stepTitle = "Username".localized

		super.loadView()

		usernameField = buildTextField(withAction: UIAction(handler: { [weak self] _ in
			self?.updateState()
		}), autocorrectionType: .no, autocapitalizationType: .none, accessibilityLabel: "Username".localized, borderStyle: .roundedRect)
		usernameField?.textContentType = .username

		focusTextFields = [ usernameField! ]

		contentView = usernameField

		updateState()
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		usernameField?.becomeFirstResponder()
	}

	func updateState() {
		if let username = usernameField?.text, username.count > 0 {
			continueButton.isEnabled = true
		} else {
			continueButton.isEnabled = false
		}
	}

	override func handleContinue() {
		if let username = usernameField?.text {
			setupViewController?.composer?.enterUsername(username, completion: composerCompletion)
		}
	}
}
