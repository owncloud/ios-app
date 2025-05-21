//
//  ClientLocationPicker.swift
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

// MARK: - OCLocation additions
extension OCLocation {
	// LocationLevel property
	public var clientLocationLevel: ClientLocationPicker.LocationLevel {
		if path != nil, !isRoot {
			return .folder
		} else if driveID != nil {
			return .drive
		} else if bookmarkUUID != nil {
			return .account
		}

		return .accounts
	}

	// OCLocation creation with app terminology
	public static var accounts: OCLocation {
		return OCLocation()
	}

	public static func account(_ bookmark: OCBookmark) -> OCLocation {
		return OCLocation(bookmarkUUID: bookmark.uuid, driveID: nil, path: nil)
	}

	public static func drive(_ driveID: String, bookmark: OCBookmark) -> OCLocation {
		return OCLocation(bookmarkUUID: bookmark.uuid, driveID: driveID, path: "/")
	}

	public static func folder(_ item: OCItem, bookmark: OCBookmark) -> OCLocation {
		let folderLocation = item.location!

		if folderLocation.bookmarkUUID == nil {
			folderLocation.bookmarkUUID = bookmark.uuid
		}

		return folderLocation
	}
}

// MARK: - Location Picker
public class ClientLocationPicker : NSObject {
	// MARK: - Types
	public enum LocationLevel: CaseIterable {
		case accounts	// Choice between accounts is possible
		case account	// Choice within a single account is possible
		case drive	// Choice within a single drive is possible
		case folder	// Choice within a folder (+ subfolders) is possible
	}

	public typealias LocationFilter = (_ location: OCLocation, _ context: ClientContext?) -> Bool
	public typealias ChoiceHandler = (_ chosenItem: OCItem?, _ location: OCLocation?, _ context: ClientContext?, _ cancelled: Bool) -> Void

	// MARK: - Options
	public var showFavorites: Bool
	public var showRecentLocations: Bool

	public var startLocation: OCLocation
	public var maximumLevel: LocationLevel

	public var conflictItems: [OCItem]?
	public var choiceHandler: ChoiceHandler?

	public var allowedLocationFilter: LocationFilter? // Determines which locations can be picked by the user
	public var navigationLocationFilter: LocationFilter? // Determines which locations can be selected by the user during navigation

	public var allowFileSelection: Bool = false

	public var headerView: UIView?
	var headerViewTitleElement: ComposedMessageElement?
	var headerViewSubtitleElement: ComposedMessageElement?

	public var headerTitle: String? {
		didSet {
			headerViewTitleElement?.text = headerTitle
		}
	}
	public var headerSubTitle: String? {
		didSet {
			headerViewSubtitleElement?.text = headerSubTitle
		}
	}

	public var selectButtonTitle: String
	public var selectPrompt: String?
	public var accountControllerConfiguration: AccountController.Configuration?

	// MARK: - Init
	public init(location: OCLocation, maximumLevel: LocationLevel = .folder, showFavorites: Bool = true, showRecents: Bool = true, selectButtonTitle: String?, selectPrompt: String? = nil, headerTitle: String? = nil, headerSubTitle: String? = nil, headerView: UIView? = nil, requiredPermissions: OCItemPermissions? = [.createFile], avoidConflictsWith conflictItems: [OCItem]?, choiceHandler: @escaping ChoiceHandler) {
		self.startLocation = location
		self.showFavorites = showFavorites
		self.showRecentLocations = showRecents
		self.selectButtonTitle = selectButtonTitle ?? OCLocalizedString("Select folder", nil)
		self.selectPrompt = selectPrompt
		self.headerTitle = headerTitle
		self.headerSubTitle = headerSubTitle
		self.conflictItems = conflictItems
		self.maximumLevel = maximumLevel
		self.headerView = headerView

		self.accountControllerConfiguration = .pickerConfiguration

		super.init()

		if location.clientLocationLevel == .account {
			// No point showing the account pill if its the only account being shown
			// self.accountControllerConfiguration?.showAccountPill = false
		}

		self.choiceHandler = choiceHandler

		// Create header view if title is specified, but headerView isn't
		if let headerTitle, headerView == nil {
			headerViewTitleElement = .text(headerTitle, style: .system(textStyle: .title2, weight: .bold), alignment: .leading, cssSelectors: [.title])

			var elements: [ComposedMessageElement] = [ headerViewTitleElement! ]

			if let headerSubTitle {
				headerViewSubtitleElement = .text(headerSubTitle, style: .systemSecondary(textStyle: .body), alignment: .leading, cssSelectors: [.subtitle])
				elements.append(headerViewSubtitleElement!)
			}

			self.headerView = ComposedMessageView(elements: elements)
		}

		// Create allowedLocationFilter and navigationLocationFilter from conflictItems
		var effectiveConflictItems = conflictItems

		if conflictItems == nil, requiredPermissions != nil {
			// Ensure .allowedLocationFilter is also created with empty conflictItems -
			// if there are permission requirements to check for
			effectiveConflictItems = []
		}

		if let effectiveConflictItems {
			var navigationPathFilter : LocationFilter?

			let folderItemLocations = effectiveConflictItems.filter({ (item) -> Bool in
				return item.type == .collection && item.path != nil && !item.isRoot
			}).map { (item) -> OCLocation in
				return item.location!
			}
			let itemParentLocations = effectiveConflictItems.filter({ (item) -> Bool in
				return item.location?.parent != nil
			}).map { (item) -> OCLocation in
				return item.location!.parent!
			}

			if folderItemLocations.count > 0 {
				navigationPathFilter = { (targetLocation, _) in
					return !folderItemLocations.contains(targetLocation)
				}
			}

			allowedLocationFilter = { (targetLocation, context) in
				// Disallow all paths as target that are parent of any of the items
				if itemParentLocations.contains(targetLocation) {
					return false
				}

				// Check that destination meets permission requirements
				if let requiredPermissions {
					if let item = try? context?.core?.cachedItem(at: targetLocation) {
						return item.permissions.contains(requiredPermissions)
					}
				}

				return true
			}

			navigationLocationFilter = navigationPathFilter
		}
	}

	// MARK: - Permission checks
	func checkPermission(context: ClientContext?, dataItemRecord: OCDataItemRecord?, interaction: ClientItemInteraction, viewController: UIViewController?) -> Bool {
		switch interaction {
			case .selection:
				if let item = dataItemRecord?.item as? OCItem {
					if item.type == .file {
						if allowFileSelection,
						   let locationPickerViewController = viewController?.parent?.parent as? ClientLocationPickerViewController {
						   	// Permission check for selection is only called upon selection, so we
						   	// can use this as a hook to pick the file if file selection is allowed
							locationPickerViewController.choose(item: item, location: item.location, cancelled: false)
						}
						return false
					}

					if let itemLocation = item.location, let navigationLocationFilter {
						return navigationLocationFilter(itemLocation, context)
					}
				}
				return true

			case .multiselection, .contextMenu, .leadingSwipe, .trailingSwipe, .drag, .acceptDrop, .search, .moreOptions, .addContent:
				return false
		}
	}

	// MARK: - Provide data source and initial view controller
	func provideDataSource(for location: OCLocation, maximumLevel: LocationLevel, context: ClientContext) -> OCDataSource? {
		var sectionDataSource: OCDataSource?

		let level = location.clientLocationLevel

		switch level {
			case .accounts, .account:
				sectionDataSource = OCDataSourceMapped(source: OCBookmarkManager.shared.bookmarksDatasource, creator: { [weak self] (_, bookmarkDataItem) in
					if let bookmark = bookmarkDataItem as? OCBookmark,
					   let self = self,
					   let rootContext = self.rootContext,
					   let accountControllerConfiguration = self.accountControllerConfiguration {
						if level == .account, bookmark.uuid != self.startLocation.bookmarkUUID {
							// If level is account, only return the start location's account (if provided)
							return nil
						}

						let controller = AccountController(bookmark: bookmark, context: rootContext, configuration: accountControllerConfiguration)

						return AccountControllerSection(with: controller)
					}

					return nil
				}, updater: nil, destroyer: { _, bookmarkItemRef, accountController in
					// Safely disconnect account controller if currently connected
					if let accountController = accountController as? AccountController {
						accountController.destroy() // needs to be called since AccountController keeps a reference to itself otherwise
					}
				}, queue: .main)

			case .drive, .folder: break
		}

		return sectionDataSource
	}

	func provideViewController(for location: OCLocation, extraSections: [CollectionViewSection]? = nil, maximumLevel: LocationLevel, context: ClientContext) -> CollectionViewController? {
		let sectionsDataSource = provideDataSource(for: location, maximumLevel: maximumLevel, context: context)
		var viewController: CollectionViewController?

		if let sectionsDataSource {
			var effectiveSectionsDataSource: OCDataSource? = sectionsDataSource

			if let extraSections {
				effectiveSectionsDataSource = OCDataSourceComposition(sources: [
					OCDataSourceArray(items: extraSections),
					sectionsDataSource
				])
			}

			viewController = CollectionViewController(context: context, sections: nil, useStackViewRoot: true, hierarchic: true)
			viewController?.sectionsDataSource = effectiveSectionsDataSource
		} else {
			viewController = location.openItem(from: nil, with: context, animated: true, pushViewController: false, completion: nil) as? CollectionViewController

			if let extraSections, let viewController {
				viewController.insert(sections: extraSections, at: 0)
			}
		}

		if let viewController {
			var title: String?

			switch location.clientLocationLevel {
				case .accounts:
					title = OCLocalizedString("Accounts", nil)
					viewController.cssSelector = .accountList

				case .account:
					title = OCLocalizedString("Account", nil)
					viewController.cssSelector = .accountList
					if let bookmarkUUID = location.bookmarkUUID {
						title = OCBookmarkManager.shared.bookmark(for: bookmarkUUID)?.displayName
					}
					viewController.hideNavigationBar = true

				case .drive:
					if let driveID = location.driveID {
						title = context.core?.drive(withIdentifier: driveID, attachedOnly: false)?.name
					}

				case .folder: break
			}

			if let title {
				viewController.navigationItem.titleLabelText = title
			}
		}

		headerView?.secureView(core: context.core)

		return viewController
	}

	// MARK: - Recent locations
	lazy var recentLocationsDatasource: OCDataSource? = {
		var datasources: [OCDataSource] = []

		switch startLocation.clientLocationLevel {
			case .accounts:
				for bookmark in OCBookmarkManager.shared.bookmarks {
					if let accountDatasource = recentLocationStore(for: bookmark.uuid)?.dataSource {
						datasources.append(accountDatasource)
					}
				}

			case .account, .drive, .folder:
				if let accountDatasource = recentLocationStore(for: startLocation.bookmarkUUID)?.dataSource {
					datasources.append(accountDatasource)
				}
		}

		let datasource = OCDataSourceComposition(sources: datasources, applyCustomizations: { [weak self] compositionSource in
			// Sort by date (more recent first)
			compositionSource.sortComparator = { (src1, ref1, src2, ref2) -> ComparisonResult in
				if let record1 = try? src1.record(forItemRef: ref1),
				   let record2 = try? src2.record(forItemRef: ref2),
				   let location1 = record1.item as? RecentLocation,
				   let location2 = record2.item as? RecentLocation,
				   let timestamp1 = location1.timestamp,
				   let timestamp2 = location2.timestamp {
				   	if timestamp1.timeIntervalSinceReferenceDate > timestamp2.timeIntervalSinceReferenceDate {
						return .orderedAscending
					} else if timestamp1.timeIntervalSinceReferenceDate < timestamp2.timeIntervalSinceReferenceDate {
						return .orderedDescending
					}
				}
				return .orderedSame
			}

			// Do not include locations that aren't allowed
			if self?.allowedLocationFilter != nil {
				compositionSource.filter = { [weak self] source, itemRef in
					guard let self, let allowedLocationFilter = self.allowedLocationFilter,
					      let itemRec = try? source.record(forItemRef: itemRef),
					      let recentLocation = itemRec.item as? RecentLocation,
					      let location = recentLocation.location else { return false }

					return allowedLocationFilter(location, (location.bookmarkUUID == self.rootContext?.core?.bookmark.uuid) ? self.rootContext : nil)
				}
			}
		})

		return datasource
	}()

	var recentLocationsStores: [UUID : RecentLocationStore] = [:] // store stores strongly and at the picker level, so they get retained for the lifetime of the picker and deallocated once the picker is dismissed
	func recentLocationStore(for bookmarkUUID: UUID?) -> RecentLocationStore? {
		guard let bookmarkUUID else { return nil }

		if let recentLocationStore = recentLocationsStores[bookmarkUUID] {
			return recentLocationStore
		}

		if let bookmark = OCBookmarkManager.shared.bookmark(for: bookmarkUUID) {
			let recentLocationStore = RecentLocationStore(for: bookmark)
			recentLocationsStores[bookmark.uuid] = recentLocationStore
			return recentLocationStore
		}

		return nil
	}

	func addRecent(location: OCLocation, from core: OCCore) {
		if let bookmarkUUID = location.bookmarkUUID {
			recentLocationStore(for: bookmarkUUID)?.add(location: location)
		}
	}

	// MARK: - Presentation & Choice
	var rootNavigationController: UINavigationController?
	var rootViewController: CollectionViewController?
	var rootContext: ClientContext?

	public func pickerViewControllerForPresentation(with baseContext: ClientContext? = nil) -> UIViewController? {
		let navigationController = ThemeNavigationController()
		var extraSections: [CollectionViewSection]?

		// Set up navigation controller and context
		rootNavigationController = navigationController
		rootContext = ClientContext(with: baseContext, modifier: { context in
			context.add(permissionHandler: { [weak self] context, dataItemRecord, checkInteraction, viewController in
				return self?.checkPermission(context: context, dataItemRecord: dataItemRecord, interaction: checkInteraction, viewController: viewController) ?? false
			})
			context.viewControllerPusher = self
			context.browserController = nil
			context.navigationController = navigationController
			context.permissions = [ .selection ]
			context.itemStyler = { [weak self] (context, _, item) in
				if let item = item as? OCItem {
					if self?.allowFileSelection == false, item.type == .file {
						return .disabled
					}

					if let itemLocation = item.location,
					   let navigationLocationFilter = self?.navigationLocationFilter,
					   !navigationLocationFilter(itemLocation, context) {
						return .disabled
					}
				}
				return .regular
			}
		})

		// Set up recent locations
		if showRecentLocations, let recentLocationsDatasource {
			// Add recents section on top
			let itemSize = NSCollectionLayoutSize(widthDimension: .estimated(64), heightDimension: .estimated(64))
			let item = NSCollectionLayoutItem(layoutSize: itemSize)
			let recentsSection = CollectionViewSection(identifier: "recents", dataSource: recentLocationsDatasource, cellStyle: .init(with: .gridCell), cellLayout: .sideways(item: item, groupSize: itemSize, edgeSpacing: NSCollectionLayoutEdgeSpacing(leading: .fixed(10), top: .fixed(0), trailing: .fixed(10), bottom: .fixed(0)), contentInsets: NSDirectionalEdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0), orthogonalScrollingBehaviour: .continuous), clientContext: baseContext)
			recentsSection.hideIfEmptyDataSource = recentLocationsDatasource

			recentsSection.boundarySupplementaryItems = [
				.mediumTitle(OCLocalizedString("Recent locations",nil), pinned: true)
			]

			extraSections = [
				recentsSection
			]
		}

		// Compose view controller
		if let rootContext = rootContext {
			rootViewController = provideViewController(for: startLocation, extraSections: extraSections, maximumLevel: maximumLevel, context: rootContext)
			if let rootViewController {
				navigationController.pushViewController(rootViewController, animated: false)

				let pickerViewController = ClientLocationPickerViewController(with: self)
				pickerViewController.contentViewController = navigationController
				pickerViewController.isModalInPresentation = true

				return pickerViewController

			}
		}

		return nil
	}

	public func present(in clientContext: ClientContext, baseContext: ClientContext? = nil) {
		// Compose and present view controller
		if let pickerViewController = pickerViewControllerForPresentation(with: baseContext) {
			clientContext.present(pickerViewController, animated: true)
		}
	}

	func choose(item: OCItem?, location: OCLocation?, context: ClientContext?, cancelled: Bool) {
		if let choiceHandler {
			self.choiceHandler = nil

			if !cancelled {
				// Add missing counterparts
				if let location, item == nil {
					// Add missing item for location
					if let core = context?.core {
						core.cachedItem(at: location, resultHandler: { error, item in
							if item?.bookmarkUUID == nil, let bookmarkUUID = location.bookmarkUUID?.uuidString {
								item?.bookmarkUUID = bookmarkUUID
							}
							OnMainThread {
								self.addRecent(location: location, from: core)
								choiceHandler(item, location, context, cancelled)
							}
						})
						return
					}
				} else if let item, location == nil {
					// Add missing location for item
					if item.bookmarkUUID == nil, let bookmarkUUID = context?.core?.bookmark.uuid.uuidString {
						item.bookmarkUUID = bookmarkUUID
					}
					if let itemLocation = item.location, let core = context?.core {
						addRecent(location: itemLocation, from: core)
					}
					choiceHandler(item, item.location, context, cancelled)
					return
				}
			}

			choiceHandler(item, location, context, cancelled)
		}
	}
}

// MARK: - ViewControllerPusher
// Implemented solely to disable .compressForKeyboard for the collection views in the picker, as the usage of the keyboardLayoutGuide
// inexplicably leads to a bogus BottomBar layout when pushing the first "Files" view controller
extension ClientLocationPicker : ViewControllerPusher {
	public func pushViewController(context: ClientContext?, provider: (ClientContext) -> UIViewController?, push: Bool, animated: Bool) -> UIViewController? {
		if let context {
			let viewController = provider(context)

			if let collectionViewController = viewController as? CollectionViewController {
				// Disable .compressForKeyboard for CollectionViewController
				collectionViewController.compressForKeyboard = false
			}

			if push, let viewController {
				context.navigationController?.pushViewController(viewController, animated: animated)
			}

			return viewController
		}

		return nil
	}
}

extension ThemeCSSSelector {
	static let accountList = ThemeCSSSelector(rawValue: "accountList")
}
