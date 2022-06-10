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

public class SegmentedControl: UISegmentedControl {
	var oldValue : Int!

	public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent? ) {
		self.oldValue = self.selectedSegmentIndex
		super.touchesBegan(touches, with: event)
	}

	public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent? ) {
		super.touchesEnded(touches, with: event )

		if self.oldValue == self.selectedSegmentIndex {
			sendActions(for: UIControl.Event.valueChanged)
		}
	}
}

public enum SearchScope : Int, CaseIterable {
	case global
	case local

	var label : String {
		var name : String!

		switch self {
			case .global: name = "Account".localized
			case .local: name = "Folder".localized
		}

		return name
	}
}

public protocol SortBarDelegate: AnyObject {

	var sortDirection: SortDirection { get set }
	var sortMethod: SortMethod { get set }
	var searchScope: SearchScope { get set }

	func sortBar(_ sortBar: SortBar, didUpdateSortMethod: SortMethod)

	func sortBar(_ sortBar: SortBar, didUpdateSearchScope: SearchScope)

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
	let sideButtonsSize: CGSize = CGSize(width: 44.0, height: 44.0)
	let leftPadding: CGFloat = 16.0
	let rightPadding: CGFloat = 20.0
	let rightSelectButtonPadding: CGFloat = 8.0
	let rightSearchScopePadding: CGFloat = 15.0
	let topPadding: CGFloat = 10.0
	let bottomPadding: CGFloat = 10.0

	// MARK: - Instance variables.

	public var sortButton: UIButton?
	public var searchScopeSegmentedControl : SegmentedControl?
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

	var showSearchScope: Bool = false {
		didSet {
			showSelectButton = !self.showSearchScope
			self.searchScopeSegmentedControl?.isHidden = false
			self.searchScopeSegmentedControl?.alpha = oldValue ? 1.0 : 0.0

			// Woraround for Accessibility: remove all elements, when element is hidden, otherwise the elements are still available for accessibility
			if oldValue == false {
				for scope in SearchScope.allCases {
					searchScopeSegmentedControl?.insertSegment(withTitle: scope.label, at: scope.rawValue, animated: false)
				}
				searchScopeSegmentedControl?.selectedSegmentIndex = searchScope.rawValue
			} else {
				self.searchScopeSegmentedControl?.removeAllSegments()
			}

			UIView.animate(withDuration: 0.3, animations: {
				self.searchScopeSegmentedControl?.alpha = self.showSearchScope ? 1.0 : 0.0
			}, completion: { (_) in
				self.searchScopeSegmentedControl?.isHidden = !self.showSearchScope
			})
		}
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

	public var searchScope : SearchScope {
		didSet {
			delegate?.searchScope = searchScope
			searchScopeSegmentedControl?.selectedSegmentIndex = searchScope.rawValue
		}
	}

	// MARK: - Init & Deinit

	public init(frame: CGRect = .zero, sortMethod: SortMethod, searchScope: SearchScope = .local) {
		selectButton = UIButton()
		sortButton = UIButton(type: .system)
		searchScopeSegmentedControl = SegmentedControl()

		self.sortMethod = sortMethod
		self.searchScope = searchScope

		super.init(frame: frame)

		if let sortButton = sortButton, let searchScopeSegmentedControl = searchScopeSegmentedControl, let selectButton = selectButton {
			sortButton.translatesAutoresizingMaskIntoConstraints = false
			selectButton.translatesAutoresizingMaskIntoConstraints = false
			searchScopeSegmentedControl.translatesAutoresizingMaskIntoConstraints = false

			sortButton.accessibilityIdentifier = "sort-bar.sortButton"
			searchScopeSegmentedControl.accessibilityIdentifier = "sort-bar.searchScopeSegmentedControl"
			searchScopeSegmentedControl.accessibilityLabel = "Search scope".localized
			searchScopeSegmentedControl.isHidden = !self.showSearchScope
			searchScopeSegmentedControl.addTarget(self, action: #selector(searchScopeValueChanged), for: .valueChanged)

			self.addSubview(sortButton)
			self.addSubview(searchScopeSegmentedControl)
			self.addSubview(selectButton)

			// Sort segmented control
			NSLayoutConstraint.activate([
				searchScopeSegmentedControl.trailingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.trailingAnchor, constant: -rightSearchScopePadding),
				searchScopeSegmentedControl.topAnchor.constraint(equalTo: self.topAnchor, constant: topPadding),
				searchScopeSegmentedControl.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -bottomPadding)
			])

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
		self.searchScopeSegmentedControl?.applyThemeCollection(collection)
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
	@objc private func searchScopeValueChanged() {
		if let selectedIndex = searchScopeSegmentedControl?.selectedSegmentIndex {
			self.searchScope = SearchScope(rawValue: selectedIndex)!
			delegate?.sortBar(self, didUpdateSearchScope: self.searchScope)
		}
	}

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
