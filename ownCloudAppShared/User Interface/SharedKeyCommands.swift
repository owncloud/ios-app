//
//  SharedKeyCommands.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 29.03.23.
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

extension PasscodeViewController {
	// Moved over from KeyCommands.swift to be usable across app and extensions
	public override var keyCommands: [UIKeyCommand]? {
		var keyCommands : [UIKeyCommand] = []
		for i in 0 ..< 10 {
			keyCommands.append(
				UIKeyCommand.ported(input:String(i),
						    modifierFlags: [],
						    action: #selector(self.performKeyCommand(sender:)),
						    discoverabilityTitle: String(i))
			)
		}

		keyCommands.append(
			UIKeyCommand.ported(input: "\u{8}",
					    modifierFlags: [],
					    action: #selector(self.performKeyCommand(sender:)),
					    discoverabilityTitle: OCLocalizedString("Delete", nil))
		)

		if cancelButton?.isHidden == false {
			keyCommands.append(

				UIKeyCommand.ported(input: UIKeyCommand.inputEscape,
						    modifierFlags: [],
						    action: #selector(self.performKeyCommand(sender:)),
						    discoverabilityTitle: OCLocalizedString("Cancel", nil))
			)
		}

		return keyCommands
	}

	override open var canBecomeFirstResponder: Bool {
		return true
	}

	@objc func performKeyCommand(sender: UIKeyCommand) {
		guard let key = sender.input else {
			return
		}

		switch key {
			case "\u{8}":
				deleteLastDigit()
			case UIKeyCommand.inputEscape:
				cancelHandler?(self)
			default:
				appendDigit(digit: key)
		}

	}
}
