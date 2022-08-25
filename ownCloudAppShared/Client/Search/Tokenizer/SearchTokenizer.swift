//
//  SearchTokenizer.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 12.08.22.
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
import ownCloudApp

// Base search tokenizer class
open class SearchTokenizer: NSObject {
	weak var scope: SearchScope?
	public var clientContext: ClientContext?

	var elements : [SearchElement] = []

	weak var searchField: UISearchTextField?

	open func updateFor(searchField: UISearchTextField) {
		let searchText = searchField.text
		let cursorOffset = searchField.cursorPositionInTextualRange

		self.searchField = searchField

		var searchTokens : [SearchToken] = []

		for token in searchField.tokens {
			if let searchToken = token.representedObject as? SearchToken {
				searchTokens.append(searchToken)
			}
		}

		updateForSearchTerm((searchText != "") ? searchText : nil, cursorOffset: cursorOffset, tokens: searchTokens)
	}

	open func updateForSearchTerm(_ term: String?, cursorOffset: Int?, tokens: [SearchToken]) {
		var assembledTokens : [SearchToken] = []
		var assembledElements : [SearchElement] = []

		// Find terms and tokens in provided searchTerm
		if let searchSegments = term?.segmentedForSearch(withQuotationMarks: false, cursorPosition: (cursorOffset as? NSNumber)) {
			Log.log("SearchSegments: \(String.init(describing: searchSegments))")

			for searchSegment in searchSegments.reversed() { // Iterate segments in reverse so that replacing a segment doesn't change its position
				if !searchSegment.hasCursor, let token = shouldTokenize(segment: searchSegment) {
					// Create token from search segment and insert it position 0 (remember: we're iterating segments in reverse!)
					assembledTokens.insert(token, at: 0)
					replace(segment: searchSegment, with: token)
				} else {
					// Create search term text element and insert it position 0 (remember: we're iterating segments in reverse!)
					assembledElements.insert(composeTextElement(segment: searchSegment), at: 0)
				}
			}
		}

		// Insert existing tokens at the front of the found tokens
		assembledTokens.insert(contentsOf: tokens, at: 0)

		// Insert tokens in front of elements
		assembledElements.insert(contentsOf: assembledTokens, at: 0)

		// Tell scope to update for the provided elements
		scope?.updateFor(assembledElements)
	}

	// MARK: UISearchToken generation
	open func replace(segment: OCSearchSegment, with searchToken: SearchToken) {
		var replaceRange = segment.range
		replaceRange.length += 1 // remove trailing space as well as the spaces accumulate otherwise

		if let replaceRange = searchField?.textRange(from: replaceRange) {
			let token = UISearchToken(icon: searchToken.icon, text: searchToken.text)
			token.representedObject = searchToken

			searchField?.replace(replaceRange, withText: "")
			searchField?.insertToken(token, at: searchField?.tokens.count ?? 0)
		}
	}

	public init(scope: SearchScope, clientContext: ClientContext?) {
		super.init()

		self.scope = scope
		self.clientContext = clientContext
	}

	// MARK: - Conversion to token & text element
	open func shouldTokenize(segment: OCSearchSegment) -> SearchToken? {
		// No tokenization
		return nil
	}

	open func composeTextElement(segment: OCSearchSegment) -> SearchElement {
		// Conversion of text elements in SearchElements
		return SearchElement(text: segment.segmentedString, representedObject: nil, inputComplete: !segment.hasCursor)
	}
}
