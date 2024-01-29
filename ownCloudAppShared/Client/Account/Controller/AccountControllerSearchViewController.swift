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
		OCSavedSearch(scope: .account, location: nil, name: "PDF Documents".localized, isTemplate: true, searchTerm: ":pdf").withCustomIcon(name: "doc.richtext").useNameAsTitle(true).isQuickAccess(true),
		OCSavedSearch(scope: .account, location: nil, name: "Documents".localized, isTemplate: true, searchTerm: ":document").withCustomIcon(name: "doc").useNameAsTitle(true).isQuickAccess(true),
		OCSavedSearch(scope: .account, location: nil, name: "Images".localized, isTemplate: true, searchTerm: ":image").withCustomIcon(name: "photo").useNameAsTitle(true).isQuickAccess(true),
		OCSavedSearch(scope: .account, location: nil, name: "Videos".localized, isTemplate: true, searchTerm: ":video").withCustomIcon(name: "film").useNameAsTitle(true).isQuickAccess(true),
		OCSavedSearch(scope: .account, location: nil, name: "Audios".localized, isTemplate: true, searchTerm: ":audio").withCustomIcon(name: "waveform").useNameAsTitle(true).isQuickAccess(true)
	]

	override func composeSuggestionContents(from savedSearches: [OCSavedSearch]?, clientContext: ClientContext, includingFallbacks: Bool) -> [OCDataItem & OCDataItemVersioning] {
		var suggestions = super.composeSuggestionContents(from: savedSearches, clientContext: clientContext, includingFallbacks: false)

		let headerView = ComposedMessageView.sectionHeader(titled: "Quick Access".localized)
		headerView.elementInsets = .zero
		suggestions.insert(headerView, at: 0)

		suggestions.insert(contentsOf: quickAccessSuggestions, at: 1)

		return suggestions
	}
}
