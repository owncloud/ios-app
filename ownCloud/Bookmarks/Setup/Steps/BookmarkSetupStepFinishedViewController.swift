//
//  BookmarkSetupStepFinishedViewController.swift
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
import ownCloudSDK

class BookmarkSetupStepFinishedViewController: BookmarkSetupStepViewController {
	var bookmarkNameField: UITextField?

	override func loadView() {
		stepTitle = OCLocalizedString("Account setup complete", nil)

		if setupViewController?.configuration.nameEditable == true {
			stepMessage = OCLocalizedString("If you'd like to give the account a custom name, please enter it below:", nil)
		}

		continueButtonLabelText = OCLocalizedString("Done", nil)

		super.loadView()

		if setupViewController?.configuration.nameEditable == true {
			bookmarkNameField = buildTextField(withAction: UIAction(handler: { [weak self] _ in
				self?.updateName()
			}), placeholder: setupViewController?.composer?.bookmark.shortName ?? "Name", value: setupViewController?.composer?.bookmark.name ?? "", autocorrectionType: .no, autocapitalizationType: .none, accessibilityLabel: OCLocalizedString("Name", nil), borderStyle: .roundedRect)

			contentView = bookmarkNameField
		}
	}

	func updateName() {
		var name = bookmarkNameField?.text

		if name != nil, name?.count == 0 {
			name = nil
		}

		setupViewController?.composer?.setName(name)
	}

	override func handleContinue() {
		let bookmark = setupViewController?.composer?.addBookmark()
		setupViewController?.done(bookmark: bookmark)
	}
}
