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

open class PopupButtonController : NSObject, Themeable {
	typealias TitleCustomizer = (_ choice: PopupButtonChoice, _ isSelected: Bool) -> String
	typealias SelectionCustomizer = (_ choice: PopupButtonChoice, _ isSelected: Bool) -> Bool
	typealias ChoiceHandler = (_ choice: PopupButtonChoice, _ wasSelected: Bool) -> Void
	typealias DynamicChoicesProvider = (_ popupController: PopupButtonController) -> [PopupButtonChoice]

	var button : UIButton

	private var _choices : [PopupButtonChoice]?
	var choices : [PopupButtonChoice]? {
		get {
			if let choicesProvider = choicesProvider {
				return choicesProvider(self)
			}
			return _choices
		}
		set {
			_choices = newValue
		}
	}
	var choicesProvider: DynamicChoicesProvider?
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
	var selectionCustomizer: SelectionCustomizer?
	var choiceHandler: ChoiceHandler?

	var staticTitle: String? {
		didSet {
			_updateTitleFromSelectedChoice()
		}
	}
	var adaptButton: Bool = true

	override init() {
		button = UIButton(type: .system)

		super.init()

		button.translatesAutoresizingMaskIntoConstraints = false

		button.titleLabel?.font = UIFont.preferredFont(forTextStyle: .subheadline)
		button.titleLabel?.adjustsFontForContentSizeCategory = true

		button.setContentHuggingPriority(.required, for: .horizontal)

		button.showsMenuAsPrimaryAction = true

		button.cssSelectors = [.popupButton]
	}

	convenience init(with choices: [PopupButtonChoice], selectedChoice: PopupButtonChoice? = nil, selectFirstChoice: Bool = false, dropDown: Bool = false, staticTitle: String? = nil, titleCustomizer: TitleCustomizer? = nil, selectionCustomizer: SelectionCustomizer? = nil, choiceHandler: ChoiceHandler? = nil) {
		self.init()

		self.choices = choices
		self.selectedChoice = selectedChoice ?? (selectFirstChoice ? choices.first : nil)

		self.titleCustomizer = titleCustomizer
		self.selectionCustomizer = selectionCustomizer
		self.choiceHandler = choiceHandler

		self.staticTitle = staticTitle
		self.isDropDown = dropDown

		button.menu = UIMenu(title: "", children: [
			UIDeferredMenuElement.uncached({ [weak self] completion in
				var menuItems : [UIMenuElement] = []
				guard let choices = self?.choices else {
					completion(menuItems)
					return
				}

				for choice in choices {
					var isSelectedChoice : Bool = (self?.isDropDown == false) ? (self?.selectedChoice == choice) : false
					var title = choice.title

					if let selectionCustomizer = self?.selectionCustomizer {
						isSelectedChoice = selectionCustomizer(choice, isSelectedChoice)
					}

					if let titleCustomizer = self?.titleCustomizer {
						title = titleCustomizer(choice, isSelectedChoice)
					}

					let menuItem = UIAction(title: title, image: choice.image, attributes: [], state: isSelectedChoice ? .on : .off) { [weak self] _ in
						self?.selectedChoice = choice
						self?.choiceHandler?(choice, isSelectedChoice)
					}

					menuItems.append(menuItem)
				}

				completion(menuItems)
			})
		])

		_updateTitleFromSelectedChoice()

		Theme.shared.register(client: self, applyImmediately: true)
	}

	private func _updateTitleFromSelectedChoice() {
		var title = staticTitle

		if let selectedChoice = selectedChoice, !isDropDown {
			if staticTitle == nil {
				title = selectedChoice.buttonTitle ?? selectedChoice.title

				if let titleCustomizer = titleCustomizer {
					title = titleCustomizer(selectedChoice, true)
				}
			}

			if adaptButton {
				if showImageInButton {
					button.setImage(selectedChoice.image, for: .normal)
				}
				button.accessibilityLabel = selectedChoice.buttonAccessibilityLabel
			}
		}

		let chevronAttachment = NSTextAttachment()
		chevronAttachment.image = UIImage(named: "chevron-small-light")?.withRenderingMode(.alwaysTemplate)
		// Alternative using SF Symbols (but too strong IMO): chevronAttachment.image = UIImage(systemName: "chevron.down")?.withRenderingMode(.alwaysTemplate)
		let chevronString = NSAttributedString(attachment: chevronAttachment)

		let attributedTitle = NSMutableAttributedString(string: (title != nil) && showTitleInButton ? " \(title!) " : " ")

		if adaptButton {
			if button.effectiveUserInterfaceLayoutDirection == .leftToRight {
				attributedTitle.append(chevronString)
			} else {
				attributedTitle.insert(chevronString, at: 0)
			}

			button.setAttributedTitle(attributedTitle, for: .normal)
			button.sizeToFit()
		}
	}

	open func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		button.applyThemeCollection(collection)
	}
}
