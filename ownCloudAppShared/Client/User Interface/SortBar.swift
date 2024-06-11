//
//  SortBar.swift
//  ownCloud
//
//  Created by Pablo Carrascal on 31/05/2018.
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

public protocol SortBarDelegate: AnyObject {
	func sortBar(_ sortBar: SortBar, didChangeSortDescriptor: SortDescriptor)
	func sortBar(_ sortBar: SortBar, itemLayout: ItemLayout)
	func sortBarToggleSelectMode(_ sortBar: SortBar)
}

public class SortBar: ThemeCSSView {
	weak public var delegate: SortBarDelegate? {
		didSet {
			updateSortButtonTitle()
		}
	}

	// MARK: - Constants
	let sideButtonsSize: CGSize = CGSize(width: 40.0, height: 40.0)
	let leftPadding: CGFloat = 16.0
	let rightPadding: CGFloat = 20.0
	let rightSelectButtonPadding: CGFloat = 8.0
	let rightDisplayModeButtonPadding: CGFloat = 8.0
	let topPadding: CGFloat = 10.0
	let bottomPadding: CGFloat = 10.0

	// MARK: - Instance variables.
	public var sortButton: UIButton?
	public var selectButton: UIButton?
	public var changeItemLayoutButton: UIButton?
	public var allowMultiSelect: Bool = true {
		didSet {
			updateSelectButtonVisibility()
		}
	}
	public var multiselectActive: Bool = false {
		didSet {
			selectButton?.accessibilityLabel = multiselectActive ? "Exit multiple selection".localized : "Enter multiple selection".localized
		}
	}
	public var showSelectButton: Bool = false {
		didSet {
			updateSelectButtonVisibility()
		}
	}

	private func updateSelectButtonVisibility() {
		let showButton = showSelectButton && allowMultiSelect

		selectButton?.isHidden = !showButton
		selectButton?.accessibilityElementsHidden = !showButton
		selectButton?.isEnabled = showButton

		UIAccessibility.post(notification: .layoutChanged, argument: nil)
	}

	public var sortDescriptor: SortDescriptor {
		didSet {
			updateSortButtonTitle()
		}
	}

	func userSelectedSortMethod(_ newSortMethod: SortMethod) {
		var sortDirection = sortDescriptor.direction

		if self.superview != nil { // Only toggle direction if the view is already in the view hierarchy (i.e. not during initial setup)
			if sortDescriptor.method == newSortMethod {
				if sortDirection == .ascending {
					sortDirection = .descending
				} else {
					sortDirection = .ascending
				}
			} else {
				sortDirection = .ascending // Reset sort direction when switching sort methods
			}
		}

		sortDescriptor = SortDescriptor(method: newSortMethod, direction: sortDirection)

		delegate?.sortBar(self, didChangeSortDescriptor: sortDescriptor)
	}

	public var itemLayout: ItemLayout = .list {
		didSet {
			let (_, icon) = itemLayout.labelAndIcon()
			changeItemLayoutButton?.setImage(icon, for: .normal)
		}
	}

	// MARK: - Init & Deinit
	public init(frame: CGRect = .zero, sortDescriptor: SortDescriptor) {
		selectButton = UIButton()
		changeItemLayoutButton = UIButton(type: .system)
		sortButton = UIButton(type: .system)

		self.sortDescriptor = sortDescriptor

		super.init(frame: frame)
		self.cssSelector = .sortBar

		let focusGuide = UIFocusGuide()

		if let sortButton, let selectButton, let changeItemLayoutButton {
			sortButton.translatesAutoresizingMaskIntoConstraints = false
			selectButton.translatesAutoresizingMaskIntoConstraints = false
			changeItemLayoutButton.translatesAutoresizingMaskIntoConstraints = false

			sortButton.accessibilityIdentifier = "sort-bar.sortButton"

			self.addSubview(sortButton)
			self.addSubview(selectButton)
			self.addSubview(changeItemLayoutButton)

			// Sort Button
			sortButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .subheadline)
			sortButton.titleLabel?.adjustsFontForContentSizeCategory = true
			sortButton.cssSelector = .sorting
			sortButton.semanticContentAttribute = (sortButton.effectiveUserInterfaceLayoutDirection == .leftToRight) ? .forceRightToLeft : .forceLeftToRight
			sortButton.setImage(UIImage(named: "chevron-small-light"), for: .normal)
			sortButton.setContentHuggingPriority(.required, for: .horizontal)
			sortButton.showsMenuAsPrimaryAction = true
			sortButton.menu = UIMenu(title: "", children: [
				UIDeferredMenuElement.uncached({ [weak self] completion in
					var menuItems : [UIMenuElement] = []

					for method in SortMethod.all {
						let title = method.localizedName
						var sortDirectionTitle = ""
						var sortDirectionLabel = ""

						if let sortDescriptor = self?.sortDescriptor {
							if sortDescriptor.method == method {
								// Show arrows and labels opposite to the current sort direction to show what choosing them will lead to
								sortDirectionTitle = sortDescriptor.direction == .ascending ? " ↓" : " ↑"
								sortDirectionLabel = sortDescriptor.direction == .ascending ? "descending".localized : "ascending".localized
							} else {
								sortDirectionLabel = sortDescriptor.direction == .ascending ? "ascending".localized : "descending".localized
							}
						}

						let menuItem = UIAction(title: "\(title)\(sortDirectionTitle)", image: nil, attributes: []) { [weak self] _ in
							self?.userSelectedSortMethod(method)
						}

						menuItem.accessibilityLabel = "{{attribute}} {{direction}}".localized([
							"attribute" : method.localizedName,
							"direction" : sortDirectionLabel
						])

						menuItems.append(menuItem)
					}

					completion(menuItems)
				})
			])

			NSLayoutConstraint.activate([
				sortButton.topAnchor.constraint(equalTo: self.topAnchor, constant: topPadding),
				sortButton.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -bottomPadding),
				sortButton.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: leftPadding),
				sortButton.trailingAnchor.constraint(lessThanOrEqualTo: self.trailingAnchor, constant: -rightPadding)
			])

			// Select Button
			selectButton.setImage(UIImage(named: "select"), for: .normal)
			selectButton.cssSelector = .multiselect
			selectButton.addTarget(self, action: #selector(toggleSelectMode), for: .primaryActionTriggered)
			selectButton.accessibilityLabel = multiselectActive ? "Exit multiple selection".localized : "Enter multiple selection".localized
			selectButton.isPointerInteractionEnabled = true

			NSLayoutConstraint.activate([
				selectButton.centerYAnchor.constraint(equalTo: self.centerYAnchor),
				selectButton.trailingAnchor.constraint(lessThanOrEqualTo: self.safeAreaLayoutGuide.trailingAnchor, constant: -rightSelectButtonPadding),
				selectButton.heightAnchor.constraint(equalToConstant: sideButtonsSize.height),
				selectButton.widthAnchor.constraint(equalToConstant: sideButtonsSize.width)
			])

			// Display Mode Button
			changeItemLayoutButton.cssSelector = .itemLayout
			changeItemLayoutButton.accessibilityLabel = "Toggle layout".localized
			changeItemLayoutButton.isPointerInteractionEnabled = true
			changeItemLayoutButton.showsMenuAsPrimaryAction = true
			changeItemLayoutButton.menu = UIMenu(title: "", children: [
				UIDeferredMenuElement.uncached({ [weak self] completion in
					var menuItems : [UIMenuElement] = []

					for itemLayout in ItemLayout.allCases {
						let (title, icon) = itemLayout.labelAndIcon()

						let menuItem = UIAction(title: "\(title)", image: icon, attributes: []) { [weak self] _ in
							self?.switchItemLayout(to: itemLayout)
						}

						menuItems.append(menuItem)
					}

					completion(menuItems)
				})
			])

			NSLayoutConstraint.activate([
				changeItemLayoutButton.centerYAnchor.constraint(equalTo: self.centerYAnchor),
				changeItemLayoutButton.trailingAnchor.constraint(lessThanOrEqualTo: selectButton.leadingAnchor, constant: -rightDisplayModeButtonPadding),
				changeItemLayoutButton.heightAnchor.constraint(equalToConstant: sideButtonsSize.height),
				changeItemLayoutButton.widthAnchor.constraint(equalToConstant: sideButtonsSize.width)
			])

			self.accessibilityRespondsToUserInteraction = false

			sortButton.focusGroupIdentifier = "com.owncloud.sort-button"
			selectButton.focusGroupIdentifier = "com.owncloud.select-button"
			changeItemLayoutButton.focusGroupIdentifier = "com.owncloud.change-item-layout-button"

			focusGuide.preferredFocusEnvironments = [ sortButton, selectButton, changeItemLayoutButton ]
			addLayoutGuide(focusGuide)

			NSLayoutConstraint.activate([
				leadingAnchor.constraint(equalTo: focusGuide.leadingAnchor),
				trailingAnchor.constraint(equalTo: focusGuide.trailingAnchor),
				topAnchor.constraint(equalTo: focusGuide.topAnchor),
				bottomAnchor.constraint(equalTo: focusGuide.bottomAnchor)
			])
		}

		// Finalize view setup
		self.accessibilityIdentifier = "sort-bar"

		selectButton?.isHidden = !showSelectButton
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	// MARK: - Theme support
	public override func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		self.sortButton?.apply(css: collection.css, properties: [.stroke])
		self.selectButton?.apply(css: collection.css, properties: [.stroke])
		self.changeItemLayoutButton?.apply(css: collection.css, properties: [.stroke])

		super.applyThemeCollection(theme: theme, collection: collection, event: event)
	}

	// MARK: - Sort Direction Title
	func updateSortButtonTitle() {
		let method = sortDescriptor.method
		let sortButtonTitle = sortDirectionTitle(method.localizedName)
		sortButton?.setTitle(sortButtonTitle, for: .normal)
		sortButton?.accessibilityLabel = "Sort by {{attribute}} in {{direction}} order".localized([
			"attribute" : method.localizedName,
			"direction" : (sortDescriptor.direction == .ascending) ? "ascending".localized : "descending".localized
		])
		sortButton?.sizeToFit()
	}

	func sortDirectionTitle(_ title: String) -> String {
		if sortDescriptor.direction == .descending {
			return String(format: "%@ ↓", title)
		} else {
			return String(format: "%@ ↑", title)
		}
	}

	// MARK: - Actions
	@objc private func toggleSelectMode() {
		delegate?.sortBarToggleSelectMode(self)
	}

	private func switchItemLayout(to newItemLayout: ItemLayout) {
		itemLayout = newItemLayout
		delegate?.sortBar(self, itemLayout: newItemLayout)
	}
}

public extension ThemeCSSSelector {
	static let sortBar = ThemeCSSSelector(rawValue: "sortBar")
	static let multiselect = ThemeCSSSelector(rawValue: "multiselect")
	static let itemLayout = ThemeCSSSelector(rawValue: "itemLayout")
	static let sorting = ThemeCSSSelector(rawValue: "sorting")
}
