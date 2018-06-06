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
}

class SortBar: UIView, Themeable {

	weak var delegate: SortBarDelegate?

	// MARK: - Instance variables.

	var sortButton: ThemeButton?
	var sortSegmentedControl: UISegmentedControl?
	var sortMethod: SortMethod {
		didSet {

			if self.sortButton != nil {
				let title = NSString(format: "Sorted by %@ ▼".localized as NSString, sortMethod.localizedName()) as String
				sortButton?.setTitle(title, for: .normal)
			}

			if self.sortSegmentedControl != nil {
				sortSegmentedControl?.selectedSegmentIndex = SortMethod.all.index(of: sortMethod)!
			}

			delegate?.sortBar(self, didUpdateSortMethod: sortMethod)
		}
	}

	// MARK: - Init & Deinit

	init(frame: CGRect, sortMethod: SortMethod) {

		self.sortMethod = sortMethod
		super.init(frame: frame)

		if UIDevice.current.isIpad() {
			createSortSegmentedController()
		} else {
			createSortButton()
		}

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
		self.applyThemeCollection(collection)
	}

	// MARK: - Sort UI

	private func createSortButton() {
		sortButton = ThemeButton(frame: .zero)
		sortButton?.translatesAutoresizingMaskIntoConstraints = false
		self.addSubview(sortButton!)
		sortButton?.topAnchor.constraint(equalTo: self.topAnchor, constant: 10).isActive = true
		sortButton?.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -10).isActive = true
		sortButton?.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
		sortButton?.addTarget(self, action: #selector(presentSortButtonOptions), for: .touchUpInside)
		sortButton?.accessibilityIdentifier = "sort-button"
	}

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

	private func createSortSegmentedController() {
		sortSegmentedControl = UISegmentedControl(frame: .zero)
		sortSegmentedControl?.translatesAutoresizingMaskIntoConstraints = false
		self.addSubview(sortSegmentedControl!)
		sortSegmentedControl?.topAnchor.constraint(equalTo: self.topAnchor, constant: 10).isActive = true
		sortSegmentedControl?.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -10).isActive = true
		sortSegmentedControl?.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
		sortSegmentedControl?.accessibilityIdentifier = "sort-segmented-control"

		for method in SortMethod.all {
			sortSegmentedControl?.insertSegment(withTitle: method.localizedName(), at: SortMethod.all.index(of: method)!, animated: false)
		}

		sortSegmentedControl?.selectedSegmentIndex = SortMethod.all.index(of: sortMethod)!
		sortSegmentedControl?.addTarget(self, action: #selector(sortSegmentedControllerValueChanged), for: .valueChanged)
	}

	@objc private func sortSegmentedControllerValueChanged() {

		self.sortMethod = SortMethod.all[sortSegmentedControl!.selectedSegmentIndex]
		delegate?.sortBar(self, didUpdateSortMethod: self.sortMethod)

	}

	func updateSortMethod() {
		_ = self.sortMethod
	}

}
