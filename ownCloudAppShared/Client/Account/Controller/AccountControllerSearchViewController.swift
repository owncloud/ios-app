//
//  AccountControllerSearchViewController.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 17.01.24.
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

class AccountControllerSearchViewController: ClientItemViewController {
	convenience init(context inContext: ClientContext) {
		self.init(context: inContext, query: nil, itemsDatasource: OCDataSourceArray())
		revoke(in: inContext, when: [ .connectionClosed ])
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		// Bring up search
		startSearch()
	}

	override var searchViewController: SearchViewController? {
		didSet {
			// Modify newly created SearchViewController before it is used
			searchViewController?.showCancelButton = false
			searchViewController?.hideNavigationButtons = false
		}
	}

	let quickAccessSuggestions: [OCSavedSearch] = [
		OCSavedSearch(scope: .account, location: nil, name: OCLocalizedString("PDF Documents", nil), isTemplate: true, searchTerm: ":pdf").withCustomIcon(name: "doc.richtext").useNameAsTitle(true).isQuickAccess(true),
		OCSavedSearch(scope: .account, location: nil, name: OCLocalizedString("Documents", nil), isTemplate: true, searchTerm: ":document").withCustomIcon(name: "doc").useNameAsTitle(true).isQuickAccess(true),
		OCSavedSearch(scope: .account, location: nil, name: OCLocalizedString("Images", nil), isTemplate: true, searchTerm: ":image").withCustomIcon(name: "photo").useNameAsTitle(true).isQuickAccess(true),
		OCSavedSearch(scope: .account, location: nil, name: OCLocalizedString("Videos", nil), isTemplate: true, searchTerm: ":video").withCustomIcon(name: "film").useNameAsTitle(true).isQuickAccess(true),
		OCSavedSearch(scope: .account, location: nil, name: OCLocalizedString("Audios", nil), isTemplate: true, searchTerm: ":audio").withCustomIcon(name: "waveform").useNameAsTitle(true).isQuickAccess(true)
	]

	override func composeSuggestionContents(from savedSearches: [OCSavedSearch]?, clientContext: ClientContext, includingFallbacks: Bool) -> [OCDataItem & OCDataItemVersioning] {
		var suggestions = super.composeSuggestionContents(from: savedSearches, clientContext: clientContext, includingFallbacks: false)

		let savedSearches = clientContext.core?.vault.savedSearches ?? []
		var thinnedQuickAccessSuggestions : [OCSavedSearch] = []

		for quickAccessSuggestion in quickAccessSuggestions {
			let storedSearch = savedSearches.first(where: { storedSavedSearch in
				return 	storedSavedSearch.searchTerm == quickAccessSuggestion.searchTerm &&
					storedSavedSearch.customIconName == quickAccessSuggestion.customIconName &&
					storedSavedSearch.name == quickAccessSuggestion.name &&
					storedSavedSearch.isTemplate != quickAccessSuggestion.isTemplate &&
					storedSavedSearch.isQuickAccess == quickAccessSuggestion.isQuickAccess &&
					storedSavedSearch.useNameAsTitle == quickAccessSuggestion.useNameAsTitle &&
					storedSavedSearch.scope == quickAccessSuggestion.scope
			})

			if storedSearch == nil {
				thinnedQuickAccessSuggestions.append(quickAccessSuggestion)
			}
		}

		if thinnedQuickAccessSuggestions.count > 0 {
			let headerView = ComposedMessageView.sectionHeader(titled: OCLocalizedString("Quick Access", nil))
			headerView.elementInsets = .zero
			suggestions.insert(headerView, at: 0)

			suggestions.insert(contentsOf: thinnedQuickAccessSuggestions, at: 1)
		}

		return suggestions
	}

	override func search(for viewController: SearchViewController, content: SearchViewController.Content?) {
		// Disable dragging of items, so keyboard control does not include "Drag Item"
		// in the accessibility actions invoked with Tab + Z for (Quick Access) suggestions
		dragInteractionEnabled = (content?.type == .suggestion) ? false : true

		super.search(for: viewController, content: content)
	}
}
