//
//  ThemeCollection.swift
//  ownCloud
//
//  Created by Felix Schwarz on 10.04.18.
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

// MARK: - Color Sets
private struct ThemeColorSet {
	var labelColor: UIColor
	var secondaryLabelColor: UIColor

	var iconColor: UIColor	//!< Icons (non-interactive)
	var tintColor: UIColor	//!< User-interactive buttons, accessories

	var backgroundColor: UIColor

	static func from(backgroundColor: UIColor, tintColor: UIColor, for style: UIUserInterfaceStyle) -> ThemeColorSet {
		let preferredTraitCollection = UITraitCollection(userInterfaceStyle: (style == .light) ? .light : .dark)
		let preferredPrimaryLabelColor = UIColor.label.resolvedColor(with: preferredTraitCollection)
		let preferredSecondaryLabelColor = UIColor.secondaryLabel.resolvedColor(with: preferredTraitCollection).withHighContrastAlternative(.label.resolvedColor(with: preferredTraitCollection))

		let alternateTraitCollection = UITraitCollection(userInterfaceStyle: (style == .light) ? .dark : .light)
		let alternatePrimaryLabelColor = UIColor.label.resolvedColor(with: alternateTraitCollection)
		let alternateSecondaryLabelColor = UIColor.secondaryLabel.resolvedColor(with: alternateTraitCollection).withHighContrastAlternative(.label.resolvedColor(with: alternateTraitCollection))

		let labelColor = backgroundColor.preferredContrastColor(from: [preferredPrimaryLabelColor, alternatePrimaryLabelColor]) ?? preferredPrimaryLabelColor
		let secondaryLabelColor = backgroundColor.preferredContrastColor(from: [preferredSecondaryLabelColor, alternateSecondaryLabelColor]) ?? preferredSecondaryLabelColor
		let iconColor = labelColor

		return ThemeColorSet(labelColor: labelColor, secondaryLabelColor: secondaryLabelColor, iconColor: iconColor, tintColor: tintColor, backgroundColor: backgroundColor)
	}

	func disabledSet(for style: UIUserInterfaceStyle) -> ThemeColorSet {
		return ThemeColorSet(labelColor: secondaryLabelColor.greyscale, secondaryLabelColor: secondaryLabelColor.greyscale, iconColor: secondaryLabelColor.greyscale, tintColor: tintColor.greyscale, backgroundColor: backgroundColor.greyscale)
	}

	func highlightedSet(for style: UIUserInterfaceStyle) -> ThemeColorSet {
		var highlightedColorSet = self

		switch style {
			case .light: highlightedColorSet.backgroundColor = highlightedColorSet.backgroundColor.darker(0.10)
			case .dark:  highlightedColorSet.backgroundColor = highlightedColorSet.backgroundColor.lighter(0.15)
			default: break
		}

		return highlightedColorSet
	}
}

private struct ThemeColorStateSet {
	var regular: ThemeColorSet

	var selected: ThemeColorSet
	var highlighted: ThemeColorSet
	var disabled: ThemeColorSet

	static func from(colorSet: ThemeColorSet, for style: UIUserInterfaceStyle) -> ThemeColorStateSet {
		let highlightedSet = colorSet.highlightedSet(for: style)

		return ThemeColorStateSet(regular: colorSet, selected: highlightedSet, highlighted: highlightedSet, disabled: colorSet.disabledSet(for: style))
	}
}

private class ThemeColorPair : NSObject {
	@objc public var foreground: UIColor
	@objc public var background: UIColor

	public init(foreground fgColor: UIColor, background bgColor: UIColor) {
		foreground = fgColor
		background = bgColor
	}
}

private class ThemeColorPairCollection : NSObject {
	@objc public var normal : ThemeColorPair
	@objc public var highlighted : ThemeColorPair
	@objc public var disabled : ThemeColorPair

	public init(fromPair: ThemeColorPair) {
		normal = fromPair
		highlighted = ThemeColorPair(foreground: fromPair.foreground, background: fromPair.background.lighter(0.25))
		disabled = ThemeColorPair(foreground: fromPair.foreground, background: fromPair.background.lighter(0.25))
	}

	public init(fromPairCollection: ThemeColorPairCollection) {
		normal = ThemeColorPair(foreground: fromPairCollection.normal.foreground, background: fromPairCollection.normal.background)
		highlighted = ThemeColorPair(foreground: fromPairCollection.highlighted.foreground, background: fromPairCollection.highlighted.background)
		disabled = ThemeColorPair(foreground: fromPairCollection.disabled.foreground, background: fromPairCollection.disabled.background)
	}
}

private class ThemeColorCollection : NSObject {
	@objc public var backgroundColor : UIColor?
	@objc public var labelColor : UIColor
	@objc public var secondaryLabelColor : UIColor
	@objc public var symbolColor : UIColor
	@objc public var tintColor : UIColor?

	@objc public var filledColorPairCollection : ThemeColorPairCollection

	public init(backgroundColor bgColor : UIColor?, tintColor tntColor: UIColor?, labelColor lblColor : UIColor, secondaryLabelColor secLabelColor: UIColor, symbolColor symColor: UIColor, filledColorPairCollection filColorPairCollection: ThemeColorPairCollection) {
		backgroundColor = bgColor
		labelColor = lblColor
		symbolColor = symColor
		secondaryLabelColor = secLabelColor
		tintColor = tntColor
		filledColorPairCollection = filColorPairCollection
	}
}

public enum ThemeCollectionStyle : String, CaseIterable {
	case dark
	case light

	public var name : String {
		switch self {
			case .dark:	return OCLocalizedString("Dark", nil)
			case .light:	return OCLocalizedString("Light", nil)
		}
	}

	public var userInterfaceStyle : UIUserInterfaceStyle {
		switch self {
			case .dark: return .dark
			case .light: return .light
		}
	}
}

public class ThemeCollection : NSObject {
	@objc var identifier : String = UUID().uuidString
	public let style: ThemeCollectionStyle

	public var isDark: Bool {
		style == .dark
	}

	// MARK: - ThemeCSS
	public var css: ThemeCSS

	// MARK: - Default Collection
	static public var defaultCollection : ThemeCollection = {
		let collection = ThemeCollection()

		/*
		Log.log("%@", collection.value(forKeyPath: "tintColor") as! CVarArg)
		Log.log("%@", collection.value(forKeyPath: "toolBarColorCollection.filledColorPairCollection.normal.background") as! CVarArg)
		Log.log("%@", collection.value(forKeyPath: "toolBarColorCollection.filledColorPairCollection.normal.backgrounds") as! CVarArg)
		*/

		return (collection)
	}()

	static var darkCollection : ThemeCollection = {
		let collection = ThemeCollection()

		return (collection)
	}()

	private static func generateColorPairs(with baseSelectors:[ThemeCSSSelector], foregroundColor: UIColor, backgroundColor: UIColor) -> [ThemeCSSRecord] {
		var disabledSelectors = baseSelectors
		disabledSelectors.append(.disabled)
		var highlightedSelectors = baseSelectors
		highlightedSelectors.append(.highlighted)

		let colorPairs: [ThemeCSSRecord] = [
			ThemeCSSRecord(selectors: baseSelectors,		property: .stroke, value: foregroundColor),
			ThemeCSSRecord(selectors: baseSelectors,		property: .fill,   value: backgroundColor),

			ThemeCSSRecord(selectors: highlightedSelectors,		property: .stroke, value: foregroundColor),
			ThemeCSSRecord(selectors: highlightedSelectors,		property: .fill,   value: backgroundColor.lighter(0.25)),

			ThemeCSSRecord(selectors: disabledSelectors,		property: .stroke, value: foregroundColor),
			ThemeCSSRecord(selectors: disabledSelectors,		property: .fill,   value: backgroundColor.lighter(0.25))
		]

		return colorPairs
	}

	private static func generateColorPairs(with baseSelectors:[ThemeCSSSelector], from pairCollection: ThemeColorPairCollection) -> [ThemeCSSRecord] {
		var disabledSelectors = baseSelectors
		disabledSelectors.append(.disabled)
		var highlightedSelectors = baseSelectors
		highlightedSelectors.append(.highlighted)

		let colorPairs: [ThemeCSSRecord] = [
			ThemeCSSRecord(selectors: baseSelectors,		property: .stroke, value: pairCollection.normal.foreground),
			ThemeCSSRecord(selectors: baseSelectors,		property: .fill,   value: pairCollection.normal.background),

			ThemeCSSRecord(selectors: highlightedSelectors,		property: .stroke, value: pairCollection.highlighted.foreground),
			ThemeCSSRecord(selectors: highlightedSelectors,		property: .fill,   value: pairCollection.highlighted.background),

			ThemeCSSRecord(selectors: disabledSelectors,		property: .stroke, value: pairCollection.disabled.foreground),
			ThemeCSSRecord(selectors: disabledSelectors,		property: .fill,   value: pairCollection.disabled.background)
		]

		return colorPairs
	}

	init(darkBrandColor inDarkColor: UIColor, lightBrandColor inLightColor: UIColor, style: ThemeCollectionStyle = .dark, interfaceStyles: NSDictionary? = nil, useSystemColors: Bool = false, systemTintColor: UIColor? = nil) {
		var logoFillColor : UIColor?
		self.style = style
		self.css = ThemeCSS()

		var interfaceStyle : UIUserInterfaceStyle = .unspecified
		var keyboardAppearance : UIKeyboardAppearance = .default
		var backgroundBlurEffectStyle : UIBlurEffect.Style = .regular

		var statusBarStyle : UIStatusBarStyle
		var barStyle : UIBarStyle

		let styleTraitCollection = UITraitCollection(userInterfaceStyle: style.userInterfaceStyle)

		let darkBrandColor = inDarkColor.resolvedColor(with: styleTraitCollection)
		let lightBrandColor = inLightColor.resolvedColor(with: styleTraitCollection)

		let resolvedSystemTintColor: UIColor = systemTintColor ?? .tintColor.resolvedColor(with: styleTraitCollection)

		/*
			Cells:
			- cell		-> lightCell
			- groupedCell	-> lightGroupedCell
			- sidebarCell	-> darkCell
			- accountCell	-> darkGroupedCell

			Bars:
			- topBar
			- sidebarTopBar

			- bottomBar
			- sidebarBottomBar

			Buttons:
			- plain
			- bordered
			- confirm
			- ..
		*/
		var lightBrandSet = ThemeColorSet.from(backgroundColor: lightBrandColor, tintColor: darkBrandColor, for: style.userInterfaceStyle)
		let darkBrandSet = ThemeColorSet.from(backgroundColor: darkBrandColor, tintColor: lightBrandColor, for: style.userInterfaceStyle)

		var cellSet: ThemeColorSet
		var groupedCellSet: ThemeColorSet
		var collectionBackgroundColor: UIColor
		var groupedCollectionBackgroundColor: UIColor
		var accountCellSet: ThemeColorSet
		var sidebarAccountCellSet: ThemeColorSet

		var navigationBarSet: ThemeColorSet
		var toolbarSet: ThemeColorSet
		var contentNavigationBarSet: ThemeColorSet
		var contentToolbarSet: ThemeColorSet

		var cellStateSet: ThemeColorStateSet
		var groupedCellStateSet: ThemeColorStateSet
		var sidebarCellStateSet: ThemeColorStateSet

		var sidebarLogoIconColor: UIColor
		var sidebarLogoLabel: UIColor
		var iconSymbolColor: UIColor

		var inlineActionBackgroundColor: UIColor
		var inlineActionBackgroundColorHighlighted: UIColor

		let tintColor: UIColor = lightBrandColor

		var separatorColor: UIColor = UIColor.opaqueSeparator.resolvedColor(with: styleTraitCollection)
		var sectionHeaderColor: UIColor
		var sectionFooterColor: UIColor
		var groupedSectionHeaderColor: UIColor
		var groupedSectionFooterColor: UIColor

		var moreHeaderBackgroundColor: UIColor

		var modalBackgroundColor: UIColor

		let lightBrandColors = ThemeColorCollection(
			backgroundColor: lightBrandColor,
			tintColor: UIColor.white,
			labelColor: UIColor.white,
			secondaryLabelColor: UIColor.lightGray,
			symbolColor: UIColor.white,
			filledColorPairCollection: ThemeColorPairCollection(fromPair: ThemeColorPair(foreground: UIColor.white, background: lightBrandColor))
		)

		let neutralColors = lightBrandColors.filledColorPairCollection
		let purchaseColors = ThemeColorPairCollection(fromPair: ThemeColorPair(foreground: lightBrandColors.labelColor, background: lightBrandColor))
		purchaseColors.disabled.background = purchaseColors.disabled.background.greyscale

		var tokenForegroundColor = lightBrandColor
		var tokenBackgroundColor = UIColor(white: 0, alpha: 0.1)

		// Table view
		var progressColors : ThemeColorPair

		// Styles
		switch style {
			case .dark:
				// Interface style
				interfaceStyle = .dark
				keyboardAppearance = .dark
				backgroundBlurEffectStyle = .dark
				statusBarStyle = .lightContent
				barStyle = .black

				lightBrandSet.labelColor = .white
				lightBrandSet.secondaryLabelColor = .white
				lightBrandSet.iconColor = .white

				sidebarAccountCellSet = ThemeColorSet.from(backgroundColor: .init(hex: 0, alpha: 0.5), tintColor: lightBrandColor, for: interfaceStyle)
				accountCellSet = sidebarAccountCellSet

				navigationBarSet = darkBrandSet
				toolbarSet = darkBrandSet

				cellSet = ThemeColorSet.from(backgroundColor: HCColor.Structure.appBackground(true), tintColor: lightBrandColor.withHighContrastAlternative(lightBrandColor.lighter(0.3)), for: interfaceStyle)
				cellStateSet = ThemeColorStateSet.from(colorSet: cellSet, for: interfaceStyle)
				collectionBackgroundColor = HCColor.Structure.menuBackground(true)

				groupedCellSet = ThemeColorSet.from(backgroundColor: darkBrandColor, tintColor: lightBrandColor, for: interfaceStyle)
				groupedCellStateSet = ThemeColorStateSet.from(colorSet: groupedCellSet, for: interfaceStyle)
				groupedCollectionBackgroundColor = useSystemColors ? .systemGroupedBackground.resolvedColor(with: styleTraitCollection) : navigationBarSet.backgroundColor.darker(0.3)

				contentNavigationBarSet = cellSet
				contentToolbarSet = cellSet

				sidebarCellStateSet = ThemeColorStateSet.from(colorSet: darkBrandSet, for: interfaceStyle)
				sidebarCellStateSet.selected.backgroundColor = useSystemColors ? resolvedSystemTintColor :  sidebarCellStateSet.regular.labelColor
				sidebarCellStateSet.selected.labelColor = useSystemColors ? .white : sidebarCellStateSet.regular.backgroundColor
				sidebarCellStateSet.selected.iconColor = sidebarCellStateSet.selected.labelColor

				sidebarLogoIconColor = .white
				sidebarLogoLabel = .white
				iconSymbolColor = lightBrandColor

				separatorColor = .darkGray

				sectionHeaderColor = .white
				sectionFooterColor = .lightGray
				groupedSectionHeaderColor = .lightGray
				groupedSectionFooterColor = .lightGray

				moreHeaderBackgroundColor = darkBrandColor.lighter(0.05)

				modalBackgroundColor = darkBrandColor

				inlineActionBackgroundColor = UIColor(white: 1, alpha: 0.10)
				inlineActionBackgroundColorHighlighted = UIColor(white: 1, alpha: 0.05)

				// Bars
				tokenForegroundColor = lightBrandColor
				tokenBackgroundColor = UIColor(white: 1, alpha: 0.1)

				// Progress
				progressColors = ThemeColorPair(foreground: lightBrandColor, background: lightBrandColor.withAlphaComponent(0.3))

				// Logo fill color
				logoFillColor = .white

			case .light:
				// Interface style
				interfaceStyle = .light
				keyboardAppearance = .light
				backgroundBlurEffectStyle = .light
				statusBarStyle = .darkContent
				barStyle = .default

				sidebarAccountCellSet = ThemeColorSet.from(backgroundColor: .white, tintColor: .white, for: interfaceStyle)
				accountCellSet = sidebarAccountCellSet

				navigationBarSet = ThemeColorSet.from(backgroundColor: .systemBackground.resolvedColor(with: styleTraitCollection), tintColor: lightBrandColor, for: interfaceStyle)
				toolbarSet = navigationBarSet

				cellSet = ThemeColorSet.from(backgroundColor: HCColor.Structure.appBackground(false), tintColor: lightBrandColor.withHighContrastAlternative(lightBrandColor.darker(0.3)), for: interfaceStyle)
				cellStateSet = ThemeColorStateSet.from(colorSet: cellSet, for: interfaceStyle)
				collectionBackgroundColor = HCColor.Structure.menuBackground(false)

				groupedCellSet = cellSet
				groupedCellStateSet = ThemeColorStateSet.from(colorSet: groupedCellSet, for: interfaceStyle)
				groupedCollectionBackgroundColor = .systemGroupedBackground.resolvedColor(with: styleTraitCollection)

				contentNavigationBarSet = cellSet
				contentToolbarSet = ThemeColorSet.from(backgroundColor: HCColor.Structure.menuBackground(false), tintColor: lightBrandColor.withHighContrastAlternative(lightBrandColor.darker(0.3)), for: interfaceStyle)

				sidebarCellStateSet = ThemeColorStateSet.from(colorSet: cellSet, for: interfaceStyle)
				sidebarCellStateSet.regular.backgroundColor =  .secondarySystemBackground.resolvedColor(with: styleTraitCollection)
				sidebarCellStateSet.selected.labelColor = .white
				sidebarCellStateSet.selected.iconColor = .white
				sidebarCellStateSet.selected.backgroundColor = useSystemColors ? resolvedSystemTintColor : darkBrandColor

				sidebarLogoIconColor = darkBrandColor
				sidebarLogoLabel = darkBrandColor
				iconSymbolColor = darkBrandColor

				sectionHeaderColor = .label.resolvedColor(with: styleTraitCollection)
				sectionFooterColor = .secondaryLabel.resolvedColor(with: styleTraitCollection).withHighContrastAlternative(sectionHeaderColor) // aka "resolved system .label color" in this case
				groupedSectionHeaderColor = .secondaryLabel.resolvedColor(with: styleTraitCollection).withHighContrastAlternative(sectionHeaderColor)
				groupedSectionFooterColor = .secondaryLabel.resolvedColor(with: styleTraitCollection).withHighContrastAlternative(sectionHeaderColor)

				moreHeaderBackgroundColor = cellSet.backgroundColor

				modalBackgroundColor = collectionBackgroundColor

				inlineActionBackgroundColor = UIColor(white: 0, alpha: 0.05)
				inlineActionBackgroundColorHighlighted = UIColor(white: 0, alpha: 0.10)

				// Progress
				progressColors = ThemeColorPair(foreground: lightBrandColor, background: UIColor.lightGray.withAlphaComponent(0.3))

				// Logo fill color
				logoFillColor = .lightGray
		}

		// Fixed colors
		let primaryLabelColor = cellSet.labelColor // UIColor.label.resolvedColor(with: styleTraitCollection)
		let secondaryLabelColor = cellSet.secondaryLabelColor // UIColor.secondaryLabel.resolvedColor(with: styleTraitCollection)
		let tertiaryLabelColor = cellSet.secondaryLabelColor // UIColor.tertiaryLabel.resolvedColor(with: styleTraitCollection)
		let placeholderTextColor = cellSet.secondaryLabelColor // UIColor.placeholderText.resolvedColor(with: styleTraitCollection)

		let primaryBackgroundColor = UIColor.systemBackground.resolvedColor(with: styleTraitCollection)
		let secondaryBackgroundColor = UIColor.secondarySystemBackground.resolvedColor(with: styleTraitCollection)
		let tertiaryBackgroundColor = UIColor.tertiarySystemBackground.resolvedColor(with: styleTraitCollection)

		let progressForegroundColor = progressColors.foreground
		let progressBackgroundColor = progressColors.background

		let favoriteEnabledColor = UIColor(hex: 0xFFCC00)
		let favoriteDisabledColor = UIColor(hex: 0x7C7C7C)

		let isDark = style == .dark

		// CSS
		css.add(records: [
			// Global styles
			// - Interface Style
			ThemeCSSRecord(selectors: [.all], 			   	property: .style, value: interfaceStyle),

			// - Blur Effect Style
			ThemeCSSRecord(selectors: [.all], 			   	property: .blurEffectStyle, value: backgroundBlurEffectStyle),

			// - Status Bar
			ThemeCSSRecord(selectors: [.all], 			   	property: .statusBarStyle, value: statusBarStyle),

			// - Bar
			ThemeCSSRecord(selectors: [.all], 			   	property: .barStyle, value: barStyle),

			// - Activity Indicator
			ThemeCSSRecord(selectors: [.all], 			   	property: .activityIndicatorStyle, value: UIActivityIndicatorView.Style.medium),

			// General

			// - Navigation Bar
			ThemeCSSRecord(selectors: [.navigationBar], property: .stroke, value: HCColor.Content.textPrimary(isDark)),
			ThemeCSSRecord(selectors: [.navigationBar, .label], property: .stroke, value: HCColor.Content.textPrimary(isDark)),
			ThemeCSSRecord(selectors: [.navigationBar, .label, .title], property: .stroke, value: HCColor.Content.textPrimary(isDark)),
			ThemeCSSRecord(selectors: [.navigationBar], property: .fill, value: HCColor.Structure.cardBackground(isDark)),
			ThemeCSSRecord(selectors: [.navigationBar, .button], property: .fill, value: HCColor.Interaction.primarySolidNormal(isDark)),
			ThemeCSSRecord(selectors: [.navigationBar, .popupButton, .icon],property: .stroke, value: HCColor.Content.textPrimary(isDark)),
			ThemeCSSRecord(selectors: [.navigationBar, .popupButton, .icon],property: .fill,   value: UIColor(white: 0.5, alpha: 0.3)),

			// - Toolbar
			ThemeCSSRecord(selectors: [.toolbar],				property: .stroke, value: toolbarSet.tintColor),
			ThemeCSSRecord(selectors: [.toolbar], property: .fill, value: HCColor.Structure.menuBackground(isDark)),

			// - Progress
			ThemeCSSRecord(selectors: [.progress], 				property: .fill,  value: progressBackgroundColor),
			ThemeCSSRecord(selectors: [.progress], 				property: .stroke,value: progressForegroundColor),
			ThemeCSSRecord(selectors: [.progress, .button],			property: .fill,  value: tintColor),

			// - Cells
			ThemeCSSRecord(selectors: [.cell, .sectionHeader],		property: .stroke, value: sectionHeaderColor),

			// - Modal
			ThemeCSSRecord(selectors: [.modal],     	    	   	property: .fill,   value: modalBackgroundColor),
			ThemeCSSRecord(selectors: [.modal, .issues, .table],		property: .fill,   value: modalBackgroundColor),
			ThemeCSSRecord(selectors: [.modal, .issues, .table, .cell],	property: .fill,   value: modalBackgroundColor),
			ThemeCSSRecord(selectors: [.modal],     	    	   	property: .stroke, value: cellSet.labelColor),

			// - Splitview
			ThemeCSSRecord(selectors: [.splitView],     	    	   	property: .fill,   value: HCColor.Structure.menuBackground(isDark)),

			// - Collection View
			ThemeCSSRecord(selectors: [.collection],     	    	   	property: .fill,   value: cellStateSet.regular.backgroundColor),
			ThemeCSSRecord(selectors: [.collection, .highlighted, .cell],  	property: .fill,   value: cellStateSet.highlighted.backgroundColor),
			ThemeCSSRecord(selectors: [.collection, .cell], 	   	property: .stroke, value: cellStateSet.regular.tintColor),
			ThemeCSSRecord(selectors: [.collection, .cell,.title], 		property: .stroke, value: cellStateSet.regular.labelColor),
			ThemeCSSRecord(selectors: [.collection, .cell,.segments], 	property: .stroke, value: cellStateSet.regular.secondaryLabelColor),
			ThemeCSSRecord(selectors: [.collection, .cell,.segments], 	property: .fill,   value: UIColor.clear),
			ThemeCSSRecord(selectors: [.collection, .cell,.segments,.icon], property: .stroke, value: cellStateSet.regular.secondaryLabelColor),
			ThemeCSSRecord(selectors: [.collection, .cell,.segments,.title],property: .stroke, value: cellStateSet.regular.secondaryLabelColor),

			ThemeCSSRecord(selectors: [.collection, .cell,.segments,.focused],property: .stroke, value: cellStateSet.regular.labelColor),
			ThemeCSSRecord(selectors: [.collection, .cell,.segments,.focused,.icon],property: .stroke, value: cellStateSet.regular.labelColor),
			ThemeCSSRecord(selectors: [.collection, .cell,.segments,.focused,.title],property: .stroke, value: cellStateSet.regular.labelColor),

			ThemeCSSRecord(selectors: [.collection, .sectionFooter], 	property: .stroke, value: sectionFooterColor),
			ThemeCSSRecord(selectors: [.collection, .cell], 	   	property: .fill,   value: cellStateSet.regular.backgroundColor),

			ThemeCSSRecord(selectors: [.collection, .selectionCheckmark], 			property: .fill,   value: cellStateSet.regular.tintColor),
			ThemeCSSRecord(selectors: [.collection, .selectionCheckmark], 			property: .stroke, value: cellStateSet.regular.backgroundColor),

			ThemeCSSRecord(selectors: [.collection, .selected, .selectionCheckmark], 		property: .stroke,   value: UIColor.white),

			ThemeCSSRecord(selectors: [.grouped, .collection],  	   			property: .fill,   value: HCColor.Structure.appBackground(isDark)),
			ThemeCSSRecord(selectors: [.insetGrouped, .collection],    			property: .fill,   value: HCColor.Structure.appBackground(isDark)),
			ThemeCSSRecord(selectors: [.grouped, .collection, .sectionHeader],  		property: .fill,   value: HCColor.Structure.appBackground(isDark)),
			ThemeCSSRecord(selectors: [.grouped, .collection, .sectionHeader, .cell],	property: .fill,   value: UIColor.clear),
			ThemeCSSRecord(selectors: [.grouped, .collection, .cell],  			property: .fill,   value: HCColor.Structure.appBackground(isDark)),
			ThemeCSSRecord(selectors: [.grouped, .collection, .cell, .action],  		property: .fill,   value: cellStateSet.regular.backgroundColor),
			ThemeCSSRecord(selectors: [.insetGrouped, .collection, .sectionHeader], 	property: .fill,   value: HCColor.Structure.appBackground(isDark)),
			ThemeCSSRecord(selectors: [.insetGrouped, .collection, .sectionHeader, .cell, .title],	property: .fill,   value: UIColor.clear),
			ThemeCSSRecord(selectors: [.insetGrouped, .collection, .sectionHeader, .cell, .mediumTitle],	property: .fill,   value: UIColor.clear),
			ThemeCSSRecord(selectors: [.insetGrouped, .collection, .sectionHeader, .cell, .smallTitle],	property: .fill,   value: UIColor.clear),

			ThemeCSSRecord(selectors: [.insetGrouped, .collection, .cell, .action], 	property: .fill,   value: HCColor.Structure.cardBackground(isDark)),
			ThemeCSSRecord(selectors: [.insetGrouped, .collection, .cell], property: .fill,   value: HCColor.Structure.cardBackground(isDark)),

			// - Table View
			ThemeCSSRecord(selectors: [.table],     	    	   	property: .fill,   value: cellStateSet.regular.backgroundColor),
			ThemeCSSRecord(selectors: [.grouped, .table],  	    	   	property: .fill,   value: groupedCollectionBackgroundColor),
			ThemeCSSRecord(selectors: [.insetGrouped, .table],    	   	property: .fill,   value: groupedCollectionBackgroundColor),

			ThemeCSSRecord(selectors: [.table, .cell],    			property: .stroke, value: cellStateSet.regular.tintColor), // tableRowColors.tintColor),
			ThemeCSSRecord(selectors: [.table, .cell],     	    	   	property: .fill,   value: cellStateSet.regular.backgroundColor),
			ThemeCSSRecord(selectors: [.table, .highlighted, .cell],     	property: .fill,   value: cellStateSet.highlighted.backgroundColor),

			ThemeCSSRecord(selectors: [.grouped, .table, .cell],			property: .stroke, value: groupedCellStateSet.regular.tintColor), // tableRowColors.tintColor),
			ThemeCSSRecord(selectors: [.grouped, .table, .cell, .label],		property: .stroke, value: groupedCellStateSet.regular.labelColor),
			ThemeCSSRecord(selectors: [.grouped, .table, .cell],			property: .fill,   value: groupedCellStateSet.regular.backgroundColor),
			ThemeCSSRecord(selectors: [.grouped, .table, .highlighted, .cell],	property: .fill,   value: groupedCellStateSet.highlighted.backgroundColor),

			ThemeCSSRecord(selectors: [.grouped, .table, .sectionHeader],    	property: .stroke, value: groupedSectionHeaderColor),
			ThemeCSSRecord(selectors: [.grouped, .table, .sectionFooter],    	property: .stroke, value: groupedSectionFooterColor),

			ThemeCSSRecord(selectors: [.insetGrouped, .table, .cell],		property: .stroke, value: groupedCellStateSet.regular.tintColor), // tableRowColors.tintColor),
			ThemeCSSRecord(selectors: [.insetGrouped, .table, .cell],		property: .fill,   value: groupedCellStateSet.regular.backgroundColor),
			ThemeCSSRecord(selectors: [.insetGrouped, .table, .highlighted, .cell],	property: .fill,   value: groupedCellStateSet.highlighted.backgroundColor),

			ThemeCSSRecord(selectors: [.insetGrouped, .table, .sectionHeader],    	property: .stroke, value: groupedSectionHeaderColor),
			ThemeCSSRecord(selectors: [.insetGrouped, .table, .sectionFooter],    	property: .stroke, value: groupedSectionFooterColor),

			ThemeCSSRecord(selectors: [.table, .sectionHeader],    			property: .stroke, value: sectionHeaderColor),
			ThemeCSSRecord(selectors: [.table, .sectionFooter],    			property: .stroke, value: sectionFooterColor),

			ThemeCSSRecord(selectors: [.table, .icon],    				property: .stroke, value: cellStateSet.regular.iconColor),
			ThemeCSSRecord(selectors: [.table, .label, .primary],    		property: .stroke, value: cellStateSet.regular.labelColor),
			ThemeCSSRecord(selectors: [.table, .label, .secondary], 		property: .stroke, value: cellStateSet.regular.secondaryLabelColor),
			ThemeCSSRecord(selectors: [.table, .label, .highlighted, .primary],    	property: .stroke, value: cellStateSet.highlighted.labelColor),
			ThemeCSSRecord(selectors: [.table, .label, .highlighted, .secondary], 	property: .stroke, value: cellStateSet.highlighted.secondaryLabelColor),

			// - Section titles
			ThemeCSSRecord(selectors: [.sectionHeader, .mediumTitle, .label],	property: .stroke, value: cellStateSet.regular.secondaryLabelColor),
			ThemeCSSRecord(selectors: [.sectionHeader, .smallTitle, .label],	property: .stroke, value: cellStateSet.regular.secondaryLabelColor),

			// - Accessories
			ThemeCSSRecord(selectors: [.accessory], 			property: .stroke, value: cellStateSet.regular.secondaryLabelColor),
			ThemeCSSRecord(selectors: [.accessory, .accept],		property: .stroke, value: UIColor.systemGreen),
			ThemeCSSRecord(selectors: [.accessory, .decline],		property: .stroke, value: UIColor.systemRed),
			ThemeCSSRecord(selectors: [.accessory, .action],		property: .stroke, value: lightBrandColor),

			// - Segment View
			ThemeCSSRecord(selectors: [.segments], 				property: .fill,   value: UIColor.clear),
			ThemeCSSRecord(selectors: [.segments, .icon], 			property: .stroke, value: cellSet.iconColor),
			ThemeCSSRecord(selectors: [.segments, .title],			property: .stroke, value: cellSet.secondaryLabelColor),

			ThemeCSSRecord(selectors: [.segments, .token],			property: .fill,   value: tokenBackgroundColor),
			ThemeCSSRecord(selectors: [.segments, .token, .icon],		property: .stroke, value: tokenForegroundColor),
			ThemeCSSRecord(selectors: [.segments, .token, .title],		property: .stroke, value: tokenForegroundColor),

			ThemeCSSRecord(selectors: [.segments, .item, .separator],	property: .fill,   value: nil),
			ThemeCSSRecord(selectors: [.segments, .item, .separator],	property: .stroke, value: cellSet.secondaryLabelColor),

			// - Messages
			ThemeCSSRecord(selectors: [.infoBox, .background],		property: .fill, value: UIColor.clear),
			ThemeCSSRecord(selectors: [.infoBox, .icon],			property: .fill, value: secondaryLabelColor),
			ThemeCSSRecord(selectors: [.infoBox, .subtitle],		property: .fill, value: secondaryLabelColor),

			ThemeCSSRecord(selectors: [.title],	property: .stroke, value: HCColor.Content.gray2(isDark)),
			ThemeCSSRecord(selectors: [.subtitle], property: .stroke, value: HCColor.Content.gray2(isDark)),
			ThemeCSSRecord(selectors: [.message], property: .stroke, value: HCColor.Content.gray2(isDark)),

			ThemeCSSRecord(selectors: [.primary],				property: .stroke, value: primaryLabelColor),
			ThemeCSSRecord(selectors: [.secondary],				property: .stroke, value: secondaryLabelColor),
			ThemeCSSRecord(selectors: [.tertiary],				property: .stroke, value: tertiaryLabelColor),

			// - Saved Search
			ThemeCSSRecord(selectors: [.savedSearch],			property: .fill, value: groupedCollectionBackgroundColor),
			ThemeCSSRecord(selectors: [.savedSearch, .cell],		property: .fill, value: groupedCollectionBackgroundColor),

			// - Fills
			ThemeCSSRecord(selectors: [.primary],				property: .fill, value: primaryBackgroundColor),
			ThemeCSSRecord(selectors: [.secondary],				property: .fill, value: secondaryBackgroundColor),
			ThemeCSSRecord(selectors: [.tertiary],				property: .fill, value: tertiaryBackgroundColor),

			// - Text Field
			ThemeCSSRecord(selectors: [.textField],				property: .fill,   value: HCColor.Structure
				.appBackground(isDark)), // Background color
			ThemeCSSRecord(selectors: [.textField],				property: .stroke, value: HCColor.Content.textSecondary(isDark)), // Tint/caret color for generic text fields
			ThemeCSSRecord(selectors: [.textField, .label],			property: .stroke, value: HCColor.Content.textPrimary(isDark)),
			ThemeCSSRecord(selectors: [.textField, .disabled, .label],	property: .stroke, value: cellSet.secondaryLabelColor), // Disabled text color
			ThemeCSSRecord(selectors: [.textField, .placeholder],		property: .stroke, value: placeholderTextColor), // Text field placeholder
			ThemeCSSRecord(selectors: [.textField, .secondary],		property: .stroke, value: HCColor.Content.textSecondary(isDark)), // Text field placeholder

			// - Search Field
			ThemeCSSRecord(selectors: [.textField, .searchField],			property: .stroke, value: lightBrandColor), // Search tint color (UI elements other than text)
			ThemeCSSRecord(selectors: [.textField, .searchField, .label],		property: .stroke, value: primaryLabelColor), // Search text color

			// - Slider
			ThemeCSSRecord(selectors: [.slider], 				property: .stroke, value: lightBrandColor),

			// - Buttons + Popups
			ThemeCSSRecord(selectors: [.button],				property: .stroke, value: lightBrandColor),
			ThemeCSSRecord(selectors: [.popupButton],			property: .stroke, value: lightBrandColor),

			// - Label styles
			ThemeCSSRecord(selectors: [.label, .destructive],		property: .stroke, value: UIColor.red),
			ThemeCSSRecord(selectors: [.label, .warning],			property: .stroke, value: UIColor(hex: 0xF2994A)),
			ThemeCSSRecord(selectors: [.label, .error],			property: .stroke, value: UIColor(hex: 0xEB5757)),
			ThemeCSSRecord(selectors: [.label, .success],			property: .stroke, value: UIColor(hex: 0x27AE60)),

			// - Confidential
			ThemeCSSRecord(selectors: [.confidentialLabel],		property: .stroke, value: tintColor.withAlphaComponent(0.8)),
			ThemeCSSRecord(selectors: [.confidentialSecondaryLabel],		property: .stroke, value: tintColor.withAlphaComponent(0.4)),

			// # Personal Cloud Files

			ThemeCSSRecord(selectors: [.primaryText], property: .fill, value: HCColor.Content.textPrimary(isDark)),

			// ## Location popover
			ThemeCSSRecord(selectors: [.locationDropDown], property: .fill, value: HCColor.Structure.whiteBackground(isDark)),

			// ## Text
			ThemeCSSRecord(selectors: [.text], property: .fill, value: HCColor.Content.textPrimary(isDark)),
			ThemeCSSRecord(selectors: [.secondaryText], property: .fill, value: HCColor.Content.gray2(isDark)),

			// ## Separator
			ThemeCSSRecord(selectors: [.separator], property: .fill, value: HCColor.Content.border2(isDark)),

			// ## Sidebar			
			ThemeCSSRecord(selectors: [.sidebar, .background], property: .fill, value: HCColor.Structure.menuBackground(isDark)),
			ThemeCSSRecord(selectors: [.sidebar, .border], property: .fill, value: HCColor.Content.border2(isDark)),
			ThemeCSSRecord(selectors: [.sidebar, .header, .accessory], property: .fill, value: HCColor.Content.iconBackground(isDark)),
			ThemeCSSRecord(selectors: [.sidebar, .header, .accessory], property: .stroke, value: HCColor.Interaction.primarySolidNormal(isDark)),

			// ## HCErrorView
			ThemeCSSRecord(selectors: [.hcErrorView, .background], property: .fill, value: HCColor.Symbolic.errorBackgroundTransparent(isDark)),
			ThemeCSSRecord(selectors: [.hcErrorView, .text], property: .fill, value: HCColor.Content.textPrimary(isDark)),
			ThemeCSSRecord(selectors: [.hcErrorView, .error], property: .fill, value: HCColor.Symbolic.error(isDark)),

			// # HCCardView
			ThemeCSSRecord(selectors: [.hcCardView, .background], property: .fill, value: HCColor.Structure.cardBackground(isDark)),

			// # HCOverlayView
			ThemeCSSRecord(selectors: [.hcOverlayView, .background], property: .fill, value: HCColor.Mockups.overlayDefault(isDark)),

			// # HCDigitView
			ThemeCSSRecord(selectors: [.hcDigitBox, .focused], property: .stroke, value: HCColor.Interaction.primarySolidNormal(isDark)),
			ThemeCSSRecord(selectors: [.hcDigitBox, .plain], property: .stroke, value: HCColor.Content.border(isDark)),
			ThemeCSSRecord(selectors: [.hcDigitBox, .error], property: .stroke, value: HCColor.Symbolic.error(isDark)),

			// ## Spinner
			ThemeCSSRecord(selectors: [.spinner], property: .stroke, value: HCColor.Interaction.primarySolidNormal(isDark)),
			ThemeCSSRecord(selectors: [.spinner], property: .fill, value: HCColor.Content.sliderBackground(isDark)),

			// ## Auth
			ThemeCSSRecord(selectors: [.auth, .background], property: .fill, value: HCColor.Structure.cardBackground(isDark)),
			ThemeCSSRecord(selectors: [.label, .auth], property: .stroke, value: HCColor.Content.textPrimary(isDark)),

			// ## App logo
			ThemeCSSRecord(selectors: [.hcAppLogo, .part1Color], property: .stroke, value: HCColor.Constant.primary(isDark)),
			ThemeCSSRecord(selectors: [.hcAppLogo, .part2Color], property: .stroke, value: HCColor.Content.textPrimary(isDark)),

			// ## HCField
			ThemeCSSRecord(selectors: [.hcField], property: .stroke, value: HCColor.Content.border(isDark)),
			ThemeCSSRecord(selectors: [.hcField, .selected], property: .stroke, value: isDark ? HCColor.Blue.lighten2 : HCColor.Blue.darken2),
			ThemeCSSRecord(selectors: [.hcField, .error], property: .stroke, value: HCColor.Symbolic.error(isDark)),
			ThemeCSSRecord(selectors: [.hcField], property: .borderWidth, value: CGFloat(1)),
			ThemeCSSRecord(selectors: [.hcField, .selected], property: .borderWidth, value: CGFloat(3)),
			ThemeCSSRecord(selectors: [.hcField, .text], property: .stroke, value: HCColor.Content.labels(isDark)),

			// ## HCTextField
			ThemeCSSRecord(selectors: [.hcTextField, .placeholder], property: .stroke, value: HCColor.Content.gray3),
			ThemeCSSRecord(selectors: [.hcTextField, .text], property: .stroke, value: HCColor.Content.textPrimary(isDark)),

			// ## HCDropdownView

			ThemeCSSRecord(selectors: [.hcDropdownView], property: .fill, value: HCColor.Interaction.primaryTransparentNormal20(isDark)),
			ThemeCSSRecord(selectors: [.hcDropdownView], property: .stroke, value: HCColor.Content.textPrimary(isDark)),

			// ## Sort bar
			ThemeCSSRecord(selectors: [.sortBar], property: .stroke, value: HCColor.Content.textPrimary(isDark)),
			ThemeCSSRecord(selectors: [.sortBar, .sorting], property: .stroke, value: HCColor.Content.textPrimary(isDark)),
			ThemeCSSRecord(selectors: [.sortBar, .multiselect], property: .stroke, value: HCColor.Content.textPrimary(isDark)),
			ThemeCSSRecord(selectors: [.sortBar, .itemLayout], property: .stroke, value: HCColor.Content.textPrimary(isDark)),
			ThemeCSSRecord(selectors: [.sortBar], property: .fill, value: HCColor.Structure.menuBackground(isDark)),

			// ## Login navbar
			ThemeCSSRecord(selectors: [ThemeCSSSelector(rawValue: "loginNavbar")], property: .stroke, value: HCColor.Interaction.primarySolidNormal(isDark)),

			// ## Button
			ThemeCSSRecord(selectors: [.button], property: .borderColor, value: UIColor.clear),
			ThemeCSSRecord(selectors: [.button], property: .cornerRadius, value: CGFloat(1.0)),

			// ### Tab bar
			ThemeCSSRecord(selectors: [.tabBar], property: .fill, value: HCColor.Structure.menuBackground(isDark)),
			ThemeCSSRecord(selectors: [.tabBar, .button, .help], property: .fill, value: HCColor.Interaction.primaryTransparentNormal20(isDark)),
			ThemeCSSRecord(selectors: [.tabBar, .button, .help], property: .stroke, value: HCColor.Interaction.primarySolidNormal(isDark)),
			ThemeCSSRecord(selectors: [.tabBar, .button], property: .stroke, value: HCColor.Content.textPrimary(isDark)),

			// ### Plain
			// #### Primary
			ThemeCSSRecord(selectors: [.button, .primary, .plain], property: .stroke, value: isDark ? HCColor.Blue.lighten2 : HCColor.Blue.darken2),
			ThemeCSSRecord(selectors: [.button, .primary, .plain], property: .fill, value: UIColor.clear),
			ThemeCSSRecord(selectors: [.button, .primary, .plain, .disabled], property: .stroke, value: HCColor.Grey.grey),
			ThemeCSSRecord(selectors: [.button, .primary, .plain, .disabled], property: .fill, value: UIColor.clear),
			ThemeCSSRecord(selectors: [.button, .primary, .plain, .highlighted], property: .stroke, value: isDark ? HCColor.Blue.lighten3 : HCColor.Blue.darken1),
			ThemeCSSRecord(selectors: [.button, .primary, .plain, .highlighted], property: .fill, value: isDark ? HCColor.Transparencies.blueLighten3_12 : HCColor.Transparencies.blueDarken1_12),

			// #### Secondary
			ThemeCSSRecord(selectors: [.button, .secondary, .plain], property: .stroke, value: isDark ? HCColor.white : HCColor.Grey.darken4),
			ThemeCSSRecord(selectors: [.button, .secondary, .plain], property: .fill, value: UIColor.clear),
			ThemeCSSRecord(selectors: [.button, .secondary, .plain, .disabled], property: .stroke, value: HCColor.Grey.grey),
			ThemeCSSRecord(selectors: [.button, .secondary, .plain, .disabled], property: .fill, value: UIColor.clear),
			ThemeCSSRecord(selectors: [.button, .secondary, .plain, .highlighted], property: .stroke, value: isDark ? HCColor.Grey.lighten3 : HCColor.Grey.darken3),
			ThemeCSSRecord(selectors: [.button, .secondary, .plain, .highlighted], property: .fill, value: isDark ? HCColor.Transparencies.white_12 : HCColor.Transparencies.greyDarken3_12),

			// ### Filled
			// #### Primary
			ThemeCSSRecord(selectors: [.button, .primary, .filled], property: .stroke, value: HCColor.Interaction.secondaryLabel(isDark)),
			ThemeCSSRecord(selectors: [.button, .primary, .filled], property: .fill, value: isDark ? HCColor.Blue.lighten2 : HCColor.Blue.darken2),
			ThemeCSSRecord(selectors: [.button, .primary, .filled, .disabled], property: .stroke, value: HCColor.Grey.grey),
			ThemeCSSRecord(selectors: [.button, .primary, .filled, .disabled], property: .fill, value: HCColor.Content.disabledBackground(isDark)),
			ThemeCSSRecord(selectors: [.button, .primary, .filled, .highlighted], property: .stroke, value: isDark ? HCColor.Text.lightModePrimary : HCColor.Text.darkModePrimary),
			ThemeCSSRecord(selectors: [.button, .primary, .filled, .highlighted], property: .fill, value:  isDark ? HCColor.Blue.lighten3 : HCColor.Blue.darken1),

			// #### Secondary
			ThemeCSSRecord(selectors: [.button, .secondary, .filled], property: .stroke, value: isDark ? HCColor.Text.lightModePrimary : HCColor.Text.darkModePrimary),
			ThemeCSSRecord(selectors: [.button, .secondary, .filled], property: .fill, value: isDark ? HCColor.white : HCColor.Grey.darken4),
			ThemeCSSRecord(selectors: [.button, .secondary, .filled, .disabled], property: .stroke, value: HCColor.Grey.grey),
			ThemeCSSRecord(selectors: [.button, .secondary, .filled, .disabled], property: .fill, value: HCColor.Content.disabledBackground(isDark)),
			ThemeCSSRecord(selectors: [.button, .secondary, .filled, .highlighted], property: .stroke, value: isDark ? HCColor.Text.lightModePrimary : HCColor.Text.darkModePrimary),
			ThemeCSSRecord(selectors: [.button, .secondary, .filled, .highlighted], property: .fill, value:  isDark ? HCColor.Grey.lighten3 : HCColor.Grey.darken3),

			// #### Auth
			ThemeCSSRecord(selectors: [.button, .primary_auth, .filled], property: .stroke, value: HCColor.Text.secondary(isDark)),
			ThemeCSSRecord(selectors: [.button, .primary_auth, .filled], property: .fill, value: HCColor.Interaction.primaryTransparentNormal20(isDark)),
			ThemeCSSRecord(selectors: [.button, .primary_auth, .filled, .disabled], property: .stroke, value: HCColor.Grey.grey),
			ThemeCSSRecord(selectors: [.button, .primary_auth, .filled, .disabled], property: .fill, value: HCColor.Content.disabledBackground(isDark)),
			ThemeCSSRecord(selectors: [.button, .primary_auth, .filled, .highlighted], property: .stroke, value: isDark ? HCColor.Text.lightModePrimary : HCColor.Text.darkModePrimary),
			ThemeCSSRecord(selectors: [.button, .primary_auth, .filled, .highlighted], property: .fill, value:  isDark ? HCColor.Grey.lighten3 : HCColor.Grey.darken3),
			ThemeCSSRecord(selectors: [.button, .primary_auth, .filled], property: .fontSize, value: CGFloat(34)),
			ThemeCSSRecord(selectors: [.primary_auth, .error], property: .stroke, value: HCColor.Symbolic.error(isDark)),

			// ### Outlined
			// #### Primary
			ThemeCSSRecord(selectors: [.button, .primary, .outlined], property: .borderColor, value: isDark ? HCColor.Blue.lighten2 : HCColor.Blue.darken2),
			ThemeCSSRecord(selectors: [.button, .primary, .outlined], property: .stroke, value: isDark ? HCColor.Blue.lighten2 : HCColor.Blue.darken2),
			ThemeCSSRecord(selectors: [.button, .primary, .outlined], property: .fill, value: UIColor.clear),
			ThemeCSSRecord(selectors: [.button, .primary, .outlined, .disabled], property: .borderColor, value: HCColor.Grey.grey),
			ThemeCSSRecord(selectors: [.button, .primary, .outlined, .disabled], property: .stroke, value: HCColor.Grey.grey),
			ThemeCSSRecord(selectors: [.button, .primary, .outlined, .disabled], property: .fill, value: UIColor.clear),
			ThemeCSSRecord(selectors: [.button, .primary, .outlined, .highlighted], property: .borderColor, value: isDark ? HCColor.Blue.lighten3 : HCColor.Blue.darken1),
			ThemeCSSRecord(selectors: [.button, .primary, .outlined, .highlighted], property: .stroke, value: isDark ? HCColor.Blue.lighten3 : HCColor.Blue.darken1),
			ThemeCSSRecord(selectors: [.button, .primary, .outlined, .highlighted], property: .fill, value:  isDark ? HCColor.Transparencies.blueLighten3_12 : HCColor.Transparencies.blueDarken1_12),

			// #### Secondary
			ThemeCSSRecord(selectors: [.button, .secondary, .outlined], property: .borderColor, value: isDark ? HCColor.white : HCColor.Grey.darken4),
			ThemeCSSRecord(selectors: [.button, .secondary, .outlined], property: .stroke, value: isDark ? HCColor.white : HCColor.Grey.darken4),
			ThemeCSSRecord(selectors: [.button, .secondary, .outlined], property: .fill, value: UIColor.clear),
			ThemeCSSRecord(selectors: [.button, .secondary, .outlined, .disabled], property: .borderColor, value: HCColor.Grey.grey),
			ThemeCSSRecord(selectors: [.button, .secondary, .outlined, .disabled], property: .stroke, value: HCColor.Grey.grey),
			ThemeCSSRecord(selectors: [.button, .secondary, .outlined, .disabled], property: .fill, value: UIColor.clear),
			ThemeCSSRecord(selectors: [.button, .secondary, .outlined, .highlighted], property: .borderColor, value: isDark ? HCColor.Grey.lighten3 : HCColor.Grey.darken3),
			ThemeCSSRecord(selectors: [.button, .secondary, .outlined, .highlighted], property: .stroke, value: isDark ? HCColor.Grey.lighten3 : HCColor.Grey.darken3),
			ThemeCSSRecord(selectors: [.button, .secondary, .outlined, .highlighted], property: .fill, value:  isDark ? HCColor.Transparencies.white_12 : HCColor.Transparencies.greyDarken3_12),
		])

		// - Fill styles
		css.add(records: ThemeCollection.generateColorPairs(with: [.destructive], foregroundColor: .white, backgroundColor: .red))
		css.add(records: ThemeCollection.generateColorPairs(with: [.confirm], 	  foregroundColor: .white, backgroundColor: UIColor(hex: 0x1AC763)))
		css.add(records: ThemeCollection.generateColorPairs(with: [.cancel], 	  foregroundColor: .white, backgroundColor: lightBrandColor))
		css.add(records: ThemeCollection.generateColorPairs(with: [.proceed], 	  foregroundColor: .white, backgroundColor: lightBrandColor))
		css.add(records: ThemeCollection.generateColorPairs(with: [.info], 	  foregroundColor: .white, backgroundColor: lightBrandColor))
		css.add(records: ThemeCollection.generateColorPairs(with: [.warning], 	  foregroundColor: .black, backgroundColor: .systemYellow))

		css.add(records: ThemeCollection.generateColorPairs(with: [.purchase], 	  from: purchaseColors))

		// - Pass code fill style
		css.add(records: ThemeCollection.generateColorPairs(with: [.digit], 	  from: neutralColors))

		css.add(records: [
			ThemeCSSRecord(selectors: [.passcode],				property: .fill,   value: collectionBackgroundColor),
			ThemeCSSRecord(selectors: [.passcode, .title],			property: .stroke, value: primaryLabelColor),
			ThemeCSSRecord(selectors: [.passcode, .disabled, .title],	property: .stroke, value: secondaryLabelColor),
			ThemeCSSRecord(selectors: [.passcode, .code],			property: .stroke, value: neutralColors.normal.background),
			ThemeCSSRecord(selectors: [.passcode, .disabled, .code],	property: .stroke, value: primaryLabelColor),
			ThemeCSSRecord(selectors: [.passcode, .subtitle],		property: .stroke, value: secondaryLabelColor),
			ThemeCSSRecord(selectors: [.passcode, .disabled, .subtitle],	property: .stroke, value: tertiaryLabelColor),

			// - Alert View Controller
			ThemeCSSRecord(selectors: [.alert],				property: .stroke, value: tintColor),

			// - Action / Drop target (plain) fill style
			ThemeCSSRecord(selectors: [.action],				property: .fill, value: inlineActionBackgroundColor),
			ThemeCSSRecord(selectors: [.action, .highlighted],		property: .fill, value: inlineActionBackgroundColorHighlighted),

			// - Drive Header
			ThemeCSSRecord(selectors: [.header, .drive, .cover],		property: .fill,   value: UIColor.systemGray),
			ThemeCSSRecord(selectors: [.header, .drive, .focused, .cover],	property: .fill,   value: tintColor),

			ThemeCSSRecord(selectors: [.header, .drive, .semicover],	property: .fill,   value: UIColor(red: 0, green: 0, blue: 0, alpha: 0.4)),
			ThemeCSSRecord(selectors: [.header, .drive, .focused, .semicover],property: .fill, value: tintColor),

			// - Expandable Resource Cell
			ThemeCSSRecord(selectors: [.expandable],			property: .fill,   value: collectionBackgroundColor),
			ThemeCSSRecord(selectors: [.expandable, .button],		property: .stroke, value: tintColor),
			ThemeCSSRecord(selectors: [.expandable, .textView],		property: .fill,   value: collectionBackgroundColor),
			ThemeCSSRecord(selectors: [.expandable, .textView],		property: .stroke, value: secondaryLabelColor),
			ThemeCSSRecord(selectors: [.expandable, .shadow],		property: .fill,   value: cellSet.labelColor),

			// - Location Bar
			ThemeCSSRecord(selectors: [.locationBar],			property: .fill, value: cellSet.backgroundColor),

			// - Keyboard
			ThemeCSSRecord(selectors: [.all],				property: .keyboardAppearance, value: keyboardAppearance),

			// - Account Cell
			ThemeCSSRecord(selectors: [.account],				property: .fill,   value: accountCellSet.backgroundColor),
			ThemeCSSRecord(selectors: [.account, .title],			property: .stroke, value: accountCellSet.labelColor),
			ThemeCSSRecord(selectors: [.account, .description],		property: .stroke, value: accountCellSet.secondaryLabelColor),
			ThemeCSSRecord(selectors: [.account, .disconnect],		property: .stroke, value: accountCellSet.tintColor),
			ThemeCSSRecord(selectors: [.account, .disconnect],		property: .fill,   value: accountCellSet.labelColor),

			// - Location Picker
			ThemeCSSRecord(selectors: [.locationPicker, .collection, .accountList], 		property: .fill, value: groupedCollectionBackgroundColor),
			ThemeCSSRecord(selectors: [.locationPicker, .collection, .accountList, .cell], 		property: .fill, value: accountCellSet.backgroundColor),
			ThemeCSSRecord(selectors: [.locationPicker, .navigationBar], 				property: .fill, value: groupedCollectionBackgroundColor),

			// - More card header
			ThemeCSSRecord(selectors: [.more, .header], 					property: .fill,   value: moreHeaderBackgroundColor),
			ThemeCSSRecord(selectors: [.more, .collection], 				property: .fill,   value: groupedCellStateSet),
			ThemeCSSRecord(selectors: [.more, .insetGrouped, .table, .cell, .proceed],	property: .stroke, value: UIColor.white),

			ThemeCSSRecord(selectors: [.more, .favorite],			property: .stroke, value: favoriteEnabledColor),
			ThemeCSSRecord(selectors: [.more, .favorite, .disabled],	property: .stroke, value: favoriteDisabledColor),

			// - TVG icon colors
			// ThemeCSSRecord(selectors: [.vectorImage, .folderColor], 	property: .fill, value: iconSymbolColor), // make TVG files use default colors extracted from original SVG files
			// ThemeCSSRecord(selectors: [.vectorImage, .fileColor], 	property: .fill, value: iconSymbolColor), // make TVG files use default colors extracted from original SVG files
			ThemeCSSRecord(selectors: [.vectorImage, .logoColor], 		property: .fill, value: logoFillColor ?? UIColor.white),
			ThemeCSSRecord(selectors: [.vectorImage, .iconColor], 		property: .fill, value: iconSymbolColor),
			ThemeCSSRecord(selectors: [.vectorImage, .symbolColor], 	property: .fill, value: iconSymbolColor),

			// Welcome screen
			ThemeCSSRecord(selectors: [.welcome, .message, .background], property: .fill,   value: UIColor(red: 0, green: 0, blue: 0, alpha: 0.2)),
//			ThemeCSSRecord(selectors: [.welcome, .message, .title],      property: .stroke, value: darkBrandSet.labelColor),
//			ThemeCSSRecord(selectors: [.welcome, .message, .button],     property: .stroke, value: darkBrandSet.labelColor),
			ThemeCSSRecord(selectors: [.welcome, .message, .title],      property: .stroke, value: UIColor.white),
			ThemeCSSRecord(selectors: [.welcome, .message, .button],     property: .stroke, value: UIColor.white),
			ThemeCSSRecord(selectors: [.welcome, .message, .button],     property: .fill,   value: darkBrandColor),
			ThemeCSSRecord(selectors: [.welcome],			     property: .statusBarStyle, value: UIStatusBarStyle.lightContent),

			// Account Setup
			ThemeCSSRecord(selectors: [.accountSetup, .message, .title],		property: .stroke, value: UIColor.white),
			ThemeCSSRecord(selectors: [.accountSetup, .header,  .title],		property: .stroke, value: UIColor.white),
			ThemeCSSRecord(selectors: [.accountSetup, .welcome, .icon], 		property: .fill,   value: darkBrandColor),
			ThemeCSSRecord(selectors: [.accountSetup, .step, .title], 		property: .stroke, value: primaryLabelColor),
			ThemeCSSRecord(selectors: [.accountSetup, .step, .message], 		property: .stroke, value: secondaryLabelColor),
			ThemeCSSRecord(selectors: [.accountSetup, .step, .background],		property: .fill,   value: collectionBackgroundColor),

			ThemeCSSRecord(selectors: [.accountSetup, .help, .subtitle], 		property: .stroke, value: UIColor.lightGray),
			ThemeCSSRecord(selectors: [.accountSetup],				property: .fill,   value: darkBrandColor),
			ThemeCSSRecord(selectors: [.accountSetup],      			property: .statusBarStyle, value: UIStatusBarStyle.lightContent),

			ThemeCSSRecord(selectors: [.certificateSummary],			property: .fill,   value: UIColor.clear),

			// Side Bar
			// - Interface Style
			ThemeCSSRecord(selectors: [.sidebar], 			   	property: .style, value: UIUserInterfaceStyle.light),

			// - Status Bar
			ThemeCSSRecord(selectors: [.sidebar], 			   	property: .statusBarStyle, value: statusBarStyle),

			// - Collection View
			ThemeCSSRecord(selectors: [.sidebar, .collection, .cell],  	property: .fill,   value: HCColor.Structure.appBackground(isDark)),
			ThemeCSSRecord(selectors: [.sidebar, .collection],  	   	property: .fill,   value: HCColor.Structure.appBackground(isDark)),
			ThemeCSSRecord(selectors: [.sidebar, .collection, .cell], 	property: .stroke, value: sidebarCellStateSet.regular.labelColor),
			ThemeCSSRecord(selectors: [.sidebar, .collection, .cell, .highlighted], property: .stroke, value: HCColor.Interaction.secondaryLabel(isDark)),
			ThemeCSSRecord(selectors: [.sidebar, .collection, .cell, .selected], property: .stroke, value: HCColor.Interaction.secondaryLabel(isDark)),
			// ThemeCSSRecord(selectors: [.sidebar, .collection, .label], 	property: .stroke, value: sidebarCellStateSet.regular.labelColor),
			// ThemeCSSRecord(selectors: [.sidebar, .collection, .icon],  	property: .stroke, value: sidebarCellStateSet.regular.labelColor),

			ThemeCSSRecord(selectors: [.sidebar, .collection, .selected, .cell],  property: .stroke, value: sidebarCellStateSet.selected.labelColor),
			ThemeCSSRecord(selectors: [.sidebar, .collection, .selected, .cell],  property: .fill, value: sidebarCellStateSet.selected.backgroundColor),

			// - Warning
			ThemeCSSRecord(selectors: [.sidebar, .warning, .icon], 		property: .stroke, value: UIColor.black), // "Access denied" sidebar icon

			// - Account Cell
			ThemeCSSRecord(selectors: [.sidebar, .account],			property: .fill,   value: sidebarAccountCellSet.backgroundColor),
			ThemeCSSRecord(selectors: [.sidebar, .account, .title],		property: .stroke, value: sidebarAccountCellSet.labelColor),
			ThemeCSSRecord(selectors: [.sidebar, .account, .description],	property: .stroke, value: sidebarAccountCellSet.secondaryLabelColor),
			ThemeCSSRecord(selectors: [.sidebar, .account, .disconnect],	property: .stroke, value: sidebarAccountCellSet.tintColor),
			ThemeCSSRecord(selectors: [.sidebar, .account, .disconnect],	property: .fill,   value: sidebarAccountCellSet.labelColor),

			// - Navigation Bar
			ThemeCSSRecord(selectors: [.sidebar, .navigationBar],		property: .stroke, value: HCColor.Interaction.primarySolidNormal(isDark)),
			ThemeCSSRecord(selectors: [.sidebar, .navigationBar],		property: .fill,   value: nil),
			ThemeCSSRecord(selectors: [.sidebar, .navigationBar, .logo],	property: .stroke, value: HCColor.Content.textPrimary(isDark)),
			ThemeCSSRecord(selectors: [.sidebar, .navigationBar, .logo, .label],property: .stroke, value: HCColor.Content.textPrimary(isDark)),

			// - Toolbar
			ThemeCSSRecord(selectors: [.sidebar, .toolbar], property: .fill, value: HCColor.Structure.menuBackground(isDark)),
			ThemeCSSRecord(selectors: [.sidebar, .toolbar],			property: .stroke, value: lightBrandColor),

			// Content Area
			ThemeCSSRecord(selectors: [.content],				property: .fill,   value: collectionBackgroundColor),

			// - Navigation Bar
			ThemeCSSRecord(selectors: [.content, .navigationBar], property: .fill, value: HCColor.Structure.menuBackground(isDark)),
			ThemeCSSRecord(selectors: [.content, .navigationBar],			property: .stroke, value: HCColor.Interaction.primarySolidNormal(isDark)),
			ThemeCSSRecord(selectors: [.content, .navigationBar, .label, .title],	property: .stroke, value: HCColor.Content.textPrimary(isDark)),

			// - Toolbar
			ThemeCSSRecord(selectors: [.content, .toolbar],				property: .stroke, value: contentToolbarSet.tintColor),
			ThemeCSSRecord(selectors: [.content, .toolbar],				property: .fill,   value: HCColor.Structure.menuBackground(isDark)),

			// - Location Bar
			ThemeCSSRecord(selectors: [.content, .toolbar, .locationBar, .segments, .item, .plain],		property: .stroke, value: HCColor.Content.textPrimary(isDark)),
			ThemeCSSRecord(selectors: [.content, .toolbar, .locationBar, .button],	property: .stroke, value: HCColor.Content.textPrimary(isDark)),
			ThemeCSSRecord(selectors: [.content, .toolbar, .locationBar],					property: .fill,   value: UIColor.clear),

			// # Standalone colors
			ThemeCSSRecord(selectors: [.hcColorMenuBackground], property: .fill, value: HCColor.Structure.menuBackground(isDark)),
			ThemeCSSRecord(selectors: [.hcColorCardBackground], property: .fill, value: HCColor.Structure.cardBackground(isDark))
		])

		// System colors
		css.addSystemColors()

		// Theme colors
		css.add(color: lightBrandColor, address: "theme.color.light")
		css.add(color: darkBrandColor, 	address: "theme.color.dark")
	}

	convenience override init() {
		self.init(darkBrandColor: UIColor(hex: 0x1D293B), lightBrandColor: UIColor(hex: 0x468CC8))
	}

	// MARK: - Icon colors
	var _iconColors: [String:String]?
	public var iconColors: [String:String] {
		if _iconColors == nil {
			_iconColors = [:]

			_iconColors?["folderFillColor"] = css.getColor(.fill, selectors: [.vectorImage, .folderColor], for: nil)?.hexString()

			_iconColors?["fileFillColor"] = css.getColor(.fill, selectors: [.vectorImage, .fileColor], for: nil)?.hexString()
			_iconColors?["documentFileFillColor"] = css.getColor(.fill, selectors: [.vectorImage, .documentFileColor], for: nil)?.hexString()
			_iconColors?["presentationFileFillColor"] = css.getColor(.fill, selectors: [.vectorImage, .presentationFileColor], for: nil)?.hexString()
			_iconColors?["spreadsheetFileFillColor"] = css.getColor(.fill, selectors: [.vectorImage, .spreadsheetFileColor], for: nil)?.hexString()
			_iconColors?["pdfFileFillColor"] = css.getColor(.fill, selectors: [.vectorImage, .pdfFileColor], for: nil)?.hexString()

			_iconColors?["logoFillColor"] = css.getColor(.fill, selectors: [.vectorImage, .logoColor], for: nil)?.hexString()
			_iconColors?["iconFillColor"] = css.getColor(.fill, selectors: [.vectorImage, .iconColor], for: nil)?.hexString()
			_iconColors?["symbolFillColor"] = css.getColor(.fill, selectors: [.vectorImage, .symbolColor], for: nil)?.hexString()
		}

		return _iconColors ?? [:]
	}
}

extension ThemeCSSSelector {
	static let folderColor = ThemeCSSSelector(rawValue: "folderColor")
	static let fileColor = ThemeCSSSelector(rawValue: "fileColor")
	static let documentFileColor = ThemeCSSSelector(rawValue: "documentFileColor")
	static let presentationFileColor = ThemeCSSSelector(rawValue: "presentationFileColor")
	static let spreadsheetFileColor = ThemeCSSSelector(rawValue: "spreadsheetFileColor")
	static let pdfFileColor = ThemeCSSSelector(rawValue: "pdfFileColor")
	static let logoColor = ThemeCSSSelector(rawValue: "logoColor")
	static let iconColor = ThemeCSSSelector(rawValue: "iconColor")
	static let symbolColor = ThemeCSSSelector(rawValue: "symbolColor")
}

extension ThemeCollection {
	func navigationBarAppearance(navigationBar: UINavigationBar, scrollEdge: Bool = false) -> UINavigationBarAppearance {
		let appearance = UINavigationBarAppearance()

		appearance.configureWithOpaqueBackground()

		if let labelColor = css.getColor(.stroke, selectors: [.label], for: navigationBar) {
			appearance.titleTextAttributes = [ .foregroundColor : labelColor  ]
			appearance.largeTitleTextAttributes = [ .foregroundColor : labelColor  ]
		}

		appearance.backgroundColor = css.getColor(.fill, for: navigationBar)		
		appearance.shadowColor = .clear

		return appearance
	}
}
