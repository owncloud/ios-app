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

protocol SortBarDelegate: class {
	func sortBar(_ sortBar: SortBar, didUpdateSortMethod: SortMethod)

	func sortBar(_ sortBar: SortBar, presentViewController: UIViewController, animated: Bool, completionHandler: (() -> Void)?)

	func sortBar(_ sortBar: SortBar, leftButtonPressed: UIButton)

	func sortBar(_ sortBar: SortBar, rightButtonPressed: UIButton)
}

class SortBar: UIView, Themeable {

	weak var delegate: SortBarDelegate?

	// MARK: - Instance variables.

	var stackView: UIStackView
	var leftButton: UIButton
	var rightButton: UIButton

	var containerView: UIView
	var sortSegmentedControl: UISegmentedControl
	var sortButton: ThemeButton

	var leftButtonImage: UIImage
	var rightButtonImage: UIImage

	var sortMethod: SortMethod {
		didSet {

			let title = NSString(format: "Sorted by %@ ▼".localized as NSString, sortMethod.localizedName()) as String
			sortButton.setTitle(title, for: .normal)

			sortSegmentedControl.selectedSegmentIndex = SortMethod.all.index(of: sortMethod)!

			delegate?.sortBar(self, didUpdateSortMethod: sortMethod)
		}
	}

	// MARK: - Init & Deinit

	init(frame: CGRect, sortMethod: SortMethod) {
		stackView = UIStackView()
		leftButton = UIButton()
		leftButton.accessibilityIdentifier = "sort-bar.leftButton"
		rightButton = UIButton()
		rightButton.accessibilityIdentifier = "sort-bar.rightButton"

		containerView = UIView()
		sortSegmentedControl = UISegmentedControl()
		sortSegmentedControl.accessibilityIdentifier = "sort-bar.segmentedControl"
		sortButton = ThemeButton()
		sortButton.accessibilityIdentifier = "sort-bar.sortButton"

		leftButtonImage = Theme.shared.image(for: "folder-create", size: CGSize(width: 30.0, height: 30.0))!.withRenderingMode(.alwaysTemplate)

		rightButtonImage = Theme.shared.image(for: "folder-create", size: CGSize(width: 30.0, height: 30.0))!.withRenderingMode(.alwaysTemplate)

		self.sortMethod = sortMethod

		super.init(frame: frame)
		render()
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
		self.sortButton.applyThemeCollection(collection)
		self.sortSegmentedControl.applyThemeCollection(collection)
		self.backgroundColor = Theme.shared.activeCollection.navigationBarColors.backgroundColor
		self.leftButton.tintColor = collection.navigationBarColors.tintColor
		self.rightButton.tintColor = collection.navigationBarColors.tintColor
	}

	// MARK: - Sort UI

	private func render() {
		stackView.translatesAutoresizingMaskIntoConstraints = false
		leftButton.translatesAutoresizingMaskIntoConstraints = false
		rightButton.translatesAutoresizingMaskIntoConstraints = false

		containerView.translatesAutoresizingMaskIntoConstraints = false
		sortButton.translatesAutoresizingMaskIntoConstraints = false
		sortSegmentedControl.translatesAutoresizingMaskIntoConstraints = false

		stackView.axis = .horizontal
		stackView.alignment = .fill
		stackView.distribution = .fillProportionally

		leftButton.setImage(leftButtonImage, for: .normal)
		rightButton.setImage(rightButtonImage, for: .normal)

		leftButton.addTarget(self, action: #selector(leftButtonPressed), for: .touchUpInside)

		// Sort segmented control
		containerView.addSubview(sortSegmentedControl)
		NSLayoutConstraint.activate([
			sortSegmentedControl.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 10),
			sortSegmentedControl.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -10),
			sortSegmentedControl.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
			sortSegmentedControl.leftAnchor.constraint(greaterThanOrEqualTo: containerView.leftAnchor, constant: 20),
			sortSegmentedControl.rightAnchor.constraint(greaterThanOrEqualTo: containerView.rightAnchor, constant: -20)
		])

		for method in SortMethod.all {
			sortSegmentedControl.insertSegment(withTitle: method.localizedName(), at: SortMethod.all.index(of: method)!, animated: false)
		}

		sortSegmentedControl.selectedSegmentIndex = SortMethod.all.index(of: sortMethod)!
		sortSegmentedControl.isHidden = true
		sortSegmentedControl.addTarget(self, action: #selector(sortSegmentedControllerValueChanged), for: .valueChanged)

		// Sort Button
		containerView.addSubview(sortButton)
		NSLayoutConstraint.activate([
			sortButton.topAnchor.constraint(equalTo: self.containerView.topAnchor, constant: 10),
			sortButton.bottomAnchor.constraint(equalTo: self.containerView.bottomAnchor, constant: -10),
			sortButton.centerXAnchor.constraint(equalTo: self.containerView.centerXAnchor),
			sortButton.leftAnchor.constraint(greaterThanOrEqualTo: containerView.leftAnchor, constant: 20),
			sortButton.rightAnchor.constraint(lessThanOrEqualTo: containerView.rightAnchor, constant: -20)
		])

		sortButton.isHidden = true
		sortButton.addTarget(self, action: #selector(presentSortButtonOptions), for: .touchUpInside)

		addSubview(stackView)
		NSLayoutConstraint.activate([
			stackView.topAnchor.constraint(equalTo: topAnchor),
			stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
			stackView.leftAnchor.constraint(equalTo: leftAnchor, constant: 20),
			stackView.rightAnchor.constraint(equalTo: rightAnchor, constant: -20)
		])

		stackView.addArrangedSubview(leftButton)
		stackView.addArrangedSubview(containerView)

		// Uncomment this line for the right button ()
		//stackView.addArrangedSubview(rightButton)

		NSLayoutConstraint.activate([
			leftButton.widthAnchor.constraint(equalToConstant: 30),
			rightButton.widthAnchor.constraint(equalToConstant: 30)
		])
	}

	override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
		switch (traitCollection.horizontalSizeClass, traitCollection.verticalSizeClass) {
		case (.compact, .regular):
			sortSegmentedControl.isHidden = true
			sortButton.isHidden = false
		default:
			sortSegmentedControl.isHidden = false
			sortButton.isHidden = true

			let title = NSString(format: "Sorted by %@ ▼".localized as NSString, sortMethod.localizedName()) as String
			sortButton.setTitle(title, for: .normal)
		}
	}

	// MARK: - Actions
	@objc private func presentSortButtonOptions() {
		let controller = UIAlertController(title: "Sort by".localized, message: nil, preferredStyle: .actionSheet)

		for method in SortMethod.all {
			let action = UIAlertAction(title: method.localizedName(), style: .default, handler: {(_) in
				self.sortMethod = method
			})
			controller.addAction(action)
		}

		let cancel = UIAlertAction(title: "Cancel".localized, style: .cancel)
		controller.addAction(cancel)
		delegate?.sortBar(self, presentViewController: controller, animated: true, completionHandler: nil)
	}

	@objc private func sortSegmentedControllerValueChanged() {
		self.sortMethod = SortMethod.all[sortSegmentedControl.selectedSegmentIndex]
		delegate?.sortBar(self, didUpdateSortMethod: self.sortMethod)
	}

	func updateSortMethod() {
		_ = self.sortMethod
	}

	@objc private func leftButtonPressed() {
		delegate?.sortBar(self, leftButtonPressed: leftButton)
	}

}
