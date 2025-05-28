//
//  SearchScope+Registry.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 29.11.24.
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

// MARK: - Registry
public extension SearchScope {
	static var preferredSearchedContent: OCKQLSearchedContent?
	static var defaultSearchScopeIdentifier: SearchScope.Identifier? {
		get {
			return self.classSetting(forOCClassSettingsKey: .defaultScope) as? SearchScope.Identifier
		}
		set {
			SearchScope.setUserPreferenceValue(newValue as? NSString, forClassSettingsKey: .defaultScope)
		}
	}

	static func availableScopes(for clientContext: ClientContext, cellStyle: CollectionViewCellStyle) -> ([SearchScope], SearchScope?) {
		var scopes : [SearchScope] = []
		var defaultScope: SearchScope?

		for descriptor in SearchScopeDescriptor.all {
			if let scope = descriptor.createSearchScope(clientContext, cellStyle) {
				if defaultSearchScopeIdentifier != nil,
				   descriptor.identifier == defaultSearchScopeIdentifier {
					defaultScope = scope
				}
				scopes.append(scope)
			}
		}

		return (scopes, defaultScope)
	}
}

// MARK: - Class settings
public extension OCClassSettingsIdentifier {
	static var search: OCClassSettingsIdentifier { return OCClassSettingsIdentifier(rawValue: "search") }
}

extension OCClassSettingsKey {
	static var defaultScope: OCClassSettingsKey { return OCClassSettingsKey(rawValue: "defaultScope") }
}

extension SearchScope: OCClassSettingsSupport, OCClassSettingsUserPreferencesSupport {
	public static var classSettingsIdentifier: OCClassSettingsIdentifier {
		return .search
	}

	public static func defaultSettings(forIdentifier identifier: OCClassSettingsIdentifier) -> [OCClassSettingsKey : Any]? {
		return [
			.defaultScope : SearchScopeDescriptor.folder.identifier
		]
	}

	public static func allowUserPreference(forClassSettingsKey key: OCClassSettingsKey) -> Bool {
		switch key {
			case .defaultScope:
				return true
			default:
				return false
		}
	}

	public static func classSettingsMetadata() -> [OCClassSettingsKey : [OCClassSettingsMetadataKey : Any]]? {
		var possibleValues: [[OCClassSettingsMetadataKey: Any]] = []

		for descriptor in SearchScopeDescriptor.all {
			possibleValues.append([
				.description : descriptor.localizedName,
				.value : descriptor.identifier
			])
		}

		return [
			.defaultScope : [
				.type 		: OCClassSettingsMetadataType.string,
				.description 	: "The search scope to pre-select when search is invoked inside a folder.",
				.category	: "App",
				.status		: OCClassSettingsKeyStatus.supported,
				.possibleValues	: possibleValues
			]
		]
	}
}
