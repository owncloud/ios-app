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

public protocol SortBarDelegate: AnyObject {

	var sortDirection: SortDirection { get set }
	var sortMethod: SortMethod { get set }

	func sortBar(_ sortBar: SortBar, didUpdateSortMethod: SortMethod)

	func sortBar(_ sortBar: SortBar, presentViewController: UIViewController, animated: Bool, completionHandler: (() -> Void)?)

	func toggleSelectMode()
}

public class SortBar: UIView, Themeable, UIPopoverPresentationControllerDelegate {

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
	let rightSearchScopePadding: CGFloat = 15.0
	let topPadding: CGFloat = 10.0
	let bottomPadding: CGFloat = 10.0

	// MARK: - Instance variables.
	public var sortButton: UIButton?
	public var selectButton: UIButton?
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

	// MARK: - Init & Deinit
	public init(frame: CGRect = .zero, sortMethod: SortMethod) {
		selectButton = UIButton()
		sortButton = UIButton(type: .system)

		self.sortMethod = sortMethod

		super.init(frame: frame)

		if let sortButton, let selectButton {
			sortButton.translatesAutoresizingMaskIntoConstraints = false
			selectButton.translatesAutoresizingMaskIntoConstraints = false

			sortButton.accessibilityIdentifier = "sort-bar.sortButton"

			self.addSubview(sortButton)
			self.addSubview(selectButton)

			// Sort Button
			sortButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .subheadline)
			sortButton.titleLabel?.adjustsFontForContentSizeCategory = true
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

			selectButton.setImage(UIImage(named: "select"), for: .normal)
			selectButton.tintColor = Theme.shared.activeCollection.favoriteEnabledColor
			selectButton.addTarget(self, action: #selector(toggleSelectMode), for: .touchUpInside)
			selectButton.accessibilityLabel = "Enter multiple selection".localized
			selectButton.isPointerInteractionEnabled = true

			NSLayoutConstraint.activate([
				selectButton.centerYAnchor.constraint(equalTo: self.centerYAnchor),
				selectButton.trailingAnchor.constraint(lessThanOrEqualTo: self.safeAreaLayoutGuide.trailingAnchor, constant: -rightSelectButtonPadding),
				selectButton.heightAnchor.constraint(equalToConstant: sideButtonsSize.height),
				selectButton.widthAnchor.constraint(equalToConstant: sideButtonsSize.width)
			])
		}

		// Finalize view setup
		self.accessibilityIdentifier = "sort-bar"
		Theme.shared.register(client: self)

		selectButton?.isHidden = !showSelectButton
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	deinit {
		Theme.shared.unregister(client: self)
	}

	// MARK: - Theme support
	public func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		self.sortButton?.applyThemeCollection(collection)
		self.selectButton?.applyThemeCollection(collection)
		self.backgroundColor = collection.tableRowColors.backgroundColor
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
		delegate?.toggleSelectMode()
	}

	// MARK: - UIPopoverPresentationControllerDelegate
	@objc open func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
		return .none
	}

	@objc open func prepareForPopoverPresentation(_ popoverPresentationController: UIPopoverPresentationController) {
		popoverPresentationController.backgroundColor = Theme.shared.activeCollection.tableBackgroundColor
	}
}
