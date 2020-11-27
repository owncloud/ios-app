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

public enum SortLayout: Int {
	case list = 0
	case grid = 1
}

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

public protocol SortBarDelegate: class {

	var sortDirection: SortDirection { get set }
	var sortMethod: SortMethod { get set }

	func sortBar(_ sortBar: SortBar, didUpdateSortMethod: SortMethod)

	func sortBar(_ sortBar: SortBar, presentViewController: UIViewController, animated: Bool, completionHandler: (() -> Void)?)

	func sortBar(_ sortBar: SortBar, didUpdateLayout: SortLayout)

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
	let leftPadding: CGFloat = 20.0
	let rightPadding: CGFloat = 20.0
	let topPadding: CGFloat = 10.0
	let bottomPadding: CGFloat = 10.0

	// MARK: - Instance variables.

	public var sortSegmentedControl: SegmentedControl?
	public var sortButton: UIButton?
	public var selectButton: UIButton?
	public var layoutButton: UIButton?
	public var showSelectButton: Bool = false {
		didSet {
			selectButton?.isHidden = !showSelectButton
			selectButton?.accessibilityElementsHidden = !showSelectButton
			selectButton?.isEnabled = showSelectButton

			UIAccessibility.post(notification: .layoutChanged, argument: nil)
		}
	}
	var currentLayout: SortLayout = .list

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

			sortButton?.accessibilityLabel = NSString(format: "Sort by %@".localized as NSString, sortMethod.localizedName()) as String
			sortButton?.sizeToFit()

			if let oldSementIndex = SortMethod.all.index(of: oldValue) {
				sortSegmentedControl?.setTitle(oldValue.localizedName(), forSegmentAt: oldSementIndex)
			}
			if let segmentIndex = SortMethod.all.index(of: sortMethod) {
				sortSegmentedControl?.selectedSegmentIndex = segmentIndex
				sortSegmentedControl?.setTitle(sortDirectionTitle(sortMethod.localizedName()), forSegmentAt: segmentIndex)
			}

			delegate?.sortBar(self, didUpdateSortMethod: sortMethod)
		}
	}

	// MARK: - Init & Deinit

	public init(frame: CGRect, sortMethod: SortMethod) {
		sortSegmentedControl = SegmentedControl()
		selectButton = UIButton()
		layoutButton = UIButton()
		sortButton = UIButton(type: .system)

		self.sortMethod = sortMethod

		super.init(frame: frame)

		if let sortButton = sortButton, let sortSegmentedControl = sortSegmentedControl, let selectButton = selectButton, let layoutButton = layoutButton {
			sortButton.translatesAutoresizingMaskIntoConstraints = false
			sortSegmentedControl.translatesAutoresizingMaskIntoConstraints = false
			selectButton.translatesAutoresizingMaskIntoConstraints = false
			layoutButton.translatesAutoresizingMaskIntoConstraints = false

			sortButton.accessibilityIdentifier = "sort-bar.sortButton"
			sortSegmentedControl.accessibilityIdentifier = "sort-bar.segmentedControl"

			self.addSubview(sortSegmentedControl)
			self.addSubview(sortButton)
			self.addSubview(selectButton)
			self.addSubview(layoutButton)

			// Sort segmented control
			NSLayoutConstraint.activate([
				sortSegmentedControl.topAnchor.constraint(equalTo: self.topAnchor, constant: topPadding),
				sortSegmentedControl.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -bottomPadding),
				sortSegmentedControl.centerXAnchor.constraint(equalTo: self.centerXAnchor),
				sortSegmentedControl.leftAnchor.constraint(greaterThanOrEqualTo: self.leftAnchor, constant: leftPadding),
				sortSegmentedControl.rightAnchor.constraint(lessThanOrEqualTo: self.rightAnchor, constant: -rightPadding)
			])

			var longestTitleWidth : CGFloat = 0.0
			for method in SortMethod.all {
				sortSegmentedControl.insertSegment(withTitle: method.localizedName(), at: SortMethod.all.index(of: method)!, animated: false)
				let titleWidth = method.localizedName().appending(" ↓").width(withConstrainedHeight: sortSegmentedControl.frame.size.height, font: UIFont.systemFont(ofSize: 16.0))
				if titleWidth > longestTitleWidth {
					longestTitleWidth = titleWidth
				}
			}

			var currentIndex = 0
			for _ in SortMethod.all {
				sortSegmentedControl.setWidth(longestTitleWidth, forSegmentAt: currentIndex)
				currentIndex += 1
			}

			sortSegmentedControl.selectedSegmentIndex = SortMethod.all.index(of: sortMethod)!
			sortSegmentedControl.isHidden = true
			sortSegmentedControl.accessibilityElementsHidden = true
			sortSegmentedControl.isEnabled = false
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
			sortButton.accessibilityElementsHidden = true
			sortButton.isEnabled = false
			sortButton.addTarget(self, action: #selector(presentSortButtonOptions), for: .touchUpInside)

			selectButton.setImage(UIImage(named: "select"), for: .normal)
			selectButton.tintColor = Theme.shared.activeCollection.favoriteEnabledColor
			selectButton.addTarget(self, action: #selector(toggleSelectMode), for: .touchUpInside)
			selectButton.accessibilityLabel = "Enter multiple selection".localized

			layoutButton.setImage(UIImage(named: "ic_pdf_outline")?.tinted(with: Theme.shared.activeCollection.navigationBarColors.tintColor ?? .white), for: .normal)
			layoutButton.tintColor = Theme.shared.activeCollection.favoriteEnabledColor
			//layoutButton.addTarget(self, action: #selector(presentLayoutButtonOptions), for: .touchUpInside)
			if #available(iOSApplicationExtension 14.0, *) {
				layoutButton.menu = createMenu()
			} else {
				// Fallback on earlier versions
			}

			if #available(iOS 13.4, *) {
				selectButton.isPointerInteractionEnabled = true
				layoutButton.isPointerInteractionEnabled = true
			}

			NSLayoutConstraint.activate([
				selectButton.centerYAnchor.constraint(equalTo: self.centerYAnchor),
				selectButton.rightAnchor.constraint(equalTo: self.safeAreaLayoutGuide.rightAnchor, constant: -rightPadding),
				selectButton.heightAnchor.constraint(equalToConstant: sideButtonsSize.height),
				selectButton.widthAnchor.constraint(equalToConstant: sideButtonsSize.width),

				layoutButton.centerYAnchor.constraint(equalTo: self.centerYAnchor),
				layoutButton.rightAnchor.constraint(equalTo: selectButton.leftAnchor, constant: -rightPadding),
				layoutButton.heightAnchor.constraint(equalToConstant: 60.0),
				layoutButton.widthAnchor.constraint(equalToConstant: 44.0)
			])
		}

		// Finalize view setup
		self.accessibilityIdentifier = "sort-bar"
		Theme.shared.register(client: self)

		selectButton?.isHidden = !showSelectButton
		selectButton?.accessibilityElementsHidden = !showSelectButton
		selectButton?.isEnabled = showSelectButton
		updateForCurrentTraitCollection()
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
		self.layoutButton?.applyThemeCollection(collection)
		self.sortSegmentedControl?.applyThemeCollection(collection)
		self.backgroundColor = collection.navigationBarColors.backgroundColor
	}

	// MARK: - Sort UI

	override public func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
		super.traitCollectionDidChange(previousTraitCollection)
		self.updateForCurrentTraitCollection()
	}

	public func updateForCurrentTraitCollection() {
		switch (traitCollection.horizontalSizeClass, traitCollection.verticalSizeClass) {
		case (.compact, .regular):
			sortSegmentedControl?.isHidden = true
			sortSegmentedControl?.accessibilityElementsHidden = true
			sortSegmentedControl?.isEnabled = false
			sortButton?.isHidden = false
			sortButton?.accessibilityElementsHidden = false
			sortButton?.isEnabled = true
		default:
			sortSegmentedControl?.isHidden = false
			sortSegmentedControl?.accessibilityElementsHidden = false
			sortSegmentedControl?.isEnabled = true
			sortButton?.isHidden = true
			sortButton?.accessibilityElementsHidden = true
			sortButton?.isEnabled = false
		}

		UIAccessibility.post(notification: .layoutChanged, argument: nil)
	}

	// MARK: - Sort Direction Title

	func updateSortButtonTitle() {
		let title = NSString(format: "Sort by %@".localized as NSString, sortMethod.localizedName()) as String
		sortButton?.setTitle(sortDirectionTitle(title), for: .normal)
	}

	func sortDirectionTitle(_ title: String) -> String {
		if delegate?.sortDirection == .descendant {
			return String(format: "%@ ↓", title)
		} else {
			return String(format: "%@ ↑", title)
		}
	}

	// MARK: - Actions

	@objc private func presentLayoutButtonOptions(_ sender : UIButton) {


		print("--> presentLayoutButtonOptions \(currentLayout)")
		switch currentLayout {
		case .list:
		self.layoutButton?.setImage(UIImage(named: "ic_pdf_view_multipage")?.tinted(with: Theme.shared.activeCollection.navigationBarColors.tintColor ?? .white), for: .normal)
			currentLayout = .grid
		case .grid:
		self.layoutButton?.setImage(UIImage(named: "ic_pdf_outline")?.tinted(with: Theme.shared.activeCollection.navigationBarColors.tintColor ?? .white), for: .normal)
			currentLayout = .list
		}
		delegate?.sortBar(self, didUpdateLayout: currentLayout)
	}

	@available(iOSApplicationExtension 13.0, *)
	func createMenu() -> UIMenu {

	  let photoAction = UIAction(
		title: "Liste",
		image: UIImage(systemName: "list.bullet")
	  ) { (_) in
		print("New Photo from Camera")
	  }

		let fromWebAction = UIAction(
	   title: "Raster",
	   image: UIImage(systemName: "square.grid.2x2")
	 ) { (_) in
	   print("Photo from the internet")
	 }
	   fromWebAction.state = .on

	  let albumAction = UIAction(
		title: "Symbole",
		image: UIImage(systemName: "photo")
	  ) { (_) in
		print("Photo from photo album")
	  }

		let albumAction1 = UIAction(
	   title: "Klein",
	   image: nil
	 ) { (_) in
	   print("Photo from photo album")
	 }

		let albumAction2 = UIAction(
	   title: "Medium",
	   image: nil
	 ) { (_) in
	   print("Photo from photo album")
	 }

		let albumAction3 = UIAction(
	   title: "Groß",
	   image: nil
	 ) { (_) in
	   print("Photo from photo album")
	 }

	  let menuActions = [photoAction, fromWebAction, albumAction, albumAction1, albumAction2, albumAction3]

	  let addNewMenu = UIMenu(
		title: "",
		children: menuActions)

	  return addNewMenu
	}

	@objc private func presentSortButtonOptions(_ sender : UIButton) {
		let tableViewController = SortMethodTableViewController()
		tableViewController.modalPresentationStyle = .popover
		tableViewController.sortBarDelegate = self.delegate
		tableViewController.sortBar = self

		if #available(iOS 13, *) {
			// On iOS 13.0/13.1, the table view's content needs to be inset by the height of the arrow
			// (this can hopefully be removed again in the future, if/when Apple addresses the issue)
			let popoverArrowHeight : CGFloat = 13

			tableViewController.tableView.contentInsetAdjustmentBehavior = .never
			tableViewController.tableView.contentInset = UIEdgeInsets(top: popoverArrowHeight, left: 0, bottom: 0, right: 0)
			tableViewController.tableView.separatorInset = UIEdgeInsets()
		}

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
