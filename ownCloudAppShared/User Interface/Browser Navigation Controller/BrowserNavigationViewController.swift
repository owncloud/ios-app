//
//  BrowserNavigationViewController.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 16.01.23.
//  Copyright © 2023 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2023, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import UIKit
import ownCloudSDK

public protocol BrowserNavigationViewControllerDelegate: AnyObject {
	func browserNavigation(viewController: BrowserNavigationViewController, contentViewControllerDidChange: UIViewController?)
}

open class BrowserNavigationViewController: EmbeddingViewController, Themeable, BrowserNavigationHistoryDelegate, ThemeCSSAutoSelector {
	var navigationView: UINavigationBar = UINavigationBar()
	var contentContainerView: UIView = UIView()
	var contentContainerLidView: UIView = UIView()

	var sideBarSeperatorView: ThemeCSSView = ThemeCSSView(withSelectors: [.separator])

	lazy open var history: BrowserNavigationHistory = {
		let history = BrowserNavigationHistory()
		history.delegate = self
		return history
	}()

	weak open var delegate: BrowserNavigationViewControllerDelegate?

	open override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()

		if let windowWidth = view.window?.bounds.width {
			if preferredSideBarWidth > windowWidth {
				// Adapt to widths slimmer than sidebarWidth
				sideBarWidth = windowWidth - 20
			} else {
				// Use preferredSideBarWidth
				sideBarWidth = preferredSideBarWidth
			}

			if windowWidth < sideBarWidth * 2.5 {
				// Slide the sidebar over the content if the content doesn't have at least 2.5x the space of the sidebar
				sideBarDisplayMode = .over
			} else {
				// Show sidebar and content side by side if there's enough space
				sideBarDisplayMode = .sideBySide
			}
		} else {
			// Slide the sidebar over the content
			// if the window width can't be determined
			sideBarDisplayMode = .over
		}
	}

	open override func viewDidLoad() {
		super.viewDidLoad()

		contentContainerView.cssSelector = .content
		contentContainerView.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(contentContainerView)

		navigationView.translatesAutoresizingMaskIntoConstraints = false
		navigationView.delegate = self

		contentContainerView.addSubview(navigationView)

		contentContainerLidView.translatesAutoresizingMaskIntoConstraints = false
		contentContainerLidView.backgroundColor = UIColor(white: 0.0, alpha: 0.5)
		contentContainerLidView.isHidden = true
		contentContainerLidView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showHideSideBar)))
		view.addSubview(contentContainerLidView)

		sideBarSeperatorView.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(sideBarSeperatorView)

		NSLayoutConstraint.activate([
			contentContainerView.topAnchor.constraint(equalTo: view.topAnchor),
			contentContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
			contentContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor).with(priority: .defaultHigh), // Allow for flexibility without having to remove this constraint. It will be overridden by constraints with higher priority (default is .required) when necessary
			contentContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

			contentContainerLidView.topAnchor.constraint(equalTo: contentContainerView.topAnchor),
			contentContainerLidView.bottomAnchor.constraint(equalTo: contentContainerView.bottomAnchor),
			contentContainerLidView.leadingAnchor.constraint(equalTo: contentContainerView.leadingAnchor),
			contentContainerLidView.trailingAnchor.constraint(equalTo: contentContainerView.trailingAnchor),

			sideBarSeperatorView.topAnchor.constraint(equalTo: contentContainerView.topAnchor),
			sideBarSeperatorView.bottomAnchor.constraint(equalTo: contentContainerView.bottomAnchor),
			sideBarSeperatorView.leadingAnchor.constraint(equalTo: contentContainerView.leadingAnchor, constant: -1),
			sideBarSeperatorView.widthAnchor.constraint(equalToConstant: 1),

			navigationView.topAnchor.constraint(equalTo: contentContainerView.safeAreaLayoutGuide.topAnchor),
			navigationView.leadingAnchor.constraint(equalTo: contentContainerView.safeAreaLayoutGuide.leadingAnchor),
			navigationView.trailingAnchor.constraint(equalTo: contentContainerView.safeAreaLayoutGuide.trailingAnchor)
		])

		navigationView.items = [
		]

		Theme.shared.register(client: self, applyImmediately: true)
	}

	open override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		navigationController?.isNavigationBarHidden = true
	}

	// MARK: - Push & Navigation
	open func push(viewController: UIViewController, completion: BrowserNavigationHistory.CompletionHandler? = nil) {
		push(item: BrowserNavigationItem(viewController: viewController), completion: completion)
	}

	open func push(item: BrowserNavigationItem, completion: BrowserNavigationHistory.CompletionHandler? = nil) {
		// Push to history (+ present)
		history.push(item: item)

		if hideSideBarInOverDisplayModeOnPush, sideBarDisplayMode == .over {
			setSideBarVisible(false, animated: true)
		}
	}

	open func moveBack(completion: BrowserNavigationHistory.CompletionHandler? = nil) {
		history.moveBack(completion: completion)
	}

	open func moveForward(completion: BrowserNavigationHistory.CompletionHandler? = nil) {
		history.moveForward(completion: completion)
	}

	// MARK: - View Controller presentation
	open override func addContentViewControllerSubview(_ contentViewControllerView: UIView) {
		contentContainerView.insertSubview(contentViewControllerView, at: 0)
	}

	open override func constraintsForEmbedding(contentViewController: UIViewController) -> [NSLayoutConstraint] {
		if let contentView = contentViewController.view {
			return [
				contentView.topAnchor.constraint(equalTo: navigationView.bottomAnchor),
				contentView.bottomAnchor.constraint(equalTo: contentContainerView.bottomAnchor),
				contentView.leadingAnchor.constraint(equalTo: contentContainerView.leadingAnchor),
				contentView.trailingAnchor.constraint(equalTo: contentContainerView.trailingAnchor)
			]
		}

		return []
	}

	@objc func showHideSideBar() {
		setSideBarVisible(!isSideBarVisible)
	}

	@objc func navBack() {
		moveBack()
	}

	@objc func navForward() {
		moveForward()
	}

	func buildSideBarToggleBarButtonItem() -> UIBarButtonItem {
		let buttonItem = UIBarButtonItem(image: OCSymbol.icon(forSymbolName: "sidebar.leading"), style: .plain, target: self, action: #selector(showHideSideBar))
		buttonItem.tag = BarButtonTags.showHideSideBar.rawValue
		return buttonItem
	}

	private enum BarButtonTags: Int {
		case mask = 0xC0FFEE0
		case showHideSideBar
		case backButton
		case forwardButton
	}

	func updateLeftBarButtonItems(for navigationItem: UINavigationItem, withToggleSideBar: Bool = false, withBackButton: Bool = false, withForwardButton: Bool = false) {
		let (_, existingItems) = navigationItem.navigationContent.items(withIdentifier: "browser-navigation-left")

		func reuseOrBuild(_ tag: BarButtonTags, _ build: () -> UIBarButtonItem) -> UIBarButtonItem {
			for barButtonItem in existingItems {
				if barButtonItem.tag == tag.rawValue {
					return barButtonItem
				}
			}

			return build()
		}

		var leadingButtons : [UIBarButtonItem] = []
		var sidebarButtons : [UIBarButtonItem] = []

		if withToggleSideBar {
			let item = reuseOrBuild(.showHideSideBar, {
				return buildSideBarToggleBarButtonItem()
			})

			sidebarButtons.append(item)
		}

		if withBackButton {
			let item = reuseOrBuild(.backButton, {
				let backButtonItem = UIBarButtonItem(image: OCSymbol.icon(forSymbolName: "chevron.backward"), style: .plain, target: self, action: #selector(navBack))
				backButtonItem.tag = BarButtonTags.backButton.rawValue

				return backButtonItem
			})

			item.isEnabled = history.canMoveBack

			leadingButtons.append(item)
		}

		if withForwardButton {
			let item = reuseOrBuild(.forwardButton, {
				let forwardButtonItem = UIBarButtonItem(image: OCSymbol.icon(forSymbolName: "chevron.forward"), style: .plain, target: self, action: #selector(navForward))
				forwardButtonItem.tag = BarButtonTags.forwardButton.rawValue

				return forwardButtonItem
			})

			item.isEnabled = history.canMoveForward

			leadingButtons.append(item)
		}

		let sideBarItem = NavigationContentItem(identifier: "browser-navigation-left", area: .left, priority: .standard, position: .leading, items: sidebarButtons)
		sideBarItem.visibleInPriorities = [ .standard, .high, .highest ]

		navigationItem.navigationContent.add(items: [
			sideBarItem,
			NavigationContentItem(identifier: "browser-navigation-left", area: .left, priority: .standard, position: .leading, items: leadingButtons)
		])
	}

	func updateContentNavigationItems() {
		if let contentNavigationItem = contentViewController?.navigationItem {
			updateLeftBarButtonItems(for: contentNavigationItem, withToggleSideBar: (effectiveSideBarDisplayMode == .sideBySide) ? !isSideBarVisible : true, withBackButton: true, withForwardButton: true)
		}

		updateSideBarNavigationItem()
	}

	// MARK: - BrowserNavigationHistoryDelegate
	public func present(item: BrowserNavigationItem?, with direction: BrowserNavigationHistory.Direction, completion: BrowserNavigationHistory.CompletionHandler?) {
		let needsSideBarLayout = (((item != nil) && (contentViewController == nil)) || ((item == nil) && (contentViewController != nil))) && (emptyHistoryBehaviour == .expandSideBarToFullWidth)

		if let item {
			// Has content
			let itemViewController = item.viewController

			contentViewController = itemViewController

			if let navigationItem = itemViewController?.navigationItem {
				updateContentNavigationItems()

				navigationView.items = [ navigationItem ]
			}
		} else {
			// Has no content
			contentViewController = nil
		}

		self.view.layoutIfNeeded()

		let done = {
			self.delegate?.browserNavigation(viewController: self, contentViewControllerDidChange: self.contentViewController)
			completion?(true)
		}

		if needsSideBarLayout {
			OnMainThread {
				UIView.animate(withDuration: 0.3, animations: {
					self.updateSideBarLayoutAndAppearance()
					self.view.layoutIfNeeded()
				}, completion: { _ in
					done()
				})
			}
		} else {
			done()
		}
	}

	// MARK: - Sidebar View Controller
	func updateSideBarNavigationItem() {
		var sideBarNavigationItem: UINavigationItem?

		if let sidebarViewController {
			// Add show/hide sidebar button to sidebar left items
			if let navigationController = sidebarViewController as? UINavigationController {
				sideBarNavigationItem = navigationController.topViewController?.navigationItem
			} else {
				sideBarNavigationItem = sidebarViewController.navigationItem
			}
		}

		if let sideBarNavigationItem {
			updateLeftBarButtonItems(for: sideBarNavigationItem, withToggleSideBar: (effectiveSideBarDisplayMode != .fullWidth))
		}
	}

	open var sidebarViewController: UIViewController? {
		willSet {
			sidebarViewController?.willMove(toParent: nil)
			sidebarViewController?.view.removeFromSuperview()
			sidebarViewController?.removeFromParent()
		}
		didSet {
			if let sidebarViewController, let sidebarViewControllerView = sidebarViewController.view {
				updateSideBarNavigationItem()

				addChild(sidebarViewController)
				view.insertSubview(sidebarViewControllerView, belowSubview: sideBarSeperatorView)
				sidebarViewControllerView.translatesAutoresizingMaskIntoConstraints = false
				updateSideBarLayoutAndAppearance()
				sidebarViewController.didMove(toParent: self)
			} else {
				updateSideBarLayoutAndAppearance()
			}
		}
	}

	// MARK: - Constraints, state & animation
	private var composedConstraints : [NSLayoutConstraint]? {
		willSet {
			if let composedConstraints {
				NSLayoutConstraint.deactivate(composedConstraints)
			}
		}
		didSet {
			if let composedConstraints {
				NSLayoutConstraint.activate(composedConstraints)
			}
		}
	}

	public enum SideBarDisplayMode {
		case fullWidth
		case sideBySide
		case over
	}

	public enum EmptyHistoryBehaviour {
		case none
		case expandSideBarToFullWidth
		case showEmptyHistoryViewController
	}

	public var isSideBarVisible: Bool = true {
		didSet {
			setNeedsStatusBarAppearanceUpdate()
		}
	}
	public var preferredSideBarWidth: CGFloat = 320
	var sideBarWidth: CGFloat = 320
	var preferredSideBarDisplayMode: SideBarDisplayMode?
	var sideBarDisplayMode: SideBarDisplayMode = .over {
		didSet {
			updateSideBarLayoutAndAppearance()
		}
	}

	var effectiveSideBarDisplayMode: SideBarDisplayMode {
		if history.isEmpty, emptyHistoryBehaviour == .expandSideBarToFullWidth {
			return .fullWidth
		}

		return sideBarDisplayMode
	}

	public var emptyHistoryBehaviour: EmptyHistoryBehaviour = .expandSideBarToFullWidth
	public var hideSideBarInOverDisplayModeOnPush: Bool = true

	open func setSideBarVisible(_ sideBarVisible: Bool, animated: Bool = true) {
		if isSideBarVisible == sideBarVisible {
			return
		}

		isSideBarVisible = sideBarVisible

		if animated {
			self.updateSideBarLayoutAndAppearance()

			if sideBarVisible {
				switch self.effectiveSideBarDisplayMode {
					case .over:
						self.contentContainerLidView.alpha = 0.0
						self.contentContainerLidView.isHidden = false
					default: break
				}
			}

			UIView.animate(withDuration: 0.25, animations: {
				if sideBarVisible {
					switch self.effectiveSideBarDisplayMode {
						case .over:
							self.contentContainerLidView.alpha = 1.0
						default: break
					}
				} else {
					self.contentContainerLidView.alpha = 0.0
				}
				self.sidebarViewController?.view.layoutIfNeeded()
				self.view.layoutIfNeeded()
			}, completion: { _ in
				if !sideBarVisible {
					self.contentContainerLidView.isHidden = true
				}
			})
		} else {
			updateSideBarLayoutAndAppearance()
		}
	}

	func updateSideBarLayoutAndAppearance() {
		var newConstraints : [NSLayoutConstraint] = []

		if let sidebarViewController, let sidebarView = sidebarViewController.view, let view {
			if isSideBarVisible {
				switch effectiveSideBarDisplayMode {
					case .fullWidth:
						// Sidebar occupies full area
						newConstraints = [
							sidebarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
							sidebarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
							sidebarView.topAnchor.constraint(equalTo: view.topAnchor),
							sidebarView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
						]

						contentContainerLidView.isHidden = true

					case .sideBySide:
						// Sidebar + Content side-by-side
						newConstraints = [
							sidebarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
							sidebarView.trailingAnchor.constraint(equalTo: contentContainerView.leadingAnchor, constant: 0),
							sidebarView.topAnchor.constraint(equalTo: view.topAnchor),
							sidebarView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
							sidebarView.widthAnchor.constraint(equalToConstant: sideBarWidth)
						]

						contentContainerLidView.isHidden = true

					case .over:
						// Sidebar over content
						newConstraints = [
							sidebarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
							sidebarView.topAnchor.constraint(equalTo: view.topAnchor),
							sidebarView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
							sidebarView.widthAnchor.constraint(equalToConstant: sideBarWidth)
						]

						contentContainerLidView.isHidden = false
				}
			} else {
				// Position sidebar left outside of view
				newConstraints = [
					sidebarView.trailingAnchor.constraint(equalTo: view.leadingAnchor),
					sidebarView.topAnchor.constraint(equalTo: view.topAnchor),
					sidebarView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
					sidebarView.widthAnchor.constraint(equalToConstant: sideBarWidth)
				]
			}
		}

		updateContentNavigationItems()

		composedConstraints = newConstraints
	}

	// MARK: - Themeing
	public func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		navigationView.applyThemeCollection(collection)
		view.apply(css: collection.css, properties: [.fill])
	}

	public var cssAutoSelectors: [ThemeCSSSelector] = [.splitView]

	// MARK: - Status Bar style
	open override var preferredStatusBarStyle: UIStatusBarStyle {
		var statusBarStyle: UIStatusBarStyle?

		if isSideBarVisible, let sidebarViewController {
			statusBarStyle = Theme.shared.activeCollection.css.getStatusBarStyle(for: sidebarViewController)
		} else if let contentViewController {
			statusBarStyle = Theme.shared.activeCollection.css.getStatusBarStyle(for: contentViewController)
		}

		if statusBarStyle == nil {
			statusBarStyle = Theme.shared.activeCollection.css.getStatusBarStyle(for: self)
		}

		return statusBarStyle ?? super.preferredStatusBarStyle
	}

	open override var childForStatusBarStyle: UIViewController? {
		return nil
	}
}

extension BrowserNavigationViewController: UINavigationBarDelegate {
	public func position(for bar: UIBarPositioning) -> UIBarPosition {
		return .topAttached
	}
}
