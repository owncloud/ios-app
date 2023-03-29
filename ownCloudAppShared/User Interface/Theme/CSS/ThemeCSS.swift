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
	public static let blurEffectStyle = ThemeCSSProperty(rawValue: "blurEffectStyle") // UIBlurEffect.Style
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

		if object == nil, !selectors.contains(.all) {
			// If no object is provided, ensure .all is included in the selectors
			selectors.insert(.all, at: 0)
		}

		return get(property, for: selectors)
	}

	open func getColor(_ property: ThemeCSSProperty, selectors: [ThemeCSSSelector]? = nil, state stateSelectors: [ThemeCSSSelector]? = nil, for object: AnyObject?) -> UIColor? {
		let value = get(property, selectors: selectors, state: stateSelectors, for: object)?.value

		if let color = value as? UIColor {
			return color
		}

		if let string = value as? String {
			if string == "none" {
				return nil
			}
			if let hexColor = string.colorFromHex {
				return hexColor
			}
		}

		return nil
	}

	open func getInteger(_ property: ThemeCSSProperty, selectors: [ThemeCSSSelector]? = nil, state stateSelectors: [ThemeCSSSelector]? = nil, for object: AnyObject?) -> Int? {
		return get(property, selectors: selectors, state: stateSelectors, for: object)?.value as? Int
	}

	open func getCGFloat(_ property: ThemeCSSProperty, selectors: [ThemeCSSSelector]? = nil, state stateSelectors: [ThemeCSSSelector]? = nil, for object: AnyObject?) -> CGFloat? {
		return get(property, selectors: selectors, state: stateSelectors, for: object)?.value as? CGFloat
	}

	open func getBool(_ property: ThemeCSSProperty, selectors: [ThemeCSSSelector]? = nil, state stateSelectors: [ThemeCSSSelector]? = nil, for object: AnyObject?) -> Bool? {
		let value = get(property, selectors: selectors, state: stateSelectors, for: object)?.value

		if let bool = value as? Bool {
			return bool
		}

		if let string = value as? String {
			switch string {
				case "true":	return true
				case "false":	return false
				default: break
			}
		}

		return nil
	}

	open func getUserInterfaceStyle(selectors: [ThemeCSSSelector]? = nil, state stateSelectors: [ThemeCSSSelector]? = nil, for object: AnyObject? = nil) -> UIUserInterfaceStyle {
		let value = get(.style, selectors: selectors, state: stateSelectors, for: object)?.value

		if let style = value as? UIUserInterfaceStyle {
			return style
		}

		if let intValue = value as? Int {
			// Convert Int values to UIUserInterfaceStyle if needed
			return UIUserInterfaceStyle(rawValue: intValue) ?? .unspecified
		}

		if let stringValue = value as? String {
			// Convert String values to UIUserInterfaceStyle if needed
			switch stringValue {
				case "unspecified":	return .unspecified
				case "light":		return .light
				case "dark":		return .dark
				default: break
			}
		}

		return .unspecified
	}

	open func getStatusBarStyle(selectors: [ThemeCSSSelector]? = nil, state stateSelectors: [ThemeCSSSelector]? = nil, for object: AnyObject?) -> UIStatusBarStyle? {
		let value = get(.statusBarStyle, selectors: selectors, state: stateSelectors, for: object)?.value

		if let style = value as? UIStatusBarStyle {
			return style
		}

		if let intValue = value as? Int {
			// Convert Int values to UIStatusBarStyle if needed
			return UIStatusBarStyle(rawValue: intValue)
		}

		if let stringValue = value as? String {
			// Convert String values to UIStatusBarStyle if needed
			switch stringValue {
				case "default":		return .default
				case "lightContent":	return .lightContent
				case "darkContent":	return .darkContent
				default: break
			}
		}

		return nil
	}

	open func getBarStyle(selectors: [ThemeCSSSelector]? = nil, state stateSelectors: [ThemeCSSSelector]? = nil, for object: AnyObject?) -> UIBarStyle? {
		let value = get(.barStyle, selectors: selectors, state: stateSelectors, for: object)?.value

		if let style = value as? UIBarStyle {
			return style
		}

		if let intValue = value as? Int {
			// Convert Int values to UIBarStyle if needed
			return UIBarStyle(rawValue: intValue)
		}

		if let stringValue = value as? String {
			// Convert String values to UIBarStyle if needed
			switch stringValue {
				case "default":	return .default
				case "black":	return .black
				default: break
			}
		}

		return nil
	}

	open func getKeyboardAppearance(selectors: [ThemeCSSSelector]? = nil, state stateSelectors: [ThemeCSSSelector]? = nil, for object: AnyObject? = nil) -> UIKeyboardAppearance {
		let value = get(.keyboardAppearance, selectors: selectors, state: stateSelectors, for: object)?.value

		if let style = value as? UIKeyboardAppearance {
			return style
		}

		if let intValue = value as? Int {
			// Convert Int values to UIKeyboardAppearance if needed
			return UIKeyboardAppearance(rawValue: intValue) ?? .default
		}

		if let stringValue = value as? String {
			// Convert String values to UIKeyboardAppearance if needed
			switch stringValue {
				case "default":	return .default
				case "light":	return .light
				case "dark":	return .dark
				default: break
			}
		}

		return .default
	}

	open func getActivityIndicatorStyle(selectors: [ThemeCSSSelector]? = nil, state stateSelectors: [ThemeCSSSelector]? = nil, for object: AnyObject? = nil) -> UIActivityIndicatorView.Style? {
		let value = get(.activityIndicatorStyle, selectors: selectors, state: stateSelectors, for: object)?.value

		if let style = value as? UIActivityIndicatorView.Style {
			return style
		}

		if let intValue = value as? Int {
			// Convert Int values to UIActivityIndicatorView.Style if needed
			return UIActivityIndicatorView.Style(rawValue: intValue)
		}

		if let stringValue = value as? String {
			// Convert String values to UIActivityIndicatorView.Style if needed
			switch stringValue {
				case "medium", "white", "gray":	return .medium
				case "whiteLarge", "large":	return .large
				default: break
			}
		}

		return nil
	}

	open func getBlurEffectStyle(selectors: [ThemeCSSSelector]? = nil, state stateSelectors: [ThemeCSSSelector]? = nil, for object: AnyObject? = nil) -> UIBlurEffect.Style {
		let value = get(.blurEffectStyle, selectors: selectors, state: stateSelectors, for: object)?.value

		if let style = value as? UIBlurEffect.Style {
			return style
		}

		if let intValue = value as? Int, let style = UIBlurEffect.Style(rawValue: intValue) {
			// Convert Int values to UIBlurEffect.Style if needed
			return style
		}

		if let stringValue = value as? String {
			// Convert String values to UIBlurEffect.Style if needed
			switch stringValue {
				case "regular":	return .regular
				case "light":	return .light
				case "dark":	return .dark
				default: break
			}
		}

		return .regular
	}
}
