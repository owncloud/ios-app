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

import SnapKit
import UIKit
import ownCloudSDK

public protocol BrowserNavigationViewControllerDelegate: AnyObject {
	func browserNavigation(
		viewController: BrowserNavigationViewController,
		contentViewControllerDidChange: UIViewController?)
}

public protocol ScrollViewProviding: AnyObject {
	var providedScrollView: UIScrollView? { get }
}

open class BrowserNavigationViewController: EmbeddingViewController, Themeable, BrowserNavigationHistoryDelegate, ThemeCSSAutoSelector {
	lazy var contentContainerView: UIView = {
		let view = UIView()
		view.cssSelector = .content
		view.focusGroupIdentifier = "com.owncloud.content"
		return view
	}()

	lazy var wrappedContentContainerView: UIView = {
		contentContainerView.withScreenshotProtection
	}()

	lazy var navigationView: UINavigationBar = {
		let navigationView = UINavigationBar()
		navigationView.delegate = self
		return navigationView
	}()

	// Container placed directly under the navigation bar to host contextual accessories (e.g., location breadcrumb bar)
	lazy var topAccessoryContainerView: UIStackView = {
		let stackView = UIStackView()
		stackView.axis = .vertical
		stackView.spacing = 0
		stackView.distribution = .fill
		return stackView
	}()

	// Holds the currently installed accessory view controller
	private var topAccessoryViewController: ClientLocationBarController?
	private lazy var topAccessoryView = {
		let view = UIView()
		view.isHidden = true
		return view
	}()

	lazy var navArrowsStackView: UIStackView = {
		let sv = UIStackView()
		sv.axis = .horizontal
		sv.alignment = .center
		sv.spacing = 12
		return sv
	}()

	private var backButton: UIButton = UIButton(type: .system)
	private var forwardButton: UIButton = UIButton(type: .system)
	private var hasNavigationHistory: Bool = false

	lazy var contentContainerLidView: UIView = {
		let view = UIView()
		view.backgroundColor = UIColor(white: 0.0, alpha: 0.5)
		view.isHidden = true
		view.addGestureRecognizer(UITapGestureRecognizer(
			target: self,
			action: #selector(showHideSideBar)
		))
		return view
	}()

	private var isTabBarHidden: Bool = false
	var tabBarView = HCBrowserNavigationTabBarView()
	var sideBarSeperatorView = HCSeparatorView(frame: .zero)

	private var hasCompletedInitialLayout: Bool = false

	lazy open var history: BrowserNavigationHistory = {
		let history = BrowserNavigationHistory()
		history.delegate = self
		return history
	}()

	weak open var delegate: BrowserNavigationViewControllerDelegate?
	open var clientContextProvider: (() -> ClientContext?)?
	open var accountControllerProvider: ((UUID) -> AccountController?)?

	// MARK: - "Finding network…" toast
	private var networkAvailabilityToastView: NetworkAvailabilityToastView?

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
		setContainerLidHidden(isSideBarHidden || effectiveSideBarDisplayMode != .over, animated: hasCompletedInitialLayout)
	}

	open override func viewDidLoad() {
		super.viewDidLoad()

		contentContainerView.addSubview(navigationView)
		contentContainerView.addSubview(topAccessoryContainerView)

		view.addSubview(wrappedContentContainerView)
		view.addSubview(tabBarView)
		view.addSubview(contentContainerLidView)
		view.addSubview(sideBarSeperatorView)

		contentContainerLidView.snp.remakeConstraints {
			$0.top.leading.trailing.equalToSuperview()
			$0.bottom.equalTo(view.keyboardLayoutGuide.snp.top)
		}

		setupTabBar()
		setTabBarHidden(traitCollection.verticalSizeClass == .compact, animated: false)
		navigationView.items = []

		let accessoryVC = ClientLocationBarController()
		addChild(accessoryVC)
		topAccessoryView.addSubview(accessoryVC.view)
		accessoryVC.didMove(toParent: self)
		topAccessoryViewController = accessoryVC

		// Layout accessory container just below the navigation bar; keep height 0 when empty
		topAccessoryContainerView.snp.remakeConstraints {
			$0.leading.trailing.equalTo(self.contentContainerView.safeAreaLayoutGuide)
			$0.top.equalTo(self.navigationView.snp.bottom)
		}

		topAccessoryView.backgroundColor = .clear
		topAccessoryView.snp.makeConstraints {
			$0.height.equalTo(40)
		}
		topAccessoryView.addSubview(navArrowsStackView)
		navArrowsStackView.snp.makeConstraints {
			$0.top.bottom.equalToSuperview()
			$0.leading.equalToSuperview().offset(12)
		}

		accessoryVC.view.snp.makeConstraints {
			$0.top.bottom.equalToSuperview()
			$0.leading.equalTo(navArrowsStackView.snp.trailing).offset(10)
			$0.trailing.equalToSuperview().offset(-12)
		}
		topAccessoryContainerView.addArrangedSubview(topAccessoryView)

		setupHistoryButtons()
		setupNetworkAvailabilityToast()
		updateDynamicLayout()
		view.layoutIfNeeded()
	}

	private func setupNetworkAvailabilityToast() {
		let toast = NetworkAvailabilityToastView(message: HCL10n.Network.findingNetwork)
		toast.alpha = 0
		toast.isHidden = true
		toast.onDismiss = { [weak self] in
			guard let self else { return }
			Task { await HCContext.shared.networkAvailabilityMonitor.dismiss() }
			self.setNetworkAvailabilityToastVisible(nil, animated: true)
		}
		networkAvailabilityToastView = toast

		contentContainerView.addSubview(toast)
		toast.snp.makeConstraints { make in
			make.centerX.equalTo(contentContainerView.safeAreaLayoutGuide)
			make.leading.greaterThanOrEqualTo(contentContainerView.safeAreaLayoutGuide).offset(16)
			make.trailing.lessThanOrEqualTo(contentContainerView.safeAreaLayoutGuide).offset(-16)
			make.bottom.equalTo(contentContainerView.safeAreaLayoutGuide).offset(-16)
		}

		Task { @MainActor [weak self] in
			await HCContext.shared.networkAvailabilityMonitor.observeToastVisibility { [weak self] kind in
				self?.setNetworkAvailabilityToastVisible(kind, animated: true)
			}
		}
	}

	private func setNetworkAvailabilityToastVisible(_ kind: NetworkAvailabilityToastKind?, animated: Bool) {
		guard let toast = networkAvailabilityToastView else { return }

		// Keep the toast above any content that gets inserted into contentContainerView later.
		contentContainerView.bringSubviewToFront(toast)

		if let kind {
			let message: String
			switch kind {
				case .findingNetwork: message = HCL10n.Network.findingNetwork
				case .noInternet:     message = HCL10n.Network.noInternet
			}
			toast.setMessage(message)
		}

		let visible = kind != nil
		let apply = { toast.alpha = visible ? 1.0 : 0.0 }

		if visible { toast.isHidden = false }

		if animated {
			UIView.animate(withDuration: 0.25, delay: 0, options: [.beginFromCurrentState, .curveEaseInOut], animations: apply, completion: { _ in
				if !visible { toast.isHidden = true }
			})
		} else {
			apply()
			if !visible { toast.isHidden = true }
		}
	}

	private func updateDynamicLayout() {
		guard let sidebarView, let view, sidebarView.superview != nil else { return }

		sidebarView.snp.remakeConstraints {
			guard !isSideBarHidden else {
				$0.trailing.equalTo(view.snp.leading)
				$0.top.equalToSuperview()
				if UIDevice.current.isIpad {
					$0.bottom.equalTo(tabBarView.snp.top)
				} else {
					$0.bottom.equalTo(view.keyboardLayoutGuide.snp.top)
				}
				$0.width.equalTo(sideBarWidth)
				return
			}

			switch effectiveSideBarDisplayMode {
				case .fullWidth:
					$0.leading.trailing.top.equalToSuperview()
					$0.bottom.equalTo(view.keyboardLayoutGuide.snp.top)

				case .sideBySide, .over:
					$0.leading.top.equalToSuperview()
					$0.width.equalTo(sideBarWidth)
					if UIDevice.current.isIpad {
						$0.bottom.equalTo(tabBarView.snp.top)
					} else {
						if effectiveSideBarDisplayMode == .sideBySide {
							$0.bottom.equalToSuperview()
						} else {
							$0.bottom.equalTo(view.safeAreaLayoutGuide)
						}
					}
			}
		}
		tabBarView.snp.remakeConstraints {
			if isTabBarHidden {
				$0.top.equalTo(view.snp.bottom)
			} else {
				$0.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
			}
			if !UIDevice.current.isIpad && effectiveSideBarDisplayMode == .sideBySide {
				$0.leading.equalTo(sidebarView.snp.trailing).priority(.high)
			} else {
				$0.leading.equalTo(view.snp.leading).priority(.high)
			}
			$0.top.equalTo(wrappedContentContainerView.snp.bottom)
			$0.trailing.equalTo(view.snp.trailing)
			$0.height.equalTo(68)
		}

		wrappedContentContainerView.snp.remakeConstraints {
			guard !isSideBarHidden else {
				$0.top.leading.trailing.equalToSuperview()
				return
			}

			switch effectiveSideBarDisplayMode {
				case .fullWidth:
					$0.top.leading.trailing.equalToSuperview()

				case .sideBySide:
					$0.top.trailing.equalToSuperview()
					$0.leading.equalTo(sidebarView.snp.trailing).offset(-1)

				case .over:
					$0.top.trailing.equalToSuperview()
					$0.leading.equalTo(view.snp.leading)
			}
		}

		sideBarSeperatorView.snp.remakeConstraints {
			$0.top.equalToSuperview()
			$0.trailing.equalTo(sidebarView.snp.trailing)
			$0.width.equalTo(1)
			if UIDevice.current.isIpad {
				$0.bottom.equalTo(tabBarView.snp.top)
			} else {
				$0.bottom.equalToSuperview()
			}
		}

		switch effectiveSideBarDisplayMode {
			case .fullWidth, .over:
				sideBarSeperatorView.isHidden = true

			case .sideBySide:
				sideBarSeperatorView.isHidden = false
		}
	}

	private func setupTabBar() {
		tabBarView.onTabSelected = { [weak self] tab in
			guard
				let self,
				let tab
			else { return }

			guard
				let bookmarkUUID = OCBookmarkManager.shared.bookmarks.first?.uuid,
				let accountController = accountControllerProvider?(bookmarkUUID)
			else { return }

			let context = accountController.clientContext

			switch tab {
				case .files:
					if let currentItem = history.currentItem {
						history.lastPushAttempt = currentItem
						present(item: currentItem, with: .none, completion: nil)
					}

				case .search:
					let item = CollectionSidebarAction(
						with: "", icon: nil,
						viewControllerProvider: { (context, action) in
							accountController.provideViewController(for: .globalSearch, in: context)
						},
						cacheViewControllers: false
					)

					_ = item.openItem(
						from: self,
						with: context,
						animated: true,
						pushViewController: true
					) { _ in }

				case .status:
					let item = CollectionSidebarAction(
						with: "", icon: nil,
						viewControllerProvider: { (context, action) in
							accountController.provideViewController(for: .activity, in: context)
						}, cacheViewControllers: false)

					_ = item.openItem(
						from: self,
						with: context,
						animated: true,
						pushViewController: true
					) { _ in }

				case .offline:
					let item = CollectionSidebarAction(
						with: "", icon: nil,
						viewControllerProvider: { (context, action) in
							accountController.provideViewController(for: .availableOfflineItems, in: context)
						}, cacheViewControllers: false)

					_ = item.openItem(
						from: self,
						with: context,
						animated: true,
						pushViewController: true
					) { _ in }
			}
		}
	}

	private var _themeRegistered = false
	open override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		if !_themeRegistered {
			_themeRegistered = true
			Theme.shared.register(client: self, applyImmediately: true)
		}
	}

	open override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		navigationController?.isNavigationBarHidden = true

		setNavigationBarHidden(false, animated: false)

		// Enable animations after first appearance to avoid launch-time reflow animations
		hasCompletedInitialLayout = true

		// Observe DisplayHost location changes (cross-target safe via notification)
		NotificationCenter.default.addObserver(self, selector: #selector(handleDisplayHostLocationDidChange(_:)), name: Notification.Name("DisplayHostLocationDidChange"), object: nil)
	}

	@objc private func
	handleDisplayHostLocationDidChange(_ note: Notification) {
		self.updateNavigation()
	}

	// MARK: - Navigation Bar
	open func setNavigationBarHidden(
		_ hidden: Bool,
		animated: Bool,
		completion: (() -> Void)? = nil
	) {
		let updateLayout = {
			self.navigationView.snp.remakeConstraints {
				$0.leading.trailing.equalTo(self.contentContainerView.safeAreaLayoutGuide)
				if hidden {
					$0.bottom.equalTo(self.contentContainerView.snp.top)
				} else {
					$0.top.equalTo(self.contentContainerView.safeAreaLayoutGuide.snp.top)
				}
			}
		}

		OnMainThread(inline: true) {
			if animated {
				UIView.animate(
					withDuration: 0.3,
					animations: {
						updateLayout()
						self.view.layoutIfNeeded()
					},
					completion: { _ in
						completion?()
					})
			} else {
				updateLayout()
				completion?()
			}
		}
	}

	// MARK: - Push & Navigation
	open func push(
		viewController: UIViewController,
		completion: BrowserNavigationHistory.CompletionHandler? = nil
	) {
		push(item: BrowserNavigationItem(viewController: viewController), completion: completion)
	}

	open func deleteCurrent(
		completion: BrowserNavigationHistory.CompletionHandler? = nil
	) {
		history.deleteCurrent(completion: completion)
	}

	open func push(
		item: BrowserNavigationItem, completion: BrowserNavigationHistory.CompletionHandler? = nil
	) {
		// Push to history (+ present)
		history.push(item: item)

		if hideSideBarInOverDisplayModeOnPush, sideBarDisplayMode == .over {
			setSideBarHidden(true, animated: hasCompletedInitialLayout)
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
		// Newly inserted content goes to the back, but make sure the network toast (if installed)
		// stays on top of any content view.
		if let toast = networkAvailabilityToastView, toast.superview === contentContainerView {
			contentContainerView.bringSubviewToFront(toast)
		}
	}

	open override func constraintsForEmbedding(contentViewController: UIViewController)
		-> [NSLayoutConstraint] {
		if let contentView = contentViewController.view {
			return [
				contentView.topAnchor.constraint(equalTo: topAccessoryContainerView.bottomAnchor),
				contentView.bottomAnchor.constraint(equalTo: contentContainerView.bottomAnchor),
				contentView.leadingAnchor.constraint(equalTo: contentContainerView.leadingAnchor),
				contentView.trailingAnchor.constraint(equalTo: contentContainerView.trailingAnchor)
			]
		}

		return []
	}

	@objc func showHideSideBar() {
		setSideBarHidden(!isSideBarHidden)

		if let nc = sidebarViewController as? ThemeNavigationController,
		   let sidebarViewController = nc.viewControllers.first as? ClientSidebarViewController {
			sidebarViewController.updateAvailableSpace()
		}
	}

	@objc func navBack() {
		moveBack()
	}

	@objc func navForward() {
		moveForward()
	}

	private func setupHistoryButtons() {
		// Configure buttons
		backButton.setImage(UIImage(named: "arrow-left", in: Bundle.sharedAppBundle, with: nil), for: .normal)
		forwardButton.setImage(UIImage(named: "arrow-right", in: Bundle.sharedAppBundle, with: nil), for: .normal)
		backButton.addTarget(self, action: #selector(navBack), for: .touchUpInside)
		forwardButton.addTarget(self, action: #selector(navForward), for: .touchUpInside)
		backButton.accessibilityLabel = OCLocalizedString("Back", nil)
		forwardButton.accessibilityLabel = OCLocalizedString("Forward", nil)

		// Add to stack
		navArrowsStackView.addArrangedSubview(backButton)
		navArrowsStackView.addArrangedSubview(forwardButton)

		updateHistoryButtons()
	}

	private func updateHistoryButtons() {
		let hasNavigation = !(history.lastPushAttempt?.isSpecialTabBarItem ?? false)
		backButton.isEnabled = hasNavigation && history.canMoveBack
		forwardButton.isEnabled = hasNavigation && history.canMoveForward
		// Show or hide the arrows stack depending on need
		navArrowsStackView.isHidden = false
	}

	private func previousHistoryItemTitle() -> String? {
		let previousPosition = history.position - 1
		guard previousPosition >= 0, previousPosition < history.items.count else { return nil }
		let previousVC = history.items[previousPosition].viewControllerIfLoaded
		return previousVC?.navigationItem.title ?? previousVC?.title
	}

	private func buildBackBarButtonItem(title: String?) -> UIBarButtonItem {
		var configuration = UIButton.Configuration.plain()
		configuration.image = OCSymbol.icon(forSymbolName: "chevron.backward")
		configuration.title = title
		configuration.imagePadding = 4
		configuration.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 8)

		let button = UIButton(configuration: configuration, primaryAction: UIAction { [weak self] _ in
			self?.navBack()
		})
		button.contentHorizontalAlignment = .leading

		let backButtonItem = UIBarButtonItem(customView: button)
		backButtonItem.tag = BarButtonTags.backButton.rawValue
		return backButtonItem
	}

	func buildSideBarToggleBarButtonItem() -> UIBarButtonItem {
		let buttonItem = UIBarButtonItem(
			image: OCItem.hanurgerMenu, style: .plain, target: self,
			action: #selector(showHideSideBar))
		buttonItem.tag = BarButtonTags.showHideSideBar.rawValue
		buttonItem.accessibilityLabel = OCLocalizedString("Show/Hide sidebar", nil)
		return buttonItem
	}

	private enum BarButtonTags: Int {
		case mask = 0xC0FFEE0
		case showHideSideBar
		case backButton
		case forwardButton
	}

	func updateLeftBarButtonItems(
		for navigationItem: UINavigationItem, withToggleSideBar: Bool = false,
		withBackButton: Bool = false, withForwardButton: Bool = false
	) {
		let (_, existingItems) = navigationItem.navigationContent.items(
			withIdentifier: "browser-navigation-left")

		func reuseOrBuild(_ tag: BarButtonTags, _ build: () -> UIBarButtonItem) -> UIBarButtonItem {
			for barButtonItem in existingItems {
				if barButtonItem.tag == tag.rawValue {
					return barButtonItem
				}
			}

			return build()
		}

		var leadingButtons: [UIBarButtonItem] = []
		var sidebarButtons: [UIBarButtonItem] = []

		if withToggleSideBar {
			let item = reuseOrBuild(
				.showHideSideBar,
				{
					return buildSideBarToggleBarButtonItem()
				})

			sidebarButtons.append(item)
		}

		if withBackButton {
			let previousTitle = previousHistoryItemTitle()

			let item = reuseOrBuild(
				.backButton,
				{
					return buildBackBarButtonItem(title: previousTitle)
				})

			if let button = item.customView as? UIButton {
				var configuration = button.configuration ?? UIButton.Configuration.plain()
				configuration.title = previousTitle
				button.configuration = configuration
			}

			item.isEnabled = history.canMoveBack

			leadingButtons.append(item)
		}

		if withForwardButton {
			let item = reuseOrBuild(
				.forwardButton,
				{
					let forwardButtonItem = UIBarButtonItem(
						image: OCSymbol.icon(forSymbolName: "chevron.forward"), style: .plain,
						target: self, action: #selector(navForward))
					forwardButtonItem.tag = BarButtonTags.forwardButton.rawValue

					return forwardButtonItem
				})

			item.isEnabled = history.canMoveForward

			leadingButtons.append(item)
		}

		let sideBarItem = NavigationContentItem(
			identifier: "browser-navigation-left", area: .left, priority: .standard,
			position: .leading, items: sidebarButtons)
		sideBarItem.visibleInPriorities = [.standard, .high, .highest]

		navigationItem.navigationContent.add(items: [
			sideBarItem,
			NavigationContentItem(
				identifier: "browser-navigation-left", area: .left, priority: .standard,
				position: .leading, items: leadingButtons)
		])
	}

	func updateContentNavigationItems() {
		if let contentNavigationItem = contentViewController?.navigationItem {
			let hasHistoryBack = history.canMoveBack
				&& !(history.lastPushAttempt?.isSpecialTabBarItem ?? true)
			let shouldShowSidebarToggle = hasHistoryBack
				? false
				: ((effectiveSideBarDisplayMode == .sideBySide) ? isSideBarHidden : true)

			updateLeftBarButtonItems(
				for: contentNavigationItem,
				withToggleSideBar: shouldShowSidebarToggle,
				withBackButton: hasHistoryBack)
		}

		updateHistoryButtons()
		updateSideBarNavigationItem()
	}

	func updateTabBar() {
		guard let lastPushAttempt = history.lastPushAttempt else { return }
		if !lastPushAttempt.isSpecialTabBarItem { // Files
			tabBarView.selectedTab = .files
			return
		}
		guard let specialItem = lastPushAttempt.navigationBookmark?.specialItem else { return }

		switch specialItem {
			case .availableOfflineItems:
				tabBarView.selectedTab = .offline
			case .globalSearch:
				tabBarView.selectedTab = .search
			case .activity:
				tabBarView.selectedTab = .status
			default:
				break
		}
	}

	// MARK: - BrowserNavigationHistoryDelegate

	public func updateNavigation() {
		if let navigationItem = contentViewController?.navigationItem {
			updateContentNavigationItems()

			navigationView.items = [ navigationItem ]
		}

		updateTopAccessory()
	}

	// MARK: - Top accessory (breadcrumb) management
	open func updateTopAccessory() {
		topAccessoryView.isHidden = true
		topAccessoryViewController?.clientContext = nil
		topAccessoryViewController?.location = nil

		// Install a location bar when the content is a ClientItemViewController with a non-root location
		if let itemVC = contentViewController as? ClientItemViewController, let clientContext = itemVC.clientContext {
			guard
				!(history.lastPushAttempt?.isSpecialTabBarItem ?? true),
				itemVC.query?.queryLocation != nil
			else { return }
			var effectiveLocation: OCLocation?
			if let loc = itemVC.location {
				effectiveLocation = loc
			} else if let queryLoc = itemVC.query?.queryLocation {
				effectiveLocation = queryLoc
			} else if let rootItem = clientContext.rootItem as? OCItem {
				effectiveLocation = rootItem.location
			}

			if let location = effectiveLocation, history.items.count > 1 {
				topAccessoryViewController?.clientContext = clientContext
				topAccessoryViewController?.location = location
				topAccessoryView.isHidden = false
			}
		} else if let displayHost = contentViewController as? DisplayHostType {
			topAccessoryViewController?.clientContext = displayHost.clientContext
			topAccessoryViewController?.location = displayHost.location
			topAccessoryView.isHidden = false
		}

		view.setNeedsLayout()
		view.layoutIfNeeded()
	}

	public func present(
		item: BrowserNavigationItem?, with direction: BrowserNavigationHistory.Direction,
		completion: BrowserNavigationHistory.CompletionHandler?
	) {
		let needsSideBarLayout =
			(((item != nil) && (contentViewController == nil))
				|| ((item == nil) && (contentViewController != nil)))
			&& (emptyHistoryBehaviour == .expandSideBarToFullWidth)

		if let item {
			// Has content
			let itemViewController = item.viewController

			contentViewController = itemViewController

			if let navigationItem = itemViewController?.navigationItem {
				updateContentNavigationItems()

				navigationView.items = [navigationItem]
			}
		} else {
			// Has no content
			contentViewController = nil
		}

		updateTopAccessory()

		self.view.layoutIfNeeded()

		let done = {
			self.delegate?.browserNavigation(
				viewController: self, contentViewControllerDidChange: self.contentViewController)
			self.updateTabBar()
			DispatchQueue.main.async { self.applyScrollabilityCheckForCurrentContent() }
			completion?(true)
		}

		if needsSideBarLayout {
			if hasCompletedInitialLayout {
				OnMainThread {
					UIView.animate(
						withDuration: 0.3,
						animations: {
							self.updateSideBarLayoutAndAppearance()
							self.view.layoutIfNeeded()
						},
						completion: { _ in
							done()
						})
				}
			} else {
				self.updateSideBarLayoutAndAppearance()
				self.view.layoutIfNeeded()
				done()
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
			updateLeftBarButtonItems(
				for: sideBarNavigationItem,
				withToggleSideBar: (effectiveSideBarDisplayMode != .fullWidth))
		}
	}

	var sidebarView: UIView?

	open var sidebarViewController: UIViewController? {
		willSet {
			sidebarViewController?.willMove(toParent: nil)
			sidebarViewController?.view.removeFromSuperview()
			sidebarViewController?.removeFromParent()
		}
		didSet {
			if let sidebarViewController, let sidebarViewControllerView = sidebarViewController.view {
				sidebarViewController.focusGroupIdentifier = "com.owncloud.sidebar"

				updateSideBarNavigationItem()
				sidebarView = sidebarViewControllerView
				addChild(sidebarViewController)
				view.addSubview(sidebarViewControllerView)
				sidebarViewControllerView.translatesAutoresizingMaskIntoConstraints = false
				updateSideBarLayoutAndAppearance()
				sidebarViewController.didMove(toParent: self)
			} else {
				updateSideBarLayoutAndAppearance()
			}
			view.bringSubviewToFront(sideBarSeperatorView)
		}
	}

	// MARK: - Constraints, state & animation

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

	public var isSideBarHidden: Bool = true {
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

	public var emptyHistoryBehaviour: EmptyHistoryBehaviour = .none
	public var hideSideBarInOverDisplayModeOnPush: Bool = true

	func setTabBarHidden(_ isHidden: Bool, animated: Bool = true) {
		let animations = {
			self.updateDynamicLayout()
			self.tabBarView.layoutIfNeeded()
		}

		let completion: (Bool) -> Void = { _ in

		}

		updateDynamicLayout()
		self.isTabBarHidden = isHidden
		if animated {
			UIView.animate(withDuration: 0.3, animations: animations, completion: completion)
		} else {
			animations()
			completion(true)
		}
	}

	func setContainerLidHidden(_ isHidden: Bool, animated: Bool = true) {
		guard contentContainerLidView.isHidden != isHidden else { return }

		let animations = {
			self.contentContainerLidView.alpha = isHidden ? 0.0 : 1.0
		}

		let completion: (Bool) -> Void = { _ in
			self.contentContainerLidView.isHidden = isHidden
		}

		self.contentContainerLidView.alpha = isHidden ? 1.0 : 0.0
		if !isHidden {
			self.contentContainerLidView.isHidden = false
		}

		if animated {
			UIView.animate(withDuration: 0.3, animations: animations, completion: completion)
		} else {
			animations()
			completion(true)
		}
	}

	open func setSideBarHidden(_ isHidden: Bool, animated: Bool = true) {
		let animations = {
			self.updateSideBarLayoutAndAppearance()
			self.sidebarViewController?.view.layoutIfNeeded()
			self.view.layoutIfNeeded()
		}

		let completion: (Bool) -> Void = { _ in

		}
		self.updateSideBarLayoutAndAppearance()
		self.isSideBarHidden = isHidden
		let shouldAnimate = animated && hasCompletedInitialLayout
		if shouldAnimate {
			UIView.animate(withDuration: 0.3, animations: animations, completion: completion)
		} else {
			animations()
			completion(true)
		}
	}

	func updateSideBarLayoutAndAppearance() {
		updateDynamicLayout()

		updateContentNavigationItems()
	}

	// MARK: - Themeing
	public func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		navigationView.applyThemeCollection(collection)
		view.apply(css: collection.css, properties: [.fill])

		forwardButton.apply(css: collection.css, selectors: [.content, .toolbar, .locationBar, .button], properties: [.stroke])
		backButton.apply(css: collection.css, selectors: [.content, .toolbar, .locationBar, .button], properties: [.stroke])
	}

	public var cssAutoSelectors: [ThemeCSSSelector] = [.splitView]

	// MARK: - Status Bar style
	open override var preferredStatusBarStyle: UIStatusBarStyle {
		var statusBarStyle: UIStatusBarStyle?

		if !isSideBarHidden, let sidebarViewController {
			statusBarStyle = Theme.shared.activeCollection.css.getStatusBarStyle(
				for: sidebarViewController)
		} else if let contentViewController {
			statusBarStyle = Theme.shared.activeCollection.css.getStatusBarStyle(
				for: contentViewController)
		}

		if statusBarStyle == nil {
			statusBarStyle = Theme.shared.activeCollection.css.getStatusBarStyle(for: self)
		}

		return statusBarStyle ?? super.preferredStatusBarStyle
	}

	open override var childForStatusBarStyle: UIViewController? {
		nil
	}

	open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
		let isPhone = traitCollection.userInterfaceIdiom == .phone
		let isLandscape = traitCollection.verticalSizeClass == .compact

		if isLandscape && isPhone {
			setTabBarHidden(true, animated: hasCompletedInitialLayout)
			setNavigationBarHidden(true, animated: hasCompletedInitialLayout)

			let runScrollabilityCheck = { [weak self] in
				self?.view.layoutIfNeeded()
				guard let self, !self.isContentScrollable else { return }
				self.setTabBarHidden(false)
				self.setNavigationBarHidden(false, animated: true)
			}

			if let coordinator = transitionCoordinator {
				coordinator.animate(alongsideTransition: nil) { _ in runScrollabilityCheck() }
			} else {
				DispatchQueue.main.async { runScrollabilityCheck() }
			}
		} else {
			setTabBarHidden(false, animated: hasCompletedInitialLayout)
			setNavigationBarHidden(false, animated: hasCompletedInitialLayout)
		}
	}

	func applyScrollabilityCheckForCurrentContent() {
		guard traitCollection.userInterfaceIdiom == .phone,
		      traitCollection.verticalSizeClass == .compact else { return }

		view.layoutIfNeeded()
		if isContentScrollable {
			setTabBarHidden(true)
			setNavigationBarHidden(true, animated: true)
		} else {
			setTabBarHidden(false)
			setNavigationBarHidden(false, animated: true)
		}
	}

	private var isContentScrollable: Bool {
		guard let scrollView = contentScrollView() else { return false }
		return scrollView.contentSize.height > scrollView.bounds.height
	}

	private func contentScrollView() -> UIScrollView? {
		(contentViewController as? ScrollViewProviding)?.providedScrollView
	}

	func notifyScroll(_ direction: HCScrollDirectionProcessor.ScrollDirection) {
		let isPhone = traitCollection.userInterfaceIdiom == .phone
		let isLandscape = traitCollection.verticalSizeClass == .compact

		guard isPhone && isLandscape else { return }

		switch direction {
			case .down:
				setTabBarHidden(true)
				setNavigationBarHidden(true, animated: true)
			case .up:
				setTabBarHidden(false)
				setNavigationBarHidden(false, animated: true)
			case .none:
				break
		}
	}
}

extension BrowserNavigationViewController: UINavigationBarDelegate {
	public func position(for bar: UIBarPositioning) -> UIBarPosition {
		.topAttached
	}
}

extension UIViewController {
	public var browserNavigationViewController: BrowserNavigationViewController? {
		var viewController: UIViewController? = self
		while viewController != nil {
			if let browserNavigationViewController = viewController as? BrowserNavigationViewController {
				return browserNavigationViewController
			}
			viewController = viewController?.parent
		}
		return nil
	}
}
