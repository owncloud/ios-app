//
//  ServerSideSearchScope.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 04.11.24.
//  Copyright © 2024 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2024, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import UIKit
import ownCloudSDK
import ownCloudApp

class ServerSideSearchScope: ItemSearchScope {
	open override class var descriptor: SearchScopeDescriptor {
		return SearchScopeDescriptor(identifier: "server", localizedName: OCLocalizedString("Server", nil), localizedDescription: OCLocalizedString("Searches using the server.", nil), icon: OCSymbol.icon(forSymbolName: "server.rack"), searchableContent: [.itemName, .contents], scopeCreator: { (clientContext, cellStyle, descriptor) in
			if let cellStyle {
				return ServerSideSearchScope(with: clientContext, cellStyle: cellStyle, localizedName: descriptor.localizedName, localizedPlaceholder: OCLocalizedString("Search server", nil), icon: descriptor.icon)
			}
			return nil
		})
	}

	var searchResult: OCSearchResult?

	var connectionStatusObservation: NSKeyValueObservation?

	override init(with context: ClientContext, cellStyle: CollectionViewCellStyle?, localizedName name: String, localizedPlaceholder placeholder: String? = nil, icon: UIImage? = nil) {
		var pathAndRevealCellStyle : CollectionViewCellStyle?

		if let cellStyle = cellStyle {
			pathAndRevealCellStyle = CollectionViewCellStyle(from: cellStyle, changing: { cellStyle in
				cellStyle.showRevealButton = true
				cellStyle.showPathDetails = true
			})
		}

		super.init(with: context, cellStyle: pathAndRevealCellStyle, localizedName: name, localizedPlaceholder: placeholder, icon: icon)

		connectionStatusObservation = context.core?.observe(\.connectionStatus, options: .initial, changeHandler: { [weak self] core, _ in
			let isOnline = core.connectionStatus == .online
			OnMainThread {
				self?.isOnline = isOnline
			}
		})
	}

	deinit {
		connectionStatusObservation?.invalidate()
	}

	override var queryCondition: OCQueryCondition? {
		didSet {
			updateSearch()
		}
	}

	override func createScopeViewController() -> (any UIViewController & SearchElementUpdating)? {
		return ItemSearchSuggestionsViewController(with: self, excludeCategories: [.size])
	}

	override var searchableContent: OCKQLSearchedContent {
		return [.contents, .itemName]
	}

	override var searchedContent: OCKQLSearchedContent {
		didSet {
			updateSearch()
		}
	}

	var kqlQuery: String? {
		didSet {
			if let kqlQuery {
				if kqlQuery != searchResult?.kqlQuery, let core = clientContext.core {
					searchResult?.cancel()

					searchResult = core.searchFiles(withPattern: kqlQuery, limit: 100)
					if searchResult?.error != nil {
						updateWith(results: nil, error: searchResult?.error)
					} else {
						updateWith(results: searchResult?.results, error: nil)
					}
				}
			} else {
				searchResult?.cancel()
				searchResult = nil

				updateWith(results: nil, error: nil)
			}
		}
	}

	func updateSearch() {
		// OCQueryCondition.typeAliasToKeywordMap is currently matching KQL types defined in
		// https://github.com/owncloud/ocis/blob/cff364c998355b1295793e9244e5efdfea064536/services/search/pkg/query/bleve/compiler.go#L287
		// If they diverge, an additional conversion from locally used keyword to server used keyword needs to take place here.
		kqlQuery = queryCondition?.kqlStringWithTypeAlias(toKQLTypeMap: OCQueryCondition.typeAliasToKeywordMap, targetContent: searchedContent)
	}

	var isOnline: Bool = true {
		didSet {
			if oldValue != isOnline {
				if isOnline {
					updateSearch()
				}
				updateDisplay()
			}
		}
	}

	var searchResults: OCDataSource?
	func updateWith(results source: OCDataSource?, error: Error?) {
		searchResults = source
		updateDisplay()
	}

	func updateDisplay() {
		if isOnline {
			results = searchResults
		} else {
			let noResultsView = ComposedMessageView.infoBox(image: OCSymbol.icon(forSymbolName: "wifi.slash"), title: OCLocalizedString("Server search requires a connection", nil), subtitle: OCLocalizedString("Search on the server is unavailable while not connected. To search offline, switch to the Account scope.", nil))

			results = OCDataSourceArray(items: [noResultsView])
		}
	}
}

public extension SearchScopeDescriptor {
	static var server = ServerSideSearchScope.descriptor
}
