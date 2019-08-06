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

class SegmentedControl: UISegmentedControl {

	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		let currentIndex = selectedSegmentIndex
		super.touchesBegan(touches, with: event)

		if currentIndex == selectedSegmentIndex {
			sendActions(for: UIControl.Event.valueChanged)
		}
	}
}

protocol SortBarDelegate: class {

	var sortDirection: SortDirection { get set }
	var sortMethod: SortMethod { get set }

	func sortBar(_ sortBar: SortBar, didUpdateSortMethod: SortMethod)

	func sortBar(_ sortBar: SortBar, presentViewController: UIViewController, animated: Bool, completionHandler: (() -> Void)?)
}

class SortBar: UIView, Themeable, UIPopoverPresentationControllerDelegate {

	weak var delegate: SortBarDelegate? {
		didSet {
			updateSortButtonTitle()
		}
	}

	// MARK: - Constants
	let sideButtonsSize: CGSize = CGSize(width: 30.0, height: 30.0)
	let leftPadding: CGFloat = 20.0
	let rightPadding: CGFloat = 20.0
	let topPadding: CGFloat = 10.0
	let bottomPadding: CGFloat = 10.0

	// MARK: - Instance variables.

	var sortSegmentedControl: SegmentedControl?
	var sortButton: UIButton?

	var sortMethod: SortMethod {
		didSet {
			if oldValue == sortMethod {
				if delegate?.sortDirection == .ascendant {
					delegate?.sortDirection = .descendant
				} else {
					delegate?.sortDirection = .ascendant
				}
			}
			updateSortButtonTitle()

			sortButton?.accessibilityLabel = NSString(format: "Sort by %@".localized as NSString, sortMethod.localizedName()) as String
			sortButton?.sizeToFit()

			if let segmentIndex = SortMethod.all.index(of: sortMethod) {
				sortSegmentedControl?.selectedSegmentIndex = segmentIndex
			}

			delegate?.sortBar(self, didUpdateSortMethod: sortMethod)
		}
	}

	// MARK: - Init & Deinit

	init(frame: CGRect, sortMethod: SortMethod) {
		sortSegmentedControl = SegmentedControl()

		sortButton = UIButton(type: .system)

		self.sortMethod = sortMethod

		super.init(frame: frame)

		if let sortButton = sortButton, let sortSegmentedControl = sortSegmentedControl {
			sortButton.translatesAutoresizingMaskIntoConstraints = false
			sortSegmentedControl.translatesAutoresizingMaskIntoConstraints = false

			sortButton.accessibilityIdentifier = "sort-bar.sortButton"
			sortSegmentedControl.accessibilityIdentifier = "sort-bar.segmentedControl"

			self.addSubview(sortSegmentedControl)
			self.addSubview(sortButton)

			// Sort segmented control
			NSLayoutConstraint.activate([
				sortSegmentedControl.topAnchor.constraint(equalTo: self.topAnchor, constant: topPadding),
				sortSegmentedControl.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -bottomPadding),
				sortSegmentedControl.centerXAnchor.constraint(equalTo: self.centerXAnchor),
				sortSegmentedControl.leftAnchor.constraint(greaterThanOrEqualTo: self.leftAnchor, constant: leftPadding),
				sortSegmentedControl.rightAnchor.constraint(lessThanOrEqualTo: self.rightAnchor, constant: -rightPadding)
			])

			for method in SortMethod.all {
				sortSegmentedControl.insertSegment(withTitle: method.localizedName(), at: SortMethod.all.index(of: method)!, animated: false)
			}

			sortSegmentedControl.selectedSegmentIndex = SortMethod.all.index(of: sortMethod)!
			sortSegmentedControl.isHidden = true
			sortSegmentedControl.addTarget(self, action: #selector(sortSegmentedControllerValueChanged), for: .valueChanged)

			// Sort Button
			sortButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .subheadline)
			sortButton.titleLabel?.adjustsFontForContentSizeCategory = true
			sortButton.semanticContentAttribute = (sortButton.effectiveUserInterfaceLayoutDirection == .leftToRight) ? .forceRightToLeft : .forceLeftToRight

			sortButton.setImage(UIImage(named: "chevron-small-light"), for: .normal)

			sortButton.setContentHuggingPriority(.required, for: .horizontal)

			NSLayoutConstraint.activate([
				sortButton.topAnchor.constraint(equalTo: self.topAnchor, constant: topPadding),
				sortButton.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -bottomPadding),
				sortButton.leftAnchor.constraint(equalTo: self.leftAnchor, constant: leftPadding),
				sortButton.rightAnchor.constraint(lessThanOrEqualTo: self.rightAnchor, constant: -rightPadding)
			])

			sortButton.isHidden = true
			sortButton.addTarget(self, action: #selector(presentSortButtonOptions(_:)), for: .touchUpInside)
		}

		// Finalize view setup
		self.accessibilityIdentifier = "sort-bar"
		Theme.shared.register(client: self)
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	deinit {
		Theme.shared.unregister(client: self)
	}

	// MARK: - Theme support

	func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		self.sortButton?.applyThemeCollection(collection)
		self.sortSegmentedControl?.applyThemeCollection(collection)
		self.backgroundColor = collection.navigationBarColors.backgroundColor
	}

	// MARK: - Sort UI

	override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
		switch (traitCollection.horizontalSizeClass, traitCollection.verticalSizeClass) {
		case (.compact, .regular):
			sortSegmentedControl?.isHidden = true
			sortButton?.isHidden = false
		default:
			sortSegmentedControl?.isHidden = false
			sortButton?.isHidden = true
		}
	}

	// MARK: - Sort Direction Image

	func updateSortButtonTitle() {
		var title = NSString(format: "Sort by %@".localized as NSString, sortMethod.localizedName()) as String

		if delegate?.sortDirection == .descendant {
			title = String(format: "%@ ↓", title)
		} else {
			title = String(format: "%@ ↑", title)
		}
		sortButton?.setTitle(title, for: .normal)
	}

	// MARK: - Actions
	@objc private func presentSortButtonOptions(_ sender : UIButton) {
		let tableViewController = SortMethodTableViewController()
		tableViewController.modalPresentationStyle = UIModalPresentationStyle.popover
		tableViewController.sortBarDelegate = self.delegate
		tableViewController.sortBar = self

		let popoverPresentationController = tableViewController.popoverPresentationController
		popoverPresentationController?.sourceView = sender
		popoverPresentationController?.delegate = self
		popoverPresentationController?.sourceRect = CGRect(x: 0, y: 0, width: sender.frame.size.width, height: sender.frame.size.height)
		popoverPresentationController?.permittedArrowDirections = .up

		delegate?.sortBar(self, presentViewController: tableViewController, animated: true, completionHandler: nil)
	}

	@objc private func sortSegmentedControllerValueChanged() {
		if let selectedIndex = sortSegmentedControl?.selectedSegmentIndex {
			self.sortMethod = SortMethod.all[selectedIndex]
			delegate?.sortBar(self, didUpdateSortMethod: self.sortMethod)
		}
	}

	// MARK: - UIPopoverPresentationControllerDelegate
	func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
		return .none
	}
}
