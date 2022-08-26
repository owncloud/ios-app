//
//  SearchViewController.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 21.06.22.
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

public protocol SearchViewControllerDelegate : AnyObject {
	func searchBegan(for viewController: SearchViewController)
	func search(for viewController: SearchViewController, withResults: OCDataSource?, style: CollectionViewCellStyle?)
	func searchEnded(for viewController: SearchViewController)
}

open class SearchViewController: UIViewController, UITextFieldDelegate, Themeable {
	private var resultsSourceObservation: NSKeyValueObservation?
	private var resultsCellStyleObservation: NSKeyValueObservation?

	open var clientContext: ClientContext

	open weak var delegate: SearchViewControllerDelegate?

	open var scopes: [SearchScope]? {
		didSet {
			updateChoicesFromScopes()
		}
	}

	open var activeScope: SearchScope? {
		willSet {
			if activeScope != newValue {
				activeScope?.isSelected = false

				resultsSourceObservation?.invalidate()
				resultsSourceObservation = nil

				resultsCellStyleObservation?.invalidate()
				resultsCellStyleObservation = nil
			}
		}

		didSet {
			if let activeScope = activeScope, let activeScopeChoice = self.scopePopup?.choices?.first(where: { choice in
				(choice.representedObject as? NSObject) == activeScope
			}) {
				OnMainThread {
					self.scopePopup?.selectedChoice = activeScopeChoice
				}
			}

			if activeScope != oldValue {
				activeScope?.isSelected = true

				resultsSourceObservation = activeScope?.observe(\.results, options: .initial, changeHandler: { [weak self] (scope, change) in
					if let self = self {
						self.delegate?.search(for: self, withResults: self.activeScope?.results, style: self.activeScope?.resultsCellStyle)
					}
				})

				resultsCellStyleObservation = activeScope?.observe(\.resultsCellStyle, changeHandler: { [weak self] (scope, change) in
					if let self = self {
						self.delegate?.search(for: self, withResults: self.activeScope?.results, style: self.activeScope?.resultsCellStyle)
					}
				})

				searchField.placeholder = activeScope?.localizedPlaceholder

				sendSearchFieldContentsToActiveScope()
			}
		}
	}

	private func updateChoicesFromScopes() {
		var choices : [PopupButtonChoice] = []

		if let scopes = scopes {
			for scope in scopes {
				choices.append(PopupButtonChoice(with: scope.localizedName, image: scope.icon, representedObject: scope))
			}
		}

		let previouslySelectedChoice = scopePopup?.selectedChoice

		scopePopup?.choices = choices

		if let previouslySelectedChoice = previouslySelectedChoice, let previouslyRepresentedObject = previouslySelectedChoice.representedObject as? NSObject, let equalSelectedChoice = choices.first(where: { choice in
			if let representedObject = choice.representedObject as? NSObject {
				return representedObject == previouslyRepresentedObject
			}

			return false
		}) {
			scopePopup?.selectedChoice = equalSelectedChoice
		}
	}

	init(with clientContext: ClientContext, scopes: [SearchScope]?, targetNavigationItem: UINavigationItem? = nil, delegate: SearchViewControllerDelegate?) {
		self.clientContext = clientContext

		super.init(nibName: nil, bundle: nil)

		self.targetNavigationItem = targetNavigationItem ?? clientContext.originatingViewController?.navigationItem
		self.delegate = delegate

		self.scopes = scopes
	}

	required public init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	deinit {
		Theme.shared.unregister(client: self)
	}

	// MARK: - Views
	var searchField: UISearchTextField = UISearchTextField()
	var scopePopup: PopupButtonController?
	var scopeViewController: UIViewController? {
		willSet {
			scopeViewController?.willMove(toParent: nil)
			scopeViewController?.view.removeFromSuperview()
			scopeViewController?.removeFromParent()

			scopeViewControllerConstraints = nil
		}
		didSet {
			if let scopeViewController = scopeViewController, let scopeViewControllerView = scopeViewController.view {
				addChild(scopeViewController)
				view.addSubview(scopeViewControllerView)
				scopeViewControllerConstraints = [
					scopeViewControllerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 5),
					scopeViewControllerView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
					scopeViewControllerView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10),
					scopeViewControllerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10)
				]
				scopeViewController.didMove(toParent: self)
			}
		}
	}
	private var scopeViewControllerConstraints : [NSLayoutConstraint]? {
		willSet {
			if let scopeViewControllerConstraints = scopeViewControllerConstraints {
				NSLayoutConstraint.deactivate(scopeViewControllerConstraints)
			}
		}
		didSet {
			if let scopeViewControllerConstraints = scopeViewControllerConstraints {
				NSLayoutConstraint.activate(scopeViewControllerConstraints)
			}
		}
	}

	open override func loadView() {
		let rootView = UIView()

		scopePopup = PopupButtonController(with: [], selectedChoice: nil, choiceHandler: { [weak self] choice in
			self?.activeScope = choice.representedObject as? SearchScope
		})
		// scopePopup?.showTitleInButton = false

		var scopePopupButtonConfiguration = UIButton.Configuration.borderless()
		scopePopupButtonConfiguration.contentInsets.leading = 0
		scopePopupButtonConfiguration.contentInsets.trailing = 5
		scopePopup?.button.configuration = scopePopupButtonConfiguration

		NSLayoutConstraint.activate([
			rootView.heightAnchor.constraint(equalToConstant: 10).with(priority: .defaultHigh), // Shrink to 10 points height if no scopeViewController is set
			searchField.widthAnchor.constraint(equalToConstant: 10000).with(priority: .defaultHigh) // maximize width of searchField in UINavigationBar
		])

		view = rootView
	}

	open override func viewDidLoad() {
		super.viewDidLoad()
		Theme.shared.register(client: self, applyImmediately: true)

		searchField.translatesAutoresizingMaskIntoConstraints = false
		searchField.addTarget(self, action: #selector(searchFieldContentsChanged), for: .editingChanged)
		searchField.delegate = self

		if let scopesCount = scopes?.count, scopesCount > 1 {
			searchField.leftView = scopePopup?.button
		}

		injectIntoNavigationItem()

		updateChoicesFromScopes()

		delegate?.searchBegan(for: self)

		if activeScope == nil {
			activeScope = scopes?.first
		}
	}

	open override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		OnMainThread {
			self.searchField.becomeFirstResponder()
		}
	}

	// MARK: - Navigation item modification
	var targetNavigationItem: UINavigationItem?

	var niInjected: Bool = false
	var niTitleView: UIView?
	var niRightBarButtonItems: [UIBarButtonItem]?
	var niHidesBackButton: Bool = false

	func injectIntoNavigationItem() {
		if !niInjected, let targetNavigationItem = targetNavigationItem {
			// Store content
			niTitleView = targetNavigationItem.titleView
			niRightBarButtonItems = targetNavigationItem.rightBarButtonItems
			niHidesBackButton = targetNavigationItem.hidesBackButton

			// Overwrite content
			targetNavigationItem.titleView = searchField

			// Alternative implementation as a standard "Cancel" button, more convention compliant, but needs more space: let cancelToolbarButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(endSearch))
			let cancelToolbarButton = UIBarButtonItem(image: UIImage(systemName: "xmark"), style: .done, target: self, action: #selector(endSearch))
			targetNavigationItem.rightBarButtonItems = [ cancelToolbarButton ]
			targetNavigationItem.hidesBackButton = true

			niInjected = true
		}
	}

	func restoreNavigationItem() {
		if niInjected, let targetNavigationItem = targetNavigationItem {
			// Restore content
			targetNavigationItem.titleView = niTitleView
			targetNavigationItem.rightBarButtonItems = niRightBarButtonItems
			targetNavigationItem.hidesBackButton = niHidesBackButton
			niInjected = false
		}
	}

	// MARK: - Input handling
	public func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
		return true
	}

	@objc func searchFieldContentsChanged() {
		sendSearchFieldContentsToActiveScope()
	}

	func sendSearchFieldContentsToActiveScope() {
		self.activeScope?.tokenizer?.updateFor(searchField: searchField)
	}

	// MARK: - End search
	@objc func endSearch() {
		activeScope = nil

		restoreNavigationItem()

		delegate?.search(for: self, withResults: nil, style: nil)
		delegate?.searchEnded(for: self)
	}

	// MARK: - Theme support
	public func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		self.view.backgroundColor = collection.navigationBarColors.backgroundColor
	}
}
