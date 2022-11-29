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

public class ClientLocationPicker : NSObject {
	public enum ClientLocationLevel: CaseIterable {
		case accounts
		case drive
		case folder
	}

	public typealias LocationFilter = (_ location: OCLocation) -> Bool
	public typealias ChoiceHandler = (_ chosenItem: OCItem?, _ location: OCLocation?, _ needsToDismissViewController: Bool) -> Void

	public var startLevel: ClientLocationLevel = .accounts
	public var maximumLevel: ClientLocationLevel = .folder

	public var clientContext: ClientContext

	public var showFavorites: Bool
	public var recentLocations: [OCLocation]?

	public var selectButtonTitle: String

	public var conflictItems: [OCItem]?
	public var choiceHandler: ChoiceHandler

	public var startLocation: OCLocation?

	var allowedLocationFilter: LocationFilter?
	var navigationLocationFilter: LocationFilter?

	var accountControllerConfiguration: AccountController.Configuration?

	public init(with context: ClientContext, location: OCLocation?, showFavorites: Bool = true, showRecents: Bool = true, selectButtonTitle: String?, avoidConflictsWith items: [OCItem]?, choiceHandler: @escaping ChoiceHandler) {
		self.clientContext = context
		self.startLocation = location
		self.showFavorites = showFavorites
		self.selectButtonTitle = selectButtonTitle ?? "Select folder".localized
		self.choiceHandler = choiceHandler

		self.accountControllerConfiguration = AccountController.Configuration.defaultConfiguration

		super.init()
	}

	public func present() {
	}

	func provideDataSource(for level: ClientLocationLevel) {
		var sectionDataSource: OCDataSource?
		var itemsDataSource: OCDataSource?

		switch level {
			case .accounts, .drive:
				sectionDataSource = OCDataSourceMapped(source: OCBookmarkManager.shared.bookmarksDatasource, creator: { [weak self] (_, bookmarkDataItem) in
					if let bookmark = bookmarkDataItem as? OCBookmark,
					   let self = self,
					   let accountControllerConfiguration = self.accountControllerConfiguration {
						if level == .drive, bookmark.uuid != self.startLocation?.bookmarkUUID {
							// If level is drive, only return the start location's account (if provided)
							return nil
						}

						let controller = AccountController(bookmark: bookmark, context: self.clientContext, configuration: accountControllerConfiguration)

						return AccountControllerSection(with: controller)
					}

					return nil
				}, updater: nil, destroyer: { _, bookmarkItemRef, accountController in
					// Safely disconnect account controller if currently connected
					if let accountController = accountController as? AccountController {
						accountController.destroy() // needs to be called since AccountController keeps a reference to itself otherwise
					}
				}, queue: .main)

			case .folder: break
		}
	}
}
