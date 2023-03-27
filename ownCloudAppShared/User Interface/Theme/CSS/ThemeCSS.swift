//
//  ThemeCSS.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 19.03.23.
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

// MARK: - Selectors
public struct ThemeCSSSelector: RawRepresentable, Equatable {
	public var rawValue: String

	public init(rawValue: String) {
		self.rawValue = rawValue
	}

	// Catch-all selector that *everything* matches
	public static let all = ThemeCSSSelector(rawValue: "all")

	// Presented view controllers
	public static let modal = ThemeCSSSelector(rawValue: "modal")

	// Splitview region selectors (sidebar + presented content)
	public static let sidebar = ThemeCSSSelector(rawValue: "sidebar")
	public static let content = ThemeCSSSelector(rawValue: "content")
	public static let separator = ThemeCSSSelector(rawValue: "separator")

	// Bars on top and bottom
	public static let navigationBar = ThemeCSSSelector(rawValue: "navigationBar")
	public static let toolbar = ThemeCSSSelector(rawValue: "toolbar")
	public static let tabBar = ThemeCSSSelector(rawValue: "tabbar")

	// Content structure
	public static let table = ThemeCSSSelector(rawValue: "table")
	public static let collection = ThemeCSSSelector(rawValue: "collection")
	public static let header = ThemeCSSSelector(rawValue: "header")
	public static let footer = ThemeCSSSelector(rawValue: "footer")
	public static let sectionHeader = ThemeCSSSelector(rawValue: "sectionHeader")
	public static let sectionFooter = ThemeCSSSelector(rawValue: "sectionFooter")
	public static let cell = ThemeCSSSelector(rawValue: "cell")
	public static let accessory = ThemeCSSSelector(rawValue: "accessory")

	// Content Elements
	public static let splitView = ThemeCSSSelector(rawValue: "splitView")
	public static let alert = ThemeCSSSelector(rawValue: "alert")
	public static let label = ThemeCSSSelector(rawValue: "label")
	public static let button = ThemeCSSSelector(rawValue: "button")
	public static let slider = ThemeCSSSelector(rawValue: "slider")
	public static let progress = ThemeCSSSelector(rawValue: "progress")
	public static let activityIndicator = ThemeCSSSelector(rawValue: "activityIndicator")
	public static let textField = ThemeCSSSelector(rawValue: "textField")
	public static let textView = ThemeCSSSelector(rawValue: "textView")
	public static let searchField = ThemeCSSSelector(rawValue: "searchField")
	public static let datePicker = ThemeCSSSelector(rawValue: "datePicker")
	public static let popupButton = ThemeCSSSelector(rawValue: "popupButton")
	public static let placeholder = ThemeCSSSelector(rawValue: "placeholder")
	public static let segmentedControl = ThemeCSSSelector(rawValue: "segmentedControl")
	public static let group = ThemeCSSSelector(rawValue: "group")
	public static let icon = ThemeCSSSelector(rawValue: "icon")
	public static let item = ThemeCSSSelector(rawValue: "item")
	public static let background = ThemeCSSSelector(rawValue: "background")
	public static let border = ThemeCSSSelector(rawValue: "border")
	public static let shadow = ThemeCSSSelector(rawValue: "shadow")

	// Purpose
	public static let title = ThemeCSSSelector(rawValue: "title")
	public static let subtitle = ThemeCSSSelector(rawValue: "subtitle")
	public static let description = ThemeCSSSelector(rawValue: "description")

	public static let primary = ThemeCSSSelector(rawValue: "primary")
	public static let secondary = ThemeCSSSelector(rawValue: "secondary")
	public static let tertiary = ThemeCSSSelector(rawValue: "tertiary")

	public static let info = ThemeCSSSelector(rawValue: "info")
	public static let warning = ThemeCSSSelector(rawValue: "warning")
	public static let critical = ThemeCSSSelector(rawValue: "critical")
	public static let error = ThemeCSSSelector(rawValue: "error")
	public static let success = ThemeCSSSelector(rawValue: "success")

	public static let confirm = ThemeCSSSelector(rawValue: "confirm")
	public static let destructive = ThemeCSSSelector(rawValue: "destructive")
	public static let cancel = ThemeCSSSelector(rawValue: "cancel")
	public static let proceed = ThemeCSSSelector(rawValue: "proceed")
	public static let purchase = ThemeCSSSelector(rawValue: "purchase")
	public static let favorite = ThemeCSSSelector(rawValue: "favorite")

	public static let plain = ThemeCSSSelector(rawValue: "plain")
	public static let token = ThemeCSSSelector(rawValue: "token")

	// States
	public static let highlighted = ThemeCSSSelector(rawValue: "highlighted")
	public static let selected = ThemeCSSSelector(rawValue: "selected")
	public static let disabled = ThemeCSSSelector(rawValue: "disabled")
	public static let filled = ThemeCSSSelector(rawValue: "filled")

	// Configurations
	public static let grouped = ThemeCSSSelector(rawValue: "grouped")
	public static let insetGrouped = ThemeCSSSelector(rawValue: "insetGrouped")
}

// MARK: - Properties
public struct ThemeCSSProperty: RawRepresentable, Equatable {
	public var rawValue: String

	public init(rawValue: String) {
		self.rawValue = rawValue
	}

	// Colors
	public static let stroke = ThemeCSSProperty(rawValue: "stroke")
	public static let fill = ThemeCSSProperty(rawValue: "fill")

	// Integers
	public static let cornerRadius = ThemeCSSProperty(rawValue: "cornerRadius")

	// Others
	public static let style = ThemeCSSProperty(rawValue: "style") // UIUserInterfaceStyle
	public static let barStyle = ThemeCSSProperty(rawValue: "barStyle") // UIBarStyle
	public static let statusBarStyle = ThemeCSSProperty(rawValue: "statusBarStyle") // UIStatusBarStyle
	public static let keyboardAppearance = ThemeCSSProperty(rawValue: "keyboardAppearance") // UIKeyboardAppearance
	public static let activityIndicatorStyle = ThemeCSSProperty(rawValue: "activityIndicatorStyle") // UIActivityIndicatorView.Style
}

// MARK: - CSS
open class ThemeCSS: NSObject {
	open var records: [ThemeCSSRecord] = []

	open func add(record: ThemeCSSRecord) {
		records.append(record)
	}

	open func add(records: [ThemeCSSRecord]) {
		self.records.append(contentsOf: records)
	}

	open func get(_ property: ThemeCSSProperty, for selectors: [ThemeCSSSelector]) -> ThemeCSSRecord? {
		var bestRecord: ThemeCSSRecord?
		var bestRecordScore: Int = -1

		for record in records {
			let score = record.score(for: selectors, property: property)

			if score != -1, score >= bestRecordScore { // prefer later records over previous records to allow overriding by records added later without having to replace the previous one
				bestRecordScore = score
				bestRecord = record
			}
		}

		return bestRecord
	}

	open func get(_ property: ThemeCSSProperty, selectors additionalSelectors: [ThemeCSSSelector]? = nil, state stateSelectors: [ThemeCSSSelector]? = nil, for object: AnyObject?) -> ThemeCSSRecord? {
		var selectors = (object as? NSObject)?.cascadingStyleSelectors ?? []

		if let additionalSelectors {
			selectors.append(contentsOf: additionalSelectors)
		}

		if let stateSelectors {
			// The last selector is weighted higher because it typically is used to describe the type
			// To not interfere with this convention, selectors representing state are inserted before the last selector
			selectors.insert(contentsOf: stateSelectors, at: (selectors.count > 0) ? selectors.count - 1 : 0)
		}

		return get(property, for: selectors)
	}

	open func getColor(_ property: ThemeCSSProperty, selectors: [ThemeCSSSelector]? = nil, state stateSelectors: [ThemeCSSSelector]? = nil, for object: AnyObject?) -> UIColor? {
		return get(property, selectors: selectors, state: stateSelectors, for: object)?.value as? UIColor
	}

	open func getInteger(_ property: ThemeCSSProperty, selectors: [ThemeCSSSelector]? = nil, state stateSelectors: [ThemeCSSSelector]? = nil, for object: AnyObject?) -> Int? {
		return get(property, selectors: selectors, state: stateSelectors, for: object)?.value as? Int
	}

	open func getCGFloat(_ property: ThemeCSSProperty, selectors: [ThemeCSSSelector]? = nil, state stateSelectors: [ThemeCSSSelector]? = nil, for object: AnyObject?) -> CGFloat? {
		return get(property, selectors: selectors, state: stateSelectors, for: object)?.value as? CGFloat
	}

	open func getBool(_ property: ThemeCSSProperty, selectors: [ThemeCSSSelector]? = nil, state stateSelectors: [ThemeCSSSelector]? = nil, for object: AnyObject?) -> Bool? {
		return get(property, selectors: selectors, state: stateSelectors, for: object)?.value as? Bool
	}

	open func getUserInterfaceStyle(selectors: [ThemeCSSSelector]? = nil, state stateSelectors: [ThemeCSSSelector]? = nil, for object: AnyObject?) -> UIUserInterfaceStyle {
		var style = get(.style, selectors: selectors, state: stateSelectors, for: object)?.value as? UIUserInterfaceStyle

		if style == nil, let intValue = getInteger(.style, selectors: selectors, state: stateSelectors, for: object) {
			// Convert int values to UIUserInterfaceStyle if needed
			style = UIUserInterfaceStyle(rawValue: intValue)
		}

		return style ?? .unspecified
	}

	open func getStatusBarStyle(selectors: [ThemeCSSSelector]? = nil, state stateSelectors: [ThemeCSSSelector]? = nil, for object: AnyObject?) -> UIStatusBarStyle? {
		var style = get(.statusBarStyle, selectors: selectors, state: stateSelectors, for: object)?.value as? UIStatusBarStyle

		if style == nil, let intValue = getInteger(.statusBarStyle, selectors: selectors, state: stateSelectors, for: object) {
			// Convert int values to UIStatusBarStyle if needed
			style = UIStatusBarStyle(rawValue: intValue)
		}

		return style
	}

	open func getBarStyle(selectors: [ThemeCSSSelector]? = nil, state stateSelectors: [ThemeCSSSelector]? = nil, for object: AnyObject?) -> UIBarStyle? {
		var style = get(.barStyle, selectors: selectors, state: stateSelectors, for: object)?.value as? UIBarStyle

		if style == nil, let intValue = getInteger(.barStyle, selectors: selectors, state: stateSelectors, for: object) {
			// Convert int values to UIBarStyle if needed
			style = UIBarStyle(rawValue: intValue)
		}

		return style
	}

	open func getKeyboardAppearance(selectors: [ThemeCSSSelector]? = nil, state stateSelectors: [ThemeCSSSelector]? = nil, for object: AnyObject? = nil) -> UIKeyboardAppearance {
		var keyboardAppearance = get(.keyboardAppearance, selectors: selectors, state: stateSelectors, for: object)?.value as? UIKeyboardAppearance

		if keyboardAppearance == nil, let intValue = getInteger(.keyboardAppearance, selectors: selectors, state: stateSelectors, for: object) {
			// Convert int values to UIKeyboardAppearance if needed
			keyboardAppearance = UIKeyboardAppearance(rawValue: intValue)
		}

		return keyboardAppearance ?? .default
	}

	open func getActivityIndicatorStyle(selectors: [ThemeCSSSelector]? = nil, state stateSelectors: [ThemeCSSSelector]? = nil, for object: AnyObject? = nil) -> UIActivityIndicatorView.Style? {
		var indicatorStyle = get(.activityIndicatorStyle, selectors: selectors, state: stateSelectors, for: object)?.value as? UIActivityIndicatorView.Style

		if indicatorStyle == nil, let intValue = getInteger(.activityIndicatorStyle, selectors: selectors, state: stateSelectors, for: object) {
			// Convert int values to UIKeyboardAppearance if needed
			indicatorStyle = UIActivityIndicatorView.Style(rawValue: intValue)
		}

		return indicatorStyle
	}
}
