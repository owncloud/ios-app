//
//  UIButton+PopupButton.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 25.08.22.
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

open class PopupButtonChoice : NSObject {
	var image: UIImage?

	var title: String
	var buttonTitle: String?
	var buttonAccessibilityLabel: String?

	var representedObject: AnyObject?

	init(with title: String, image: UIImage?, buttonTitle: String? = nil, buttonAccessibilityLabel: String? = nil, representedObject: AnyObject? = nil) {
		self.title = title
		super.init()

		self.image = image
		self.buttonTitle = buttonTitle
		self.buttonAccessibilityLabel = buttonAccessibilityLabel
		self.representedObject = representedObject
	}
}

open class PopupButtonController : NSObject {
	typealias TitleCustomizer = (_ choice: PopupButtonChoice, _ isSelected: Bool) -> String
	typealias ChoiceHandler = (_ choice: PopupButtonChoice) -> Void

	var button : UIButton

	var choices : [PopupButtonChoice]?
	var selectedChoice : PopupButtonChoice? {
		didSet {
			_updateTitleFromSelectedChoice()
		}
	}
	var isDropDown : Bool = true
	var showTitleInButton: Bool = true {
		didSet {
			_updateTitleFromSelectedChoice()
		}
	}
	var showImageInButton: Bool = true {
		didSet {
			_updateTitleFromSelectedChoice()
		}
	}

	var titleCustomizer: TitleCustomizer?
	var choiceHandler: ChoiceHandler?

	override init() {
		button = UIButton(type: .system)

		super.init()

		button.translatesAutoresizingMaskIntoConstraints = false

		button.titleLabel?.font = UIFont.preferredFont(forTextStyle: .subheadline)
		button.titleLabel?.adjustsFontForContentSizeCategory = true

		button.setContentHuggingPriority(.required, for: .horizontal)

		button.showsMenuAsPrimaryAction = true
	}

	convenience init(with choices: [PopupButtonChoice], selectedChoice: PopupButtonChoice?, titleCustomizer: TitleCustomizer? = nil, dropDown: Bool = false, title: String? = nil, choiceHandler: ChoiceHandler? = nil) {
		self.init()

		self.choices = choices
		self.selectedChoice = selectedChoice ?? choices.first
		self.titleCustomizer = titleCustomizer
		self.choiceHandler = choiceHandler

		self.isDropDown = dropDown

		if let title = title {
			button.setTitle(title, for: .normal)
		} else {
			_updateTitleFromSelectedChoice()
		}

		button.menu = UIMenu(title: "", children: [
			UIDeferredMenuElement.uncached({ [weak self] completion in
				var menuItems : [UIMenuElement] = []
				guard let choices = self?.choices else {
					completion(menuItems)
					return
				}

				for choice in choices {
					let isSelectedChoice : Bool = (self?.isDropDown == false) ? (self?.selectedChoice == choice) : false

					var title = choice.title

					if let titleCustomizer = self?.titleCustomizer {
						title = titleCustomizer(choice, isSelectedChoice)
					}

					let menuItem = UIAction(title: title, image: choice.image, attributes: [], state: isSelectedChoice ? .on : .off) { [weak self] _ in
						self?.selectedChoice = choice
						self?.choiceHandler?(choice)
					}

					menuItems.append(menuItem)
				}

				completion(menuItems)
			})
		])
	}

	private func _updateTitleFromSelectedChoice() {
		if let selectedChoice = selectedChoice, !isDropDown {
			var title : String? = selectedChoice.buttonTitle ?? selectedChoice.title

			if let titleCustomizer = titleCustomizer {
				title = titleCustomizer(selectedChoice, true)
			}

			let chevronAttachment = NSTextAttachment()
			chevronAttachment.image = UIImage(named: "chevron-small-light")?.withRenderingMode(.alwaysTemplate)
			// Alternative using SF Symbols (but too strong IMO): chevronAttachment.image = UIImage(systemName: "chevron.down")?.withRenderingMode(.alwaysTemplate)
			let chevronString = NSAttributedString(attachment: chevronAttachment)

			let attributedTitle = NSMutableAttributedString(string: (title != nil) && showTitleInButton ? " \(title!) " : " ")

			if button.effectiveUserInterfaceLayoutDirection == .leftToRight {
				attributedTitle.append(chevronString)
			} else {
				attributedTitle.insert(chevronString, at: 0)
			}

			button.setAttributedTitle(attributedTitle, for: .normal)
			if showImageInButton {
				button.setImage(selectedChoice.image, for: .normal)
			}
			button.accessibilityLabel = selectedChoice.buttonAccessibilityLabel
			button.sizeToFit()
		}
	}
}
