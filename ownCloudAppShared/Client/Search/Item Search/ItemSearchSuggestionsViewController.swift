//
//  ItemSearchSuggestionsViewController.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 08.09.22.
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
import ownCloudSDK
import ownCloudApp

extension OCQueryCondition {
	func matchesWith(anyOf searchElements: [SearchElement]) -> Bool {
		return searchElements.contains(where: { element in element.isEquivalent(to: self) })
	}
}

class ItemSearchSuggestionsViewController: UIViewController, SearchElementUpdating {
	class Category {
		typealias SelectionBehaviour = (_ deselectOption: OCQueryCondition, _ whenOption: OCQueryCondition, _ isSelected: Bool) -> Bool

		static let mutuallyExclusiveSelectionBehaviour : SelectionBehaviour = { (deselectOption, whenOption, isSelected) in
			if isSelected, !deselectOption.isEquivalent(to: whenOption) {
				return true
			}

			return false
		}

		var name: String
		var selectionBehaviour: SelectionBehaviour
		var options: [OCQueryCondition]

		var popupController: PopupButtonController?

		init(name: String, selectionBehaviour: @escaping SelectionBehaviour, options: [OCQueryCondition]) {
			self.name = name
			self.selectionBehaviour = selectionBehaviour
			self.options = options
		}

		func shouldDeselect(option optionCondition: OCQueryCondition, when otherOptionCondition: OCQueryCondition, isSelected: Bool) -> Bool {
			return selectionBehaviour(optionCondition, otherOptionCondition, isSelected)
		}
	}

	var categories: [Category] = [
		Category(name: "Type".localized, selectionBehaviour: Category.mutuallyExclusiveSelectionBehaviour, options: [
			OCQueryCondition.fromSearchTerm(":file")!,
			OCQueryCondition.fromSearchTerm(":folder")!,
			OCQueryCondition.fromSearchTerm(":document")!,
			OCQueryCondition.fromSearchTerm(":spreadsheet")!,
			OCQueryCondition.fromSearchTerm(":presentation")!,
			OCQueryCondition.fromSearchTerm(":pdf")!,
			OCQueryCondition.fromSearchTerm(":image")!,
			OCQueryCondition.fromSearchTerm(":video")!,
			OCQueryCondition.fromSearchTerm(":audio")!
		]),
		Category(name: "Date".localized, selectionBehaviour: Category.mutuallyExclusiveSelectionBehaviour, options: [
			OCQueryCondition.fromSearchTerm(":today")!,
			OCQueryCondition.fromSearchTerm(":week")!,
			OCQueryCondition.fromSearchTerm(":month")!,
			OCQueryCondition.fromSearchTerm(":year")!
		]),
		Category(name: "Size".localized, selectionBehaviour: Category.mutuallyExclusiveSelectionBehaviour, options: [
			OCQueryCondition.fromSearchTerm("smaller:10mb")!,
			OCQueryCondition.fromSearchTerm("greater:10mb")!,
			OCQueryCondition.fromSearchTerm("smaller:100mb")!,
			OCQueryCondition.fromSearchTerm("greater:100mb")!,
			OCQueryCondition.fromSearchTerm("smaller:500mb")!,
			OCQueryCondition.fromSearchTerm("greater:500mb")!,
			OCQueryCondition.fromSearchTerm("smaller:1gb")!,
			OCQueryCondition.fromSearchTerm("greater:1gb")!
		])
	]

	var stackView : UIStackView?
	private var rootView : UIView?

	weak var scope: SearchScope?

	var categoryActiveButtonConfig : UIButton.Configuration?
	var categoryUnusedButtonConfig : UIButton.Configuration?

	init(with scope: SearchScope) {
		super.init(nibName: nil, bundle: nil)
		self.scope = scope
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	func requestName(title: String, message: String? = nil, placeholder: String? = nil, cancelButtonText: String? = "Cancel".localized, saveButtonText: String? = "Save".localized, completionHandler: @escaping (_ save: Bool, _ name: String?) -> Void) {
		let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: saveButtonText, style: .default, handler: { [weak alert] _ in
			var text = alert?.textFields?.first?.text
			if text?.count == 0 { text = nil }
			completionHandler(true, text)
		}))
		alert.addAction(UIAlertAction(title: cancelButtonText, style: .cancel, handler: { _ in
			completionHandler(false, nil)
		}))
		alert.addTextField(configurationHandler: { textField in
			textField.placeholder = placeholder
		})

		self.present(alert, animated: true)
	}

	override func loadView() {
		// Stack view
		stackView = UIStackView(frame: .zero)
		stackView?.translatesAutoresizingMaskIntoConstraints = false
		stackView?.axis = .horizontal
		stackView?.distribution = .equalSpacing
		stackView?.spacing = 0

		// Saved search popup
		savedSearchPopup = PopupButtonController(with: [], selectFirstChoice: false, dropDown: true, choiceHandler: { [weak self] choice, wasSelected in
			if let scope = self?.scope, let command = choice.representedObject as? String {
				switch command {
					case "save-search":
						if let savedSearch = scope.savedSearch as? OCSavedSearch, let vault = scope.clientContext.core?.vault {
							OnMainThread {
								self?.requestName(title: "Name of search", placeholder: savedSearch.name, completionHandler: { save, name in
									if save {
										if let name = name {
											savedSearch.name = name
										}
										vault.add(savedSearch)
									}
								})
							}
						}
					case "save-template":
						if let savedSearch = scope.savedTemplate as? OCSavedSearch, let vault = scope.clientContext.core?.vault {
							OnMainThread {
								self?.requestName(title: "Name of template", placeholder: savedSearch.name, completionHandler: { save, name in
									if save {
										if let name = name {
											savedSearch.name = name
										}
										vault.add(savedSearch)
									}
								})
							}
						}

					default: break
				}
			} else if let savedSearch = choice.representedObject as? OCSavedSearch {
				self?.restore(savedSearch: savedSearch)
			}
		})
		savedSearchPopup?.choicesProvider = { [weak self] (_ popupController: PopupButtonController) in
			var choices: [PopupButtonChoice] = []

			if (self?.scope as? ItemSearchScope)?.canSaveSearch == true {
				let saveSearchChoice = PopupButtonChoice(with: "Save as smart folder".localized, image: UIImage(systemName: "folder.badge.gearshape")?.withRenderingMode(.alwaysTemplate), representedObject: NSString("save-search"))
				choices.append(saveSearchChoice)
			}

			if (self?.scope as? ItemSearchScope)?.canSaveTemplate == true {
				let saveTemplateChoice = PopupButtonChoice(with: "Save template".localized, image: UIImage(systemName: "plus.square.dashed")?.withRenderingMode(.alwaysTemplate), representedObject: NSString("save-template"))
				choices.append(saveTemplateChoice)
			}

			if let vault = self?.scope?.clientContext.core?.vault, let savedSearches = vault.savedSearches {
				for savedSearch in savedSearches {
					if savedSearch.isTemplate {
						choices.append(PopupButtonChoice(with: savedSearch.name, image: UIImage(systemName: "square.dashed.inset.filled")?.withRenderingMode(.alwaysTemplate), representedObject: savedSearch))
					}
				}
			}

			return choices
		}

		var buttonConfiguration = UIButton.Configuration.plain().updated(for: savedSearchPopup!.button)
		buttonConfiguration.image = UIImage(systemName: "ellipsis.circle")?.withRenderingMode(.alwaysTemplate)
		buttonConfiguration.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 5, bottom: 10, trailing: 5)
		buttonConfiguration.attributedTitle = nil
		savedSearchPopup?.adaptButton = false
		savedSearchPopup?.button.setAttributedTitle(nil, for: .normal)
		savedSearchPopup?.button.configuration = buttonConfiguration

		rootView = UIView()
		rootView?.translatesAutoresizingMaskIntoConstraints = false

		rootView?.addSubview(stackView!)
		rootView?.addSubview(savedSearchPopup!.button)

		guard let stackView = stackView, let rootView = rootView, let savedSearchPopupButton = savedSearchPopup?.button else { return }

		NSLayoutConstraint.activate([
			stackView.leadingAnchor.constraint(equalTo: rootView.leadingAnchor),
			stackView.trailingAnchor.constraint(lessThanOrEqualTo: savedSearchPopupButton.leadingAnchor),
			stackView.topAnchor.constraint(equalTo: rootView.topAnchor),
			stackView.bottomAnchor.constraint(equalTo: rootView.bottomAnchor),

			savedSearchPopupButton.topAnchor.constraint(equalTo: rootView.topAnchor),
			savedSearchPopupButton.bottomAnchor.constraint(equalTo: rootView.bottomAnchor),
			savedSearchPopupButton.trailingAnchor.constraint(equalTo: rootView.trailingAnchor)
		])

		view = rootView
	}

	override func viewDidLoad() {
		categoryActiveButtonConfig = UIButton.Configuration.borderedTinted()
		categoryActiveButtonConfig?.contentInsets.leading = 0
		categoryActiveButtonConfig?.contentInsets.trailing = 3

		categoryUnusedButtonConfig = UIButton.Configuration.borderless()
		categoryUnusedButtonConfig?.contentInsets.leading = 0
		categoryUnusedButtonConfig?.contentInsets.trailing = 3

		createPopups()

		for category in categories {
			if let button = category.popupController?.button {
				stackView?.addArrangedSubview(button)
			}
		}
	}

	var savedSearchPopup: PopupButtonController?

	func createPopups() {
		// Create popups for all categories
		for category in categories {
			var choices : [PopupButtonChoice] = []

			for queryCondition in category.options {
				if let localizedDescription = queryCondition.localizedDescription {
					let image : UIImage? = (queryCondition.symbolName != nil) ? UIImage(systemName: queryCondition.symbolName!)?.withRenderingMode(.alwaysTemplate) : nil
					let choice = PopupButtonChoice(with: localizedDescription, image: image, representedObject: queryCondition)
					choices.append(choice)
				}
			}

			let popupController = PopupButtonController(with: choices, dropDown: true, staticTitle: category.name, selectionCustomizer: { [weak self] (choice, isSelected) in
				if let queryCondition = choice.representedObject as? OCQueryCondition, let searchElements = self?.searchElements {
					return queryCondition.matchesWith(anyOf: searchElements)
				}
				return isSelected
			}, choiceHandler: { [weak self, weak category] (choice, wasSelected) in
				if let category = category, let queryCondition = choice.representedObject as? OCQueryCondition {
					self?.handleSelection(of: queryCondition, in: category, wasSelected: wasSelected)
				}
			})

			let button = popupController.button
			button.addConstraint(button.heightAnchor.constraint(equalToConstant: 25))

			category.popupController = popupController
		}
	}

	var searchElements: [SearchElement] = []

	func handleSelection(of selectedOptionCondition: OCQueryCondition, in category: Category, wasSelected: Bool) {
		var removeOptionConditions : [OCQueryCondition] = []
		var addOptionConditions : [OCQueryCondition] = []

		// Determine whether / if any other options should be removed (f.ex. to implement mutually exclusive choices)
		for option in category.options {
			if category.shouldDeselect(option: option, when: selectedOptionCondition, isSelected: !wasSelected) {
				removeOptionConditions.append(option)
			}
		}

		if !wasSelected {
			// Option was freshly selected
			addOptionConditions.append(selectedOptionCondition)
		} else {
			// Option was deselected
			removeOptionConditions.append(selectedOptionCondition)
		}

		for removeOptionToken in removeOptionConditions {
			scope?.tokenizer?.remove(elementEquivalentTo: removeOptionToken)
		}

		for addOptionToken in addOptionConditions {
			if let searchToken = addOptionToken.generateSearchToken(fallbackText: "", inputComplete: true) {
				scope?.tokenizer?.add(element: searchToken)
			}
		}
	}

	func restore(savedSearch: OCSavedSearch) {
		scope?.searchViewController?.restore(savedTemplate: savedSearch)
	}

	func updateFor(_ searchElements: [SearchElement]) {
		self.searchElements = searchElements

		for category in categories {
			var categoryHasMatch: Bool = false

			for optionCondition in category.options {
				if optionCondition.matchesWith(anyOf: searchElements) {
					categoryHasMatch = true
					break
				}
			}

			if let categoryPopupButton = category.popupController?.button {
				var buttonConfig : UIButton.Configuration?

				if categoryHasMatch {
					buttonConfig = categoryActiveButtonConfig?.updated(for: categoryPopupButton)
				} else {
					buttonConfig = categoryUnusedButtonConfig?.updated(for: categoryPopupButton)
				}

				if let attributedTitle = categoryPopupButton.currentAttributedTitle {
					buttonConfig?.attributedTitle = AttributedString(attributedTitle)
				}
				categoryPopupButton.configuration = buttonConfig
			}

			category.popupController?.button.sizeToFit()
		}
	}
}
