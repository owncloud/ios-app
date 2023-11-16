//
//  ThemeCSSTextField.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 27.03.23.
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

public extension UITextInput {
	func range(from textRange: UITextRange) -> NSRange {
		let startOffset = offset(from: beginningOfDocument, to: textRange.start)
		let endOffset = offset(from: beginningOfDocument, to: textRange.end)

		return NSRange(location: startOffset, length: endOffset-startOffset+1)
	}
}

public class ThemeCSSTextField: UITextField, Themeable {
	private var hasRegistered : Bool = false

	open var requiredFileExtension: String?

	override open func didMoveToWindow() {
		super.didMoveToWindow()

		if window != nil, !hasRegistered {
			hasRegistered = true
			Theme.shared.register(client: self, applyImmediately: true)
		}
	}

	override open var isEnabled: Bool {
		didSet {
			if hasRegistered {
				applyThemeCollection(theme: Theme.shared, collection: Theme.shared.activeCollection, event: .update)
			}
		}
	}

	open func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		self.applyThemeCollection(collection)
	}

	public override func shouldChangeText(in range: UITextRange, replacementText: String) -> Bool {
		if let requiredFileExtension, let previousText = text,
		   let textRange = Range(self.range(from: range), in: previousText) {
			let newName = previousText.replacingCharacters(in: textRange, with: replacementText)
			return (newName as NSString).pathExtension == requiredFileExtension || (newName == ".\(requiredFileExtension)")
		}

		return super.shouldChangeText(in: range, replacementText: replacementText)
	}

	public override var selectedTextRange: UITextRange? {
		didSet {
			if let requiredFileExtension {
				if let selectedTextRange,
				   let maxAllowedPosition = position(from: endOfDocument, offset: -requiredFileExtension.count-1),
				   compare(selectedTextRange.end, to: maxAllowedPosition) == .orderedDescending {
					self.selectedTextRange = textRange(from: selectedTextRange.start, to: maxAllowedPosition)
				}
			}
		}
	}
}
