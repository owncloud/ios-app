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

	var sortDirection: SortDirection { get set }
	var sortMethod: SortMethod { get set }

	func sortBar(_ sortBar: SortBar, didUpdateSortMethod: SortMethod)
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

	public var sortMethod: SortMethod {
		didSet {
			if self.superview != nil { // Only toggle direction if the view is already in the view hierarchy (i.e. not during initial setup)
				if oldValue == sortMethod {
					if delegate?.sortDirection == .ascendant {
						delegate?.sortDirection = .descendant
					} else {
						delegate?.sortDirection = .ascendant
					}
				} else {
					delegate?.sortDirection = .ascendant // Reset sort direction when switching sort methods
				}
			}
			updateSortButtonTitle()

			sortButton?.accessibilityLabel = NSString(format: "Sort by %@".localized as NSString, sortMethod.localizedName) as String
			sortButton?.sizeToFit()

			delegate?.sortBar(self, didUpdateSortMethod: sortMethod)
		}
	}

	public var itemLayout: ItemLayout = .list {
		didSet {
			switch itemLayout {
				case .grid: changeItemLayoutButton?.setImage(OCSymbol.icon(forSymbolName: "list.bullet"), for: .normal)
				case .list: changeItemLayoutButton?.setImage(OCSymbol.icon(forSymbolName: "square.grid.2x2"), for: .normal)
			}
		}
	}

	// MARK: - Init & Deinit
	public init(frame: CGRect = .zero, sortMethod: SortMethod) {
		selectButton = UIButton()
		changeItemLayoutButton = UIButton()
		sortButton = UIButton(type: .system)

		self.sortMethod = sortMethod

		super.init(frame: frame)
		self.cssSelector = .sortBar

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

						if self?.delegate?.sortMethod == method {
							if self?.delegate?.sortDirection == .ascendant { // Show arrows opposite to the current sort direction to show what choosing them will lead to
								sortDirectionTitle = " ↓"
							} else {
								sortDirectionTitle = " ↑"
							}
						}

						let menuItem = UIAction(title: "\(title)\(sortDirectionTitle)", image: nil, attributes: []) { [weak self] _ in
							self?.sortMethod = method
						}

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
			selectButton.addTarget(self, action: #selector(toggleSelectMode), for: .touchUpInside)
			selectButton.accessibilityLabel = "Enter multiple selection".localized
			selectButton.isPointerInteractionEnabled = true

			NSLayoutConstraint.activate([
				selectButton.centerYAnchor.constraint(equalTo: self.centerYAnchor),
				selectButton.trailingAnchor.constraint(lessThanOrEqualTo: self.safeAreaLayoutGuide.trailingAnchor, constant: -rightSelectButtonPadding),
				selectButton.heightAnchor.constraint(equalToConstant: sideButtonsSize.height),
				selectButton.widthAnchor.constraint(equalToConstant: sideButtonsSize.width)
			])

			// Disply Mode Button
			changeItemLayoutButton.setImage(OCSymbol.icon(forSymbolName: "square.grid.2x2"), for: .normal)
			changeItemLayoutButton.cssSelector = .itemLayout
			changeItemLayoutButton.addTarget(self, action: #selector(toggleDisplayMode), for: .touchUpInside)
			changeItemLayoutButton.accessibilityLabel = "Toggle layout".localized
			changeItemLayoutButton.isPointerInteractionEnabled = true

			NSLayoutConstraint.activate([
				changeItemLayoutButton.centerYAnchor.constraint(equalTo: self.centerYAnchor),
				changeItemLayoutButton.trailingAnchor.constraint(lessThanOrEqualTo: selectButton.leadingAnchor, constant: -rightDisplayModeButtonPadding),
				changeItemLayoutButton.heightAnchor.constraint(equalToConstant: sideButtonsSize.height),
				changeItemLayoutButton.widthAnchor.constraint(equalToConstant: sideButtonsSize.width)
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
		let sortButtonTitle = sortDirectionTitle(sortMethod.localizedName)
		sortButton?.setTitle(sortButtonTitle, for: .normal)
	}

	func sortDirectionTitle(_ title: String) -> String {
		if delegate?.sortDirection == .descendant {
			return String(format: "%@ ↓", title)
		} else {
			return String(format: "%@ ↑", title)
		}
	}

	// MARK: - Actions
	@objc private func toggleSelectMode() {
		delegate?.sortBarToggleSelectMode(self)
	}

	@objc private func toggleDisplayMode() {
		let newItemLayout: ItemLayout = (itemLayout == .grid) ? .list : .grid

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
