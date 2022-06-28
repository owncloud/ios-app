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
			updateSegmentsFromScopes()
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
			if let activeScope = activeScope, let scopeIndex = scopes?.firstIndex(of: activeScope) {
				OnMainThread {
					self.scopeView.selectedSegmentIndex = scopeIndex
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

				sendSearchFieldContentsToActiveScope()
			}
		}
	}

	private func updateSegmentsFromScopes() {
		scopeView.removeAllSegments()

		if let scopes = scopes {
			for scope in scopes {
				scopeView.insertSegment(withTitle: scope.localizedName, at: scopeView.numberOfSegments, animated: false)
			}
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
	var scopeView: UISegmentedControl = UISegmentedControl()

	open override func loadView() {
		let rootView = UIView()

		scopeView.translatesAutoresizingMaskIntoConstraints = false
		scopeView.addAction(UIAction(handler: { [weak self] action in
			guard let self = self, let scopes = self.scopes else {
				return
			}

			let selectedIndex = self.scopeView.selectedSegmentIndex

			if selectedIndex >= 0, selectedIndex < scopes.count {
				self.activeScope = scopes[selectedIndex]
			}
		}), for: .valueChanged)
		rootView.addSubview(scopeView)

		NSLayoutConstraint.activate([
			scopeView.topAnchor.constraint(equalTo: rootView.safeAreaLayoutGuide.topAnchor, constant: 5),
			scopeView.leadingAnchor.constraint(equalTo: rootView.safeAreaLayoutGuide.leadingAnchor, constant: 10),
			scopeView.trailingAnchor.constraint(equalTo: rootView.safeAreaLayoutGuide.trailingAnchor, constant: -10),
			scopeView.bottomAnchor.constraint(equalTo: rootView.safeAreaLayoutGuide.bottomAnchor, constant: -10),

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

		injectIntoNavigationItem()

		updateSegmentsFromScopes()

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

			let cancelToolbarButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(endSearch))
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
		let searchText = searchField.text
		self.activeScope?.updateForSearchTerm((searchText != "") ? searchText : nil)
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
