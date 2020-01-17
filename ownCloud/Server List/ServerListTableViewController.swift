//
//  ServerListTableViewController.swift
//  ownCloud
//
//  Created by Felix Schwarz on 08.03.18.
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
import ownCloudSDK
import PocketSVG

class ServerListTableViewController: UITableViewController, Themeable {
	// MARK: - Views
	@IBOutlet var welcomeOverlayView: UIView!
	@IBOutlet var welcomeTitleLabel : UILabel!
	@IBOutlet var welcomeMessageLabel : UILabel!
	@IBOutlet var welcomeAddServerButton : ThemeButton!
	@IBOutlet var welcomeLogoImageView : UIImageView!
	@IBOutlet var welcomeLogoTVGView : VectorImageView!
	// @IBOutlet var welcomeLogoSVGView : SVGImageView!

	// MARK: - Internals
	var shownFirstTime = true
	var hasToolbar : Bool = true

	// MARK: - Init
	override init(style: UITableView.Style) {
		super.init(style: style)

		NotificationCenter.default.addObserver(self, selector: #selector(serverListChanged), name: .OCBookmarkManagerListChanged, object: nil)
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	deinit {
		NotificationCenter.default.removeObserver(self, name: .OCBookmarkManagerListChanged, object: nil)
		NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
	}

	// TODO: Rebuild welcomeOverlayView in code
	/*
	override func loadView() {
	super.loadView()

	welcomeOverlayView = UIView()
	welcomeOverlayView.translatesAutoresizingMaskIntoConstraints = false

	welcomeTitleLabel = UILabel()
	welcomeTitleLabel.font = UIFont.boldSystemFont(ofSize: 34)
	welcomeTitleLabel.translatesAutoresizingMaskIntoConstraints = false

	welcomeAddServerButton = ThemeButton()
	}
	*/

	// MARK: - View controller events
	override func viewDidLoad() {
		super.viewDidLoad()

		OCItem.registerIcons()

		self.navigationController?.navigationBar.prefersLargeTitles = true
		self.navigationController?.navigationBar.isTranslucent = false
		self.navigationController?.toolbar.isTranslucent = false
		self.tableView.register(ServerListBookmarkCell.self, forCellReuseIdentifier: "bookmark-cell")
		self.tableView.rowHeight = UITableView.automaticDimension
		self.tableView.estimatedRowHeight = 80
		self.tableView.allowsSelectionDuringEditing = true
 		extendedLayoutIncludesOpaqueBars = true

		if VendorServices.shared.canAddAccount {
			let addServerBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.add, target: self, action: #selector(addBookmark))
			addServerBarButtonItem.accessibilityLabel = "Add account".localized
			addServerBarButtonItem.accessibilityIdentifier = "addAccount"
			self.navigationItem.rightBarButtonItem = addServerBarButtonItem
		}

		if welcomeOverlayView != nil {
			welcomeOverlayView.translatesAutoresizingMaskIntoConstraints = false
		}

		self.navigationItem.title = VendorServices.shared.appName

		NotificationCenter.default.addObserver(self, selector: #selector(considerAutoLogin), name: UIApplication.didBecomeActiveNotification, object: nil)
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		if hasToolbar {
			self.navigationController?.setToolbarHidden(false, animated: animated)
		}
		self.navigationController?.navigationBar.prefersLargeTitles = true

		Theme.shared.register(client: self)

		if welcomeOverlayView != nil {
			welcomeOverlayView.layoutSubviews()
		}

		self.tableView.reloadData()
	}

	override func viewDidAppear(_ animated: Bool) {
		var showBetaWarning = VendorServices.shared.showBetaWarning

		super.viewDidAppear(animated)

		updateNoServerMessageVisibility()

		let helpBarButtonItem = UIBarButtonItem(title: "Feedback", style: UIBarButtonItem.Style.plain, target: self, action: #selector(help))
		helpBarButtonItem.accessibilityIdentifier = "helpBarButtonItem"

		let settingsBarButtonItem = UIBarButtonItem(title: "Settings".localized, style: UIBarButtonItem.Style.plain, target: self, action: #selector(settings))
		settingsBarButtonItem.accessibilityIdentifier = "settingsBarButtonItem"

		if VendorServices.shared.isBranded {
			self.toolbarItems = [
				UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil),
				settingsBarButtonItem
			]
		} else {
			self.toolbarItems = [
				helpBarButtonItem,
				UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil),
				settingsBarButtonItem
			]
		}

		if showBetaWarning, shownFirstTime {
			showBetaWarning = !considerAutoLogin()
		}

		if showBetaWarning {
			considerBetaWarning()
		}
	}

	@objc func considerAutoLogin() -> Bool {
		if shownFirstTime, UIApplication.shared.applicationState != .background {
			shownFirstTime = false

			if let bookmark = OCBookmarkManager.lastBookmarkSelectedForConnection {
				connect(to: bookmark)
				return true
			}
		}

		return false
	}

	func considerBetaWarning() {
		let lastBetaWarningCommit = OCAppIdentity.shared.userDefaults?.string(forKey: "LastBetaWarningCommit")

		Log.log("Show beta warning: \(String(describing: VendorServices.classSetting(forOCClassSettingsKey: .showBetaWarning) as? Bool))")

		if VendorServices.classSetting(forOCClassSettingsKey: .showBetaWarning) as? Bool == true,
			let lastGitCommit = LastGitCommit(),
			(lastBetaWarningCommit == nil) || (lastBetaWarningCommit != lastGitCommit) {
			// Beta warning has never been shown before - or has last been shown for a different release
			let betaAlert = ThemedAlertController(with: "Beta Warning", message: "\nThis is a BETA release that may - and likely will - still contain bugs.\n\nYOU SHOULD NOT USE THIS BETA VERSION WITH PRODUCTION SYSTEMS, PRODUCTION DATA OR DATA OF VALUE. YOU'RE USING THIS BETA AT YOUR OWN RISK.\n\nPlease let us know about any issues that come up via the \"Send Feedback\" option in the settings.", okLabel: "Agree") {
				OCAppIdentity.shared.userDefaults?.set(lastGitCommit, forKey: "LastBetaWarningCommit")
				OCAppIdentity.shared.userDefaults?.set(NSDate(), forKey: "LastBetaWarningAcceptDate")
			}

			self.showModal(viewController: betaAlert)
		}
	}

	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)

		self.navigationController?.setToolbarHidden(true, animated: animated)

		Theme.shared.unregister(client: self)
	}

	func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		if welcomeAddServerButton != nil {
			welcomeAddServerButton.themeColorCollection = collection.neutralColors

			welcomeTitleLabel.applyThemeCollection(collection, itemStyle: .title)
			welcomeMessageLabel.applyThemeCollection(collection, itemStyle: .message)
		}

		self.tableView.applyThemeCollection(collection)
	}

	func updateNoServerMessageVisibility() {
		guard welcomeOverlayView != nil else {
			return
		}

		if OCBookmarkManager.shared.bookmarks.count == 0 {
			let safeAreaLayoutGuide : UILayoutGuide = self.tableView.safeAreaLayoutGuide
			var constraint : NSLayoutConstraint

			if welcomeOverlayView.superview != self.view {

				welcomeOverlayView.alpha = 0

				self.view.addSubview(welcomeOverlayView)

				UIView.animate(withDuration: 0.2, animations: {
					self.welcomeOverlayView.alpha = 1
				})

				welcomeOverlayView.centerXAnchor.constraint(equalTo: safeAreaLayoutGuide.centerXAnchor).isActive = true
				welcomeOverlayView.centerYAnchor.constraint(equalTo: safeAreaLayoutGuide.centerYAnchor).isActive = true

				constraint = welcomeOverlayView.leftAnchor.constraint(greaterThanOrEqualTo: safeAreaLayoutGuide.leftAnchor, constant: 30)
				constraint.isActive = true
				constraint = welcomeOverlayView.rightAnchor.constraint(lessThanOrEqualTo: safeAreaLayoutGuide.rightAnchor, constant: -30)
				constraint.isActive = true

				self.tableView.tableHeaderView = nil
				self.navigationController?.navigationBar.shadowImage = nil

				welcomeAddServerButton.setTitle("Add account".localized, for: .normal)
				welcomeTitleLabel.text = "Welcome".localized
				let welcomeMessage = "Thanks for choosing %@! \n Start by adding your account.".localized
				welcomeMessageLabel.text = welcomeMessage.replacingOccurrences(of: "%@", with: OCAppIdentity.shared.appName ?? "ownCloud")

				tableView.separatorStyle = UITableViewCell.SeparatorStyle.none
				tableView.reloadData()
				tableView.isScrollEnabled = false
			}

			if self.navigationItem.leftBarButtonItem != nil {
				self.navigationItem.leftBarButtonItem = nil
			}

		} else {

			if welcomeOverlayView.superview == self.view {
				welcomeOverlayView.removeFromSuperview()

				tableView.separatorStyle = UITableViewCell.SeparatorStyle.singleLine
				tableView.reloadData()
				tableView.isScrollEnabled = true
			}

			if self.navigationItem.leftBarButtonItem == nil {
				self.navigationItem.leftBarButtonItem = self.editButtonItem
			}

			// Add Header View
			self.tableView.tableHeaderView = ServerListTableHeaderView(frame: CGRect(x: 0.0, y: 0.0, width: self.view.frame.size.width, height: 50.0))
			self.navigationController?.navigationBar.shadowImage = UIImage()
			self.tableView.tableHeaderView?.applyThemeCollection(Theme.shared.activeCollection)

			self.addThemableBackgroundView()
		}
	}

	// MARK: - Actions
	@IBAction func addBookmark() {
		showBookmarkUI()
	}

	func showBookmarkUI(edit bookmark: OCBookmark? = nil, performContinue: Bool = false, attemptLoginOnSuccess: Bool = false, removeAuthDataFromCopy: Bool = true) {
		let bookmarkViewController : BookmarkViewController = BookmarkViewController(bookmark, removeAuthDataFromCopy: removeAuthDataFromCopy)
		let navigationController : ThemeNavigationController = ThemeNavigationController(rootViewController: bookmarkViewController)

		navigationController.modalPresentationStyle = .overFullScreen

		// Prevent any in-progress connection from being shown
		resetPreviousBookmarkSelection()

		// Exit editing mode (unfortunately, self.isEditing = false will not do the trick as it leaves the left bar button unchanged as "Done")
		if self.tableView.isEditing,
			let target = self.navigationItem.leftBarButtonItem?.target,
			let action = self.navigationItem.leftBarButtonItem?.action {
			_ = target.perform(action, with: self)
		}

		if attemptLoginOnSuccess {
			bookmarkViewController.userActionCompletionHandler = { [weak self] (bookmark, success) in
				if success, let bookmark = bookmark, let self = self {
					self.connect(to: bookmark)
				}
			}
		}

		self.showModal(viewController: navigationController, completion: {
			OnMainThread {
				if performContinue {
					bookmarkViewController.showedOAuthInfoHeader = true // needed for HTTP+OAuth2 connections to really continue on .handleContinue() call
					bookmarkViewController.handleContinue()
				}
			}
		})
	}

	func showBookmarkInfoUI(_ bookmark: OCBookmark) {
		let viewController = BookmarkInfoViewController(bookmark)
		let navigationController : ThemeNavigationController = ThemeNavigationController(rootViewController: viewController)
		navigationController.modalPresentationStyle = .overFullScreen

		// Prevent any in-progress connection from being shown
		resetPreviousBookmarkSelection()

		self.showModal(viewController: navigationController)
	}

	var themeCounter : Int = 0

	@IBAction func help() {
		// Prevent any in-progress connection from being shown
		resetPreviousBookmarkSelection()

		VendorServices.shared.sendFeedback(from: self)
	}

	@IBAction func settings() {
		let viewController : SettingsViewController = SettingsViewController(style: .grouped)

		// Prevent any in-progress connection from being shown
		resetPreviousBookmarkSelection()

		self.navigationController?.pushViewController(viewController, animated: true)
	}

	// MARK: - Track external changes
	var ignoreServerListChanges : Bool = false

	@objc func serverListChanged() {
		OnMainThread {
			if !self.ignoreServerListChanges {
				self.tableView.reloadData()
				self.updateNoServerMessageVisibility()
			}
		}
	}

	// MARK: - Connect and locking
	func isLocked(bookmark: OCBookmark, presentAlert: Bool = true) -> Bool {
		return OCBookmarkManager.isLocked(bookmark: bookmark, presentAlertOn: presentAlert ? self : nil)
	}

	var pushTransitionRecovery : PushTransitionRecovery?
	weak var pushFromViewController : UIViewController?

	func connect(to bookmark: OCBookmark) {
		if isLocked(bookmark: bookmark) {
			return
		}

		guard let indexPath = indexPath(for: bookmark) else {
			return
		}

		let clientRootViewController = ClientRootViewController(bookmark: bookmark)

		let bookmarkRow = self.tableView.cellForRow(at: indexPath)
		let activityIndicator = UIActivityIndicatorView(style: .white)

		var bookmarkRowAccessoryView : UIView?

		if bookmarkRow != nil {
			bookmarkRowAccessoryView = bookmarkRow?.accessoryView
			bookmarkRow?.accessoryView = activityIndicator

			activityIndicator.startAnimating()
		}

		self.setLastSelectedBookmark(bookmark, openedBlock: {
			activityIndicator.stopAnimating()
			bookmarkRow?.accessoryView = bookmarkRowAccessoryView
		})

		clientRootViewController.authDelegate = self
		clientRootViewController.modalPresentationStyle = .overFullScreen

		clientRootViewController.afterCoreStart {
			// Make sure only the UI for the last selected bookmark is actually presented (in case of other bookmarks facing a huge delay and users selecting another bookmark in the meantime)
			if self.lastSelectedBookmark?.uuid == bookmark.uuid {
				OCBookmarkManager.lastBookmarkSelectedForConnection = bookmark

				// Set up custom push transition for presentation
				if let fromViewController = self.pushFromViewController ?? self.navigationController {
					let transitionDelegate = PushTransitionDelegate(with: self.pushTransitionRecovery)

					clientRootViewController.pushTransition = transitionDelegate // Keep a reference, so it's still around on dismissal
					clientRootViewController.transitioningDelegate = transitionDelegate
					clientRootViewController.modalPresentationStyle = .custom

					fromViewController.present(clientRootViewController, animated: true, completion: {
						self.resetPreviousBookmarkSelection(bookmark)
					})
				}
			}

			self.didUpdateServerList()
		}
	}

	func didUpdateServerList() {
		// This is a hook for subclasses
	}

	// MARK: - Table view delegate
	var lastSelectedBookmark : OCBookmark?
	var lastSelectedBookmarkOpenedBlock : (() -> Void)?

	func setLastSelectedBookmark(_ bookmark: OCBookmark, openedBlock: (() -> Void)?) {
		resetPreviousBookmarkSelection()
		lastSelectedBookmark = bookmark
		lastSelectedBookmarkOpenedBlock = openedBlock
	}

	func resetPreviousBookmarkSelection(_ bookmark: OCBookmark? = nil) {
		if (bookmark == nil) || ((bookmark != nil) && (bookmark?.uuid == lastSelectedBookmark?.uuid)) {
			if lastSelectedBookmark != nil, lastSelectedBookmarkOpenedBlock != nil {
				lastSelectedBookmarkOpenedBlock?()
				lastSelectedBookmarkOpenedBlock = nil

				lastSelectedBookmark = nil
			}
		}
	}

	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		if let bookmark = OCBookmarkManager.shared.bookmark(at: UInt(indexPath.row)) {
			if self.isLocked(bookmark: bookmark) {
				return
			}

			if tableView.isEditing {
				self.showBookmarkUI(edit: bookmark)
			} else {
				self.connect(to: bookmark)
			}

			self.tableView.deselectRow(at: indexPath, animated: true)
		}
	}

	func openBookmark(_ bookmark: OCBookmark, closeHandler: (() -> Void)? = nil) {
		let clientRootViewController = ClientRootViewController(bookmark: bookmark)

		//clientRootViewController.closeHandler = closeHandler

		self.showModal(viewController: clientRootViewController)
	}

	func deleteBookmark(_ bookmark: OCBookmark, completionHandler: ((_ error: Error?) -> Void)? = nil) {
		var presentationStyle: UIAlertController.Style = .actionSheet
		if UIDevice.current.isIpad() {
			presentationStyle = .alert
		}
		let deleteCompletionHandler = completionHandler

		let alertController = ThemedAlertController(title: NSString(format: "Do you really want to disconnect from your '%@' account?".localized as NSString, bookmark.shortName) as String,
													message: "This will remove all locally stored file copies from your device.".localized,
													preferredStyle: presentationStyle)

		alertController.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel, handler: nil))

		alertController.addAction(UIAlertAction(title: "Remove".localized, style: .destructive, handler: { (_) in
			OCBookmarkManager.lock(bookmark: bookmark)

			OCCoreManager.shared.scheduleOfflineOperation({ (bookmark, completionHandler) in
				let vault : OCVault = OCVault(bookmark: bookmark)

				vault.erase(completionHandler: { (_, error) in
					OnMainThread {
						if error != nil {
							// Inform user if vault couldn't be erased
							let alertController = ThemedAlertController(title: NSString(format: "Removing of '%@' failed".localized as NSString, bookmark.shortName as NSString) as String,
																		message: error?.localizedDescription,
																		preferredStyle: .alert)

							alertController.addAction(UIAlertAction(title: "OK".localized, style: .default, handler: nil))
							self.showModal(viewController: alertController)
						} else {
							// Success! We can now remove the bookmark
							self.ignoreServerListChanges = true

							OCBookmarkManager.shared.removeBookmark(bookmark)

							self.updateNoServerMessageVisibility()
						}

						OCBookmarkManager.unlock(bookmark: bookmark)

						deleteCompletionHandler?(error)
					}
				})
			}, for: bookmark)
		}))

		self.showModal(viewController: alertController)
	}

	func showModal(viewController: UIViewController, completion: (() -> Void)? = nil) {
		self.present(viewController, animated: true, completion: completion)
	}

	// MARK: - Table view data source
	func indexPath(for bookmark: OCBookmark) -> IndexPath? {
		var index = 0

		for otherBookmark in OCBookmarkManager.shared.bookmarks {
			if bookmark.uuid == otherBookmark.uuid {
				return IndexPath(item: index, section: 0)
			}

			index += 1
		}

		return nil
	}

	override func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}

	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return OCBookmarkManager.shared.bookmarks.count
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		guard let bookmarkCell = self.tableView.dequeueReusableCell(withIdentifier: "bookmark-cell", for: indexPath) as? ServerListBookmarkCell else {
			return ServerListBookmarkCell()
		}

		if let bookmark : OCBookmark = OCBookmarkManager.shared.bookmark(at: UInt(indexPath.row)) {
			bookmarkCell.titleLabel.text = bookmark.shortName
			bookmarkCell.detailLabel.text = (bookmark.originURL != nil) ? bookmark.originURL!.absoluteString : bookmark.url?.absoluteString
			bookmarkCell.accessibilityIdentifier = "server-bookmark-cell"
		}

		return bookmarkCell
	}

	override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {

		let deleteRowAction = UITableViewRowAction(style: .destructive, title: "Delete".localized, handler: { (_, indexPath) in
			if let bookmark = OCBookmarkManager.shared.bookmark(at: UInt(indexPath.row)) {

				self.deleteBookmark(bookmark) { (error) in
					if error == nil {
						tableView.performBatchUpdates({
							tableView.deleteRows(at: [indexPath], with: UITableView.RowAnimation.fade)
						}, completion: { (_) in
							self.ignoreServerListChanges = false
						})
					}
				}
			}
		})

		let editRowAction = UITableViewRowAction(style: .normal, title: "Edit".localized, handler: { [weak self] (_, indexPath) in
			if let bookmark = OCBookmarkManager.shared.bookmark(at: UInt(indexPath.row)) {
				self?.showBookmarkUI(edit: bookmark)
			}
		})
		editRowAction.backgroundColor = .blue

		let manageRowAction = UITableViewRowAction(style: .normal,
							   title: "Manage".localized,
							   handler: { [weak self] (_, indexPath) in
			if let bookmark = OCBookmarkManager.shared.bookmark(at: UInt(indexPath.row)) {
				self?.showBookmarkInfoUI(bookmark)
			}
		})

		return [deleteRowAction, editRowAction, manageRowAction]
	}

	override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
		OCBookmarkManager.shared.moveBookmark(from: UInt(fromIndexPath.row), to: UInt(to.row))
	}
}

extension OCBookmarkManager {
	static private let lastConnectedBookmarkUUIDDefaultsKey = "last-connected-bookmark-uuid"

	// MARK: - Defaults Keys
	static var lastBookmarkSelectedForConnection : OCBookmark? {
		get {
			if let bookmarkUUIDString = OCAppIdentity.shared.userDefaults?.string(forKey: OCBookmarkManager.lastConnectedBookmarkUUIDDefaultsKey), let bookmarkUUID = UUID(uuidString: bookmarkUUIDString) {
				return OCBookmarkManager.shared.bookmark(for: bookmarkUUID)
			}

			return nil
		}

		set {
			OCAppIdentity.shared.userDefaults?.set(newValue?.uuid.uuidString, forKey: OCBookmarkManager.lastConnectedBookmarkUUIDDefaultsKey)
		}
	}

	static var lockedBookmarks : [OCBookmark] = []

	static func lock(bookmark: OCBookmark) {
		OCSynchronized(self) {
			self.lockedBookmarks.append(bookmark)
		}
	}

	static func unlock(bookmark: OCBookmark) {
		OCSynchronized(self) {
			if let removeIndex = self.lockedBookmarks.index(of: bookmark) {
				self.lockedBookmarks.remove(at: removeIndex)
			}
		}
	}

	static func isLocked(bookmark: OCBookmark, presentAlertOn viewController: UIViewController? = nil, completion: ((_ isLocked: Bool) -> Void)? = nil) -> Bool {
		if self.lockedBookmarks.contains(bookmark) {
			if viewController != nil {
				let alertController = ThemedAlertController(title: NSString(format: "'%@' is currently locked".localized as NSString, bookmark.shortName as NSString) as String,
									message: NSString(format: "An operation is currently performed that prevents connecting to '%@'. Please try again later.".localized as NSString, bookmark.shortName as NSString) as String,
									preferredStyle: .alert)

				alertController.addAction(UIAlertAction(title: "OK".localized, style: .default, handler: { (_) in
					completion?(true)
				}))

				viewController?.present(alertController, animated: true, completion: nil)
			}

			return true
		}

		completion?(false)

		return false
	}
}

extension ServerListTableViewController : ClientRootViewControllerAuthenticationDelegate {
	func handleAuthError(for clientViewController: ClientRootViewController, error: NSError, editBookmark: OCBookmark?) {
		clientViewController.closeClient(completion: { [weak self] in
			if let editBookmark = editBookmark {
				// Bring up bookmark editing UI
				self?.showBookmarkUI(edit: editBookmark,
						     performContinue: (editBookmark.isTokenBased == true),
						     attemptLoginOnSuccess: true,
						     removeAuthDataFromCopy: true)
			}
		})
	}
}
