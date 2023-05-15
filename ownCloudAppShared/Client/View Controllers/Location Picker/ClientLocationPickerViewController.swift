//
//  ClientLocationPickerViewController.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 29.11.22.
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

class ClientLocationPickerViewController: EmbeddingViewController, CustomViewControllerEmbedding, Themeable, UINavigationControllerDelegate {
	var locationPicker: ClientLocationPicker

	init(with locationPicker: ClientLocationPicker) {
		self.locationPicker = locationPicker
		super.init(nibName: nil, bundle: nil)
		self.locationPicker.rootNavigationController?.delegate = self

		self.cssSelector = .locationPicker

		currentLocation = (self.locationPicker.rootNavigationController?.topViewController as? ClientItemViewController)?.location
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	var bottomButtonBar: BottomButtonBar?
	var topSeparatorLine: UIView = ThemeCSSView(withSelectors: [.separator])

	override func viewDidLoad() {
		super.viewDidLoad()

		let showCancelButton = locationPicker.headerView != nil

		bottomButtonBar = BottomButtonBar(prompt: locationPicker.selectPrompt, selectButtonTitle: locationPicker.selectButtonTitle, cancelButtonTitle: "Cancel".localized, hasCancelButton: showCancelButton, selectAction: UIAction(handler: { [weak self] _ in
			self?.chooseCurrentLocation()
		}), cancelAction: UIAction(handler: { [weak self] _ in
			self?.cancel()
		}))

		topSeparatorLine.translatesAutoresizingMaskIntoConstraints = false

		guard let bottomButtonBar else { return }

		view.addSubview(bottomButtonBar)

		var constraints: [NSLayoutConstraint] = []

		if let headerView = locationPicker.headerView {
			headerView.translatesAutoresizingMaskIntoConstraints = false
			view.addSubview(headerView)

			headerView.addSubview(topSeparatorLine)

			constraints.append(contentsOf: [
				headerView.leftAnchor.constraint(equalTo: view.leftAnchor),
				headerView.rightAnchor.constraint(equalTo: view.rightAnchor),
				headerView.topAnchor.constraint(equalTo: view.topAnchor),

				topSeparatorLine.leftAnchor.constraint(equalTo: headerView.leftAnchor),
				topSeparatorLine.rightAnchor.constraint(equalTo: headerView.rightAnchor),
				topSeparatorLine.bottomAnchor.constraint(equalTo: headerView.bottomAnchor),
				topSeparatorLine.heightAnchor.constraint(equalToConstant: 1)
			])
		}

		constraints.append(contentsOf: [
			bottomButtonBar.leftAnchor.constraint(equalTo: view.leftAnchor),
			bottomButtonBar.rightAnchor.constraint(equalTo: view.rightAnchor),
			bottomButtonBar.bottomAnchor.constraint(equalTo: view.bottomAnchor)
		])

		NSLayoutConstraint.activate(constraints)
	}

	private var registered = false
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		if !registered {
			registered = true
			Theme.shared.register(client: self, applyImmediately: true)
		}
	}

	// MARK: - UINavigationControllerDelegate
	func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
		var rightBarButtonItems: [UIBarButtonItem] = []

		if locationPicker.headerView == nil {
			// Add cancel button to navigation bar if no headerView is used
			rightBarButtonItems.append(UIBarButtonItem(systemItem: .cancel, primaryAction: UIAction(handler: { [weak self] (_) in
				self?.choose(cancelled: true)
			})))
		}

		if let itemViewController = viewController as? ClientItemViewController, let location = itemViewController.location {
			currentLocationContext = itemViewController.clientContext

			if let bookmark = itemViewController.clientContext?.core?.bookmark, location.bookmarkUUID == nil {
				// Add bookmark UUID to location
				currentLocation = OCLocation(bookmarkUUID: bookmark.uuid, driveID: location.driveID, path: location.path)
			} else {
				currentLocation = location
			}

			// Add actions for location
			if let currentLocation, let currentLocationContext {
				var rootItem = currentLocationContext.rootItem as? OCItem
				if rootItem == nil {
					rootItem = try? currentLocationContext.core?.cachedItem(at: currentLocation)
				}

				if let rootItem, let core = currentLocationContext.core {
					let actionsLocation = OCExtensionLocation(ofType: .action, identifier: .locationPickerBar)
					let actionContext = ActionContext(viewController: itemViewController, clientContext: currentLocationContext, core: core, query: currentLocationContext.query, items: [rootItem], location: actionsLocation, sender: self)
					let actions = Action.sortedApplicableActions(for: actionContext)

					for action in actions {
						rightBarButtonItems.append(action.provideBarButtonItem())
					}
				}
			}
		} else {
			currentLocation = nil
			currentLocationContext = nil
		}

		viewController.navigationItem.navigationContent.add(items: [
			NavigationContentItem(identifier: "location-picker-actions-right", area: .right, priority: .high, position: .trailing, items: rightBarButtonItems)
		])
	}

	// MARK: - Location tracking and choice
	var currentLocationContext: ClientContext? // context in which to see currentLocation
	var currentLocation: OCLocation? {
		didSet {
			var validTargetLocation: Bool = false

			if let currentLocation {
				if let allowedLocationFilter = locationPicker.allowedLocationFilter {
					validTargetLocation = allowedLocationFilter(currentLocation, currentLocationContext)
				} else {
					validTargetLocation = true
				}
			}

			bottomButtonBar?.selectButton.isEnabled = validTargetLocation
		}
	}

	@objc func chooseCurrentLocation() {
		choose(location: currentLocation, cancelled: false)
	}

	@objc func cancel() {
		choose(cancelled: true)
	}

	func choose(item: OCItem? = nil, location: OCLocation? = nil, cancelled: Bool) {
		locationPicker.choose(item: item, location: location, context: currentLocationContext, cancelled: cancelled)
		self.dismiss(animated: true)
	}

	// MARK: - CustomViewControllerEmbedding
	func constraintsForEmbedding(contentView: UIView) -> [NSLayoutConstraint] {
		var defaultAnchorSet = view.defaultAnchorSet

		if let bottomButtonBar {
			defaultAnchorSet.bottomAnchor = bottomButtonBar.topAnchor
		}

		if let headerView = locationPicker.headerView {
			defaultAnchorSet.topAnchor = headerView.bottomAnchor
		}

		return view.embed(toFillWith: contentView, enclosingAnchors: defaultAnchorSet)
	}

	// MARK: - Themeable
	func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		view.backgroundColor = collection.css.getColor(.fill, for:view)
	}
}

extension ThemeCSSSelector {
	static let locationPicker = ThemeCSSSelector(rawValue: "locationPicker")
}
