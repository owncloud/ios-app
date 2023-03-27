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

public class ThemeColorPair : NSObject {
	@objc public var foreground: UIColor
	@objc public var background: UIColor

	public init(foreground fgColor: UIColor, background bgColor: UIColor) {
		foreground = fgColor
		background = bgColor
	}
}

public class ThemeColorPairCollection : NSObject {
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

public class ThemeColorCollection : NSObject {
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
	case contrast

	public var name : String {
		switch self {
			case .dark:	return "Dark".localized
			case .light:	return "Light".localized
			case .contrast:	return "Contrast".localized
		}
	}
}

public enum ThemeCollectionInterfaceStyle : String, CaseIterable {
	case dark
	case light
	case unspecified

	public var userInterfaceStyle : UIUserInterfaceStyle {
		switch self {
			case .dark: return .dark
			case .light: return .light
			case .unspecified: return .unspecified
		}
	}
}

public class ThemeCollection : NSObject {
	@objc var identifier : String = UUID().uuidString

	// MARK: - Interface style
	public var interfaceStyle : ThemeCollectionInterfaceStyle
	private var keyboardAppearance : UIKeyboardAppearance
	public var backgroundBlurEffectStyle : UIBlurEffect.Style

	// MARK: - ThemeCSS
	public var css: ThemeCSS

	// MARK: - Brand colors
	@objc private var darkBrandColor: UIColor
	@objc private var lightBrandColor: UIColor

	// MARK: - Brand color collection
	@objc private var darkBrandColors : ThemeColorCollection
	@objc private var lightBrandColors : ThemeColorCollection

	// MARK: - Button / Fill color collections
	@objc private var approvalColors : ThemeColorPairCollection
	@objc private var neutralColors : ThemeColorPairCollection
	@objc private var destructiveColors : ThemeColorPairCollection
	@objc private var warningColors : ThemeColorPairCollection

	@objc private var purchaseColors : ThemeColorPairCollection

	@objc private var tokenColors: ThemeColorPairCollection

	// MARK: - Label colors
	@objc private var informativeColor: UIColor
	@objc private var successColor: UIColor
	@objc private var warningColor: UIColor
	@objc private var errorColor: UIColor

	@objc private var tintColor : UIColor

	// MARK: - Table views
	@objc private var tableBackgroundColor : UIColor
	@objc private var tableGroupBackgroundColor : UIColor
	@objc private var tableSectionHeaderColor : UIColor?
	@objc private var tableSectionFooterColor : UIColor?
	@objc private var tableSeparatorColor : UIColor?
	@objc private var tableRowColors : ThemeColorCollection
	@objc private var tableRowHighlightColors : ThemeColorCollection
	@objc private var tableRowButtonColors : ThemeColorCollection
	@objc private var tableRowBorderColor : UIColor?

	// MARK: - Bars
	@objc private var navigationBarColors : ThemeColorCollection
	@objc private var toolbarColors : ThemeColorCollection
	@objc private var statusBarStyle : UIStatusBarStyle
	@objc private var loginStatusBarStyle : UIStatusBarStyle
	@objc private var barStyle : UIBarStyle

	// MARK: - Progress
	@objc private var progressColors : ThemeColorPair

	// MARK: - Activity View
	@objc private var activityIndicatorViewStyle : UIActivityIndicatorView.Style

	// MARK: - Login colors
	@objc private var loginColors : ThemeColorCollection
	@objc private var informalColors : ThemeColorCollection
	@objc private var cancelColors : ThemeColorCollection

	@objc private var favoriteEnabledColor : UIColor?
	@objc private var favoriteDisabledColor : UIColor?

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

	init(darkBrandColor darkColor: UIColor, lightBrandColor lightColor: UIColor, style: ThemeCollectionStyle = .dark, customColors: NSDictionary? = nil, genericColors: NSDictionary? = nil, interfaceStyles: NSDictionary? = nil) {
		var logoFillColor : UIColor?

		self.css = ThemeCSS()

		self.interfaceStyle = .unspecified
		self.keyboardAppearance = .default
		self.backgroundBlurEffectStyle = .regular

		self.darkBrandColor = darkColor
		self.lightBrandColor = lightColor

		let colors = ThemeColorValueResolver(colorValues: customColors, genericValues: genericColors, themeCollectionStyle: style)
		let styleResolver = ThemeStyleValueResolver(styleValues: interfaceStyles)

		self.darkBrandColors = colors.resolveThemeColorCollection("darkBrandColors", ThemeColorCollection(
			backgroundColor: darkColor,
			tintColor: lightColor,
			labelColor: UIColor.white,
			secondaryLabelColor: UIColor.lightGray,
			symbolColor: UIColor.white,
			filledColorPairCollection: ThemeColorPairCollection(fromPair: ThemeColorPair(foreground: UIColor.white, background: darkColor))
		))

		self.lightBrandColors = colors.resolveThemeColorCollection("lightBrandColors", ThemeColorCollection(
			backgroundColor: lightColor,
			tintColor: UIColor.white,
			labelColor: UIColor.white,
			secondaryLabelColor: UIColor.lightGray,
			symbolColor: UIColor.white,
			filledColorPairCollection: ThemeColorPairCollection(fromPair: ThemeColorPair(foreground: UIColor.white, background: lightBrandColor))
		))

		self.informativeColor = colors.resolveColor("Label.informativeColor", UIColor.darkGray)
		self.successColor = colors.resolveColor("Label.successColor", UIColor(hex: 0x27AE60))
		self.warningColor = colors.resolveColor("Label.warningColor", UIColor(hex: 0xF2994A))
		self.errorColor = colors.resolveColor("Label.errorColor", UIColor(hex: 0xEB5757))

		self.approvalColors = colors.resolveThemeColorPairCollection("Fill.approvalColors", ThemeColorPairCollection(fromPair: ThemeColorPair(foreground: UIColor.white, background: UIColor(hex: 0x1AC763))))
		self.neutralColors = colors.resolveThemeColorPairCollection("Fill.neutralColors", lightBrandColors.filledColorPairCollection)
		self.purchaseColors = ThemeColorPairCollection(fromPair: ThemeColorPair(foreground: lightBrandColors.labelColor, background: lightBrandColor))
		self.purchaseColors.disabled.background = self.purchaseColors.disabled.background.greyscale
		self.destructiveColors = colors.resolveThemeColorPairCollection("Fill.destructiveColors", ThemeColorPairCollection(fromPair: ThemeColorPair(foreground: UIColor.white, background: UIColor.red)))
		self.warningColors = colors.resolveThemeColorPairCollection("Fill.warningColors", ThemeColorPairCollection(fromPair: ThemeColorPair(foreground: UIColor.black, background: UIColor.systemYellow)))

		self.tokenColors = colors.resolveThemeColorPairCollection("Fill.tokenColors", ThemeColorPairCollection(fromPair: ThemeColorPair(foreground: lightBrandColor, background: UIColor(white: 0, alpha: 0.1))))

		self.tintColor = colors.resolveColor("tintColor", self.lightBrandColor)

		// Table view
		self.tableBackgroundColor = colors.resolveColor("Table.tableBackgroundColor", UIColor.white)

		self.tableGroupBackgroundColor = colors.resolveColor("Table.tableGroupBackgroundColor", UIColor.systemGroupedBackground.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light)))
		let color = colors.resolveColor("Table.tableSeparatorColor", UIColor.separator)
		self.tableSeparatorColor = color
		self.tableSectionHeaderColor = UIColor.gray
		self.tableSectionFooterColor = UIColor.gray

		let rowColor : UIColor? = UIColor.black.withAlphaComponent(0.1)
		self.tableRowBorderColor = colors.resolveColor("Table.tableRowBorderColor", rowColor)

		var defaultTableRowLabelColor = darkColor
		if VendorServices.shared.isBranded {
			defaultTableRowLabelColor = UIColor(hex: 0x000000)
		}

		self.tableRowColors = colors.resolveThemeColorCollection("Table.tableRowColors", ThemeColorCollection(
			backgroundColor: tableBackgroundColor,
			tintColor: nil,
			labelColor: defaultTableRowLabelColor,
			secondaryLabelColor: UIColor(hex: 0x475770),
			symbolColor: UIColor(hex: 0x475770),
			filledColorPairCollection: ThemeColorPairCollection(fromPair: ThemeColorPair(foreground: UIColor.white, background: lightBrandColor))
		))

		self.tableRowHighlightColors = colors.resolveThemeColorCollection("Table.tableRowHighlightColors", ThemeColorCollection(
			backgroundColor: UIColor.white.darker(0.1),
			tintColor: nil,
			labelColor: darkColor,
			secondaryLabelColor: UIColor(hex: 0x475770),
			symbolColor: UIColor(hex: 0x475770),
			filledColorPairCollection: ThemeColorPairCollection(fromPair: ThemeColorPair(foreground: UIColor.white, background: lightBrandColor))
		))

		self.tableRowButtonColors = colors.resolveThemeColorCollection("Table.tableRowButtonColors", ThemeColorCollection(
			backgroundColor: tableGroupBackgroundColor,
			tintColor: nil,
			labelColor: defaultTableRowLabelColor,
			secondaryLabelColor: UIColor(hex: 0x475770),
			symbolColor: UIColor(hex: 0x475770),
			filledColorPairCollection: ThemeColorPairCollection(fromPair: ThemeColorPair(foreground: defaultTableRowLabelColor, background: tableGroupBackgroundColor))
		))

		self.favoriteEnabledColor = UIColor(hex: 0xFFCC00)
		self.favoriteDisabledColor = UIColor(hex: 0x7C7C7C)

		// Styles
		switch style {
			case .dark:
				// Interface style
				self.interfaceStyle = styleResolver.resolveInterfaceStyle(fallback: .dark)
				self.keyboardAppearance = styleResolver.resolveKeyboardStyle(fallback: .dark)
				self.backgroundBlurEffectStyle = styleResolver.resolveBlurEffectStyle(fallback: .dark)

				// Bars
				self.navigationBarColors = colors.resolveThemeColorCollection("NavigationBar", self.darkBrandColors)
				self.toolbarColors = colors.resolveThemeColorCollection("Toolbar", self.darkBrandColors)
				self.loginColors = colors.resolveThemeColorCollection("Login", self.darkBrandColors)

				self.tokenColors = colors.resolveThemeColorPairCollection("Fill.tokenColors", ThemeColorPairCollection(fromPair: ThemeColorPair(foreground: lightBrandColor, background: UIColor(white: 1, alpha: 0.1))))

				// Table view
				self.tableBackgroundColor = colors.resolveColor("Table.tableBackgroundColor", navigationBarColors.backgroundColor!.darker(0.1))
				self.tableGroupBackgroundColor = colors.resolveColor("Table.tableGroupBackgroundColor", navigationBarColors.backgroundColor!.darker(0.3))
				let separatorColor : UIColor? = UIColor.darkGray
				self.tableSeparatorColor = colors.resolveColor("Table.tableSeparatorColor", separatorColor)
				let rowBorderColor : UIColor? = UIColor.white.withAlphaComponent(0.1)
				self.tableRowBorderColor = colors.resolveColor("Table.tableRowBorderColor", rowBorderColor)
				self.tableRowColors = colors.resolveThemeColorCollection("Table.tableRowColors", ThemeColorCollection(
					backgroundColor: tableBackgroundColor,
					tintColor: navigationBarColors.tintColor,
					labelColor: navigationBarColors.labelColor,
					secondaryLabelColor: navigationBarColors.secondaryLabelColor,
					symbolColor: lightColor,
					filledColorPairCollection: ThemeColorPairCollection(fromPair: ThemeColorPair(foreground: UIColor.white, background: lightBrandColor))
				))

				self.tableRowHighlightColors = colors.resolveThemeColorCollection("Table.tableRowHighlightColors", ThemeColorCollection(
					backgroundColor: lightColor.darker(0.2),
					tintColor: UIColor.white,
					labelColor: UIColor.white,
					secondaryLabelColor: UIColor.white,
					symbolColor: darkColor,
					filledColorPairCollection: ThemeColorPairCollection(fromPair: ThemeColorPair(foreground: UIColor.white, background: lightBrandColor))
				))

				self.tableRowButtonColors = colors.resolveThemeColorCollection("Table.tableRowButtonColors", ThemeColorCollection(
					backgroundColor: tableGroupBackgroundColor,
					tintColor: navigationBarColors.tintColor,
					labelColor: navigationBarColors.labelColor,
					secondaryLabelColor: navigationBarColors.secondaryLabelColor,
					symbolColor: lightColor,
					filledColorPairCollection: ThemeColorPairCollection(fromPair: ThemeColorPair(foreground: lightColor, background: tableGroupBackgroundColor))
				))

				// Bar styles
				self.statusBarStyle = styleResolver.resolveStatusBarStyle(for: "statusBarStyle", fallback: .lightContent)
				self.loginStatusBarStyle = styleResolver.resolveStatusBarStyle(for: "loginStatusBarStyle", fallback: self.statusBarStyle)
				self.barStyle = styleResolver.resolveBarStyle(fallback: .black)

				// Progress
				self.progressColors = colors.resolveThemeColorPair("Progress", ThemeColorPair(foreground: self.lightBrandColor, background: self.lightBrandColor.withAlphaComponent(0.3)))

				// Activity
				self.activityIndicatorViewStyle = styleResolver.resolveActivityIndicatorViewStyle(for: "activityIndicatorViewStyle", fallback: .medium)

				// Logo fill color
				let logoColor : UIColor? = UIColor.white
				logoFillColor = colors.resolveColor("Icon.logoFillColor", logoColor)

			case .light:
				// Interface style
				self.interfaceStyle = styleResolver.resolveInterfaceStyle(fallback: .light)
				self.keyboardAppearance = styleResolver.resolveKeyboardStyle(fallback: .light)
				self.backgroundBlurEffectStyle = styleResolver.resolveBlurEffectStyle(fallback: .light)

				// Bars
				self.navigationBarColors = colors.resolveThemeColorCollection("NavigationBar", ThemeColorCollection(
					backgroundColor: UIColor.white.darker(0.05),
					tintColor: nil,
					labelColor: darkColor,
					secondaryLabelColor: UIColor.gray,
					symbolColor: darkColor,
					filledColorPairCollection: ThemeColorPairCollection(fromPair: ThemeColorPair(foreground: UIColor.white, background: lightBrandColor))
				))

				self.toolbarColors = colors.resolveThemeColorCollection("Toolbar", self.navigationBarColors)
				self.loginColors = colors.resolveThemeColorCollection("Login", self.darkBrandColors)

				// Bar styles
				self.statusBarStyle = styleResolver.resolveStatusBarStyle(for: "statusBarStyle", fallback: .darkContent)
				self.loginStatusBarStyle = styleResolver.resolveStatusBarStyle(for: "loginStatusBarStyle", fallback: self.statusBarStyle)
				self.barStyle = styleResolver.resolveBarStyle(fallback: .default)

				// Progress
				self.progressColors = colors.resolveThemeColorPair("Progress", ThemeColorPair(foreground: self.lightBrandColor, background: UIColor.lightGray.withAlphaComponent(0.3)))

				// Activity
				self.activityIndicatorViewStyle = styleResolver.resolveActivityIndicatorViewStyle(for: "activityIndicatorViewStyle", fallback: .medium)

				// Logo fill color
				let logoColor : UIColor? = UIColor.lightGray
				logoFillColor = colors.resolveColor("Icon.logoFillColor", logoColor)

			case .contrast:
				// Interface style
				self.interfaceStyle = styleResolver.resolveInterfaceStyle(fallback: .light)
				self.keyboardAppearance = styleResolver.resolveKeyboardStyle(fallback: .light)
				self.backgroundBlurEffectStyle = styleResolver.resolveBlurEffectStyle(fallback: .light)

				// Bars
				self.navigationBarColors = colors.resolveThemeColorCollection("NavigationBar", self.darkBrandColors)
				let tmpDarkBrandColors = self.darkBrandColors

				if VendorServices.shared.isBranded {
					tmpDarkBrandColors.secondaryLabelColor = UIColor(hex: 0xF7F7F7)
				}
				if self.tintColor == UIColor(hex: 0xFFFFFF) {
					tmpDarkBrandColors.secondaryLabelColor = .lightGray
				}
				self.toolbarColors = colors.resolveThemeColorCollection("Toolbar", tmpDarkBrandColors)

				let defaultSearchBarColor = self.darkBrandColors
				if VendorServices.shared.isBranded {
					defaultSearchBarColor.labelColor = UIColor(hex: 0x000000)
					defaultSearchBarColor.secondaryLabelColor = UIColor.gray
					defaultSearchBarColor.backgroundColor = UIColor(hex: 0xF7F7F7)
					self.tableRowColors.symbolColor = darkColor
					self.tableRowHighlightColors.symbolColor = darkColor
				}

				self.loginColors = colors.resolveThemeColorCollection("Login", self.darkBrandColors)

				// Bar styles
                var defaultStatusBarStyle : UIStatusBarStyle = .lightContent
                if let backgroundColor = self.navigationBarColors.backgroundColor, backgroundColor.isLight() {
                    if #available(iOSApplicationExtension 13.0, *) {
                        defaultStatusBarStyle = .darkContent
                    } else {
                        defaultStatusBarStyle = .default
                    }
                }

                self.statusBarStyle = styleResolver.resolveStatusBarStyle(for: "statusBarStyle", fallback: defaultStatusBarStyle)
				self.loginStatusBarStyle = styleResolver.resolveStatusBarStyle(for: "loginStatusBarStyle", fallback: self.statusBarStyle)
				self.barStyle = styleResolver.resolveBarStyle(fallback: .black)

				// Progress
				self.progressColors = colors.resolveThemeColorPair("Progress", ThemeColorPair(foreground: self.lightBrandColor, background: UIColor.lightGray.withAlphaComponent(0.3)))

				// Activity
				self.activityIndicatorViewStyle = styleResolver.resolveActivityIndicatorViewStyle(for: "activityIndicatorViewStyle", fallback: .medium)

				// Logo fill color
				logoFillColor = UIColor.lightGray

				if lightBrandColor.isLight() {
					self.neutralColors.normal.background = self.darkBrandColor
					self.lightBrandColors.filledColorPairCollection.normal.background = self.darkBrandColor
                }
		}

		self.informalColors = colors.resolveThemeColorCollection("Informal", self.lightBrandColors)
		self.cancelColors = colors.resolveThemeColorCollection("Cancel", self.lightBrandColors)

		let iconSymbolColor = self.tableRowColors.symbolColor

		// CSS
		css.add(records: [
			// Global styles
			// - Interface Style
			ThemeCSSRecord(selectors: [.all], 			   	property: .style, value: self.interfaceStyle.userInterfaceStyle),

			// - Status Bar
			ThemeCSSRecord(selectors: [.all], 			   	property: .statusBarStyle, value: UIStatusBarStyle.darkContent),

			// - Activity Indicator
			ThemeCSSRecord(selectors: [.all], 			   	property: .activityIndicatorStyle, value: self.activityIndicatorViewStyle),

			// General
			// - Seperator
			ThemeCSSRecord(selectors: [.separator], 			property: .fill,  value: self.tableSeparatorColor),

			// - Navigation Bar
			ThemeCSSRecord(selectors: [.navigationBar],			property: .stroke, value: self.navigationBarColors.tintColor),
			ThemeCSSRecord(selectors: [.navigationBar, .label],		property: .stroke, value: self.navigationBarColors.labelColor),
			ThemeCSSRecord(selectors: [.navigationBar],			property: .fill, value: self.navigationBarColors.backgroundColor),

			// - Toolbar
			ThemeCSSRecord(selectors: [.toolbar],				property: .stroke, value: self.toolbarColors.tintColor),
			ThemeCSSRecord(selectors: [.toolbar],				property: .fill,   value: self.toolbarColors.backgroundColor),

			// - Progress
			ThemeCSSRecord(selectors: [.progress], 				property: .fill,  value: self.progressColors.background),
			ThemeCSSRecord(selectors: [.progress], 				property: .stroke,value: self.progressColors.foreground),
			ThemeCSSRecord(selectors: [.progress, .button],			property: .fill,  value: self.tintColor),

			// - Cells
			ThemeCSSRecord(selectors: [.cell, .sectionHeader],		property: .stroke, value: UIColor.black),

			// - Modal
			ThemeCSSRecord(selectors: [.modal],     	    	   	property: .fill,   value: self.tableBackgroundColor),
			ThemeCSSRecord(selectors: [.modal],     	    	   	property: .stroke, value: self.tableRowColors.labelColor),

			// - Collection View
			ThemeCSSRecord(selectors: [.collection],     	    	   	property: .fill,   value: self.tableBackgroundColor),
			ThemeCSSRecord(selectors: [.collection, .highlighted, .cell],  	property: .fill,   value: self.tableRowHighlightColors.backgroundColor),
			ThemeCSSRecord(selectors: [.collection, .cell], 	   	property: .stroke, value: self.lightBrandColor),
			ThemeCSSRecord(selectors: [.collection, .sectionFooter], 	property: .stroke, value: UIColor.secondaryLabel),
			// ThemeCSSRecord(selectors: [.collection, .cell], 	   	property: .fill,   value: self.tableRowColors.backgroundColor ?? .white),

			// - Table View
			ThemeCSSRecord(selectors: [.table],     	    	   	property: .fill,   value: self.tableBackgroundColor),
			ThemeCSSRecord(selectors: [.grouped, .table],  	    	   	property: .fill,   value: self.tableGroupBackgroundColor),
			ThemeCSSRecord(selectors: [.insetGrouped, .table],    	   	property: .fill,   value: self.tableGroupBackgroundColor),

			ThemeCSSRecord(selectors: [.table, .cell],    			property: .stroke, value: self.lightBrandColor), // tableRowColors.tintColor),
			ThemeCSSRecord(selectors: [.table, .cell],     	    	   	property: .fill,   value: self.tableRowColors.backgroundColor),
			ThemeCSSRecord(selectors: [.table, .highlighted, .cell],     	property: .fill,   value: self.tableRowHighlightColors.backgroundColor),

			ThemeCSSRecord(selectors: [.table, .sectionHeader],    		property: .stroke, value: self.tableSectionHeaderColor),
			ThemeCSSRecord(selectors: [.table, .sectionFooter],    		property: .stroke, value: self.tableSectionFooterColor),

			ThemeCSSRecord(selectors: [.table, .icon],    				property: .stroke, value: self.tableRowColors.symbolColor),
			ThemeCSSRecord(selectors: [.table, .label, .primary],    		property: .stroke, value: self.tableRowColors.labelColor),
			ThemeCSSRecord(selectors: [.table, .label, .secondary], 		property: .stroke, value: self.tableRowColors.secondaryLabelColor),
			ThemeCSSRecord(selectors: [.table, .label, .highlighted, .primary],    	property: .stroke, value: self.tableRowHighlightColors.labelColor),
			ThemeCSSRecord(selectors: [.table, .label, .highlighted, .secondary], 	property: .stroke, value: self.tableRowHighlightColors.secondaryLabelColor),

			// - Accessories
			ThemeCSSRecord(selectors: [.accessory], 			property: .stroke, value: self.tableRowColors.secondaryLabelColor),
			ThemeCSSRecord(selectors: [.accessory, .accept],		property: .stroke, value: UIColor.systemGreen),
			ThemeCSSRecord(selectors: [.accessory, .decline],		property: .stroke, value: UIColor.systemRed),

			// - Segment View
			ThemeCSSRecord(selectors: [.segments], 				property: .fill,   value: UIColor.clear),
			ThemeCSSRecord(selectors: [.segments, .icon], 			property: .stroke, value: self.tableRowColors.symbolColor),
			ThemeCSSRecord(selectors: [.segments, .title],			property: .stroke, value: self.tableRowColors.secondaryLabelColor),

			ThemeCSSRecord(selectors: [.segments, .token],			property: .fill,   value: self.tokenColors.normal.background),
			ThemeCSSRecord(selectors: [.segments, .token, .icon],		property: .stroke, value: self.tokenColors.normal.foreground),
			ThemeCSSRecord(selectors: [.segments, .token, .title],		property: .stroke, value: self.tokenColors.normal.foreground),

			// - Messages
			ThemeCSSRecord(selectors: [.infoBox, .background],		property: .fill, value: self.tableGroupBackgroundColor),
			ThemeCSSRecord(selectors: [.infoBox, .icon],			property: .fill, value: UIColor.secondaryLabel),

			ThemeCSSRecord(selectors: [.title],				property: .stroke, value: UIColor.label),
			ThemeCSSRecord(selectors: [.subtitle],				property: .stroke, value: UIColor.secondaryLabel),
			ThemeCSSRecord(selectors: [.message],				property: .stroke, value: UIColor.tertiaryLabel),

			ThemeCSSRecord(selectors: [.primary],				property: .stroke, value: UIColor.label),
			ThemeCSSRecord(selectors: [.secondary],				property: .stroke, value: UIColor.secondaryLabel),
			ThemeCSSRecord(selectors: [.tertiary],				property: .stroke, value: UIColor.tertiaryLabel),

			// - Fills
			ThemeCSSRecord(selectors: [.primary],				property: .fill, value: UIColor.systemBackground),
			ThemeCSSRecord(selectors: [.secondary],				property: .fill, value: UIColor.secondarySystemBackground),
			ThemeCSSRecord(selectors: [.tertiary],				property: .fill, value: UIColor.tertiarySystemBackground),

			// - Text Field
			ThemeCSSRecord(selectors: [.textField],				property: .fill,   value: self.tableBackgroundColor), // Background color
			ThemeCSSRecord(selectors: [.textField, .label],			property: .stroke, value: self.tableRowColors.labelColor), // Text color
			ThemeCSSRecord(selectors: [.textField, .disabled, .label],	property: .stroke, value: self.tableRowColors.secondaryLabelColor), // Disabled text color
			ThemeCSSRecord(selectors: [.textField, .placeholder],		property: .stroke, value: UIColor.placeholderText), // Text field placeholder

			// - Search Field
			ThemeCSSRecord(selectors: [.textField, .searchField],			property: .stroke, value: self.lightBrandColor), // Search tint color (UI elements other than text)
			ThemeCSSRecord(selectors: [.textField, .searchField, .label],		property: .stroke, value: UIColor.label), // Search text color

			// - Slider
			ThemeCSSRecord(selectors: [.slider], 				property: .stroke, value: self.tintColor),

			// - Buttons + Popups
			ThemeCSSRecord(selectors: [.button],				property: .stroke, value: self.tintColor),
			ThemeCSSRecord(selectors: [.popupButton],			property: .stroke, value: self.tintColor),

			// - Label styles
			ThemeCSSRecord(selectors: [.label, .destructive],		property: .stroke, value: UIColor.red),
			ThemeCSSRecord(selectors: [.label, .warning],			property: .stroke, value: self.warningColor),
			ThemeCSSRecord(selectors: [.label, .error],			property: .stroke, value: self.errorColor),
			ThemeCSSRecord(selectors: [.label, .success],			property: .stroke, value: self.successColor),

			// - Fill styles
			ThemeCSSRecord(selectors: [.destructive],			property: .stroke, value: self.destructiveColors.normal.foreground),
			ThemeCSSRecord(selectors: [.destructive],			property: .fill,   value: self.destructiveColors.normal.background),
			ThemeCSSRecord(selectors: [.destructive, .disabled],		property: .stroke, value: self.destructiveColors.disabled.foreground),
			ThemeCSSRecord(selectors: [.destructive, .disabled],		property: .fill,   value: self.destructiveColors.disabled.background),
			ThemeCSSRecord(selectors: [.destructive, .highlighted],		property: .stroke, value: self.destructiveColors.highlighted.foreground),
			ThemeCSSRecord(selectors: [.destructive, .highlighted],		property: .fill,   value: self.destructiveColors.highlighted.background),

			ThemeCSSRecord(selectors: [.confirm],				property: .stroke, value: self.approvalColors.normal.foreground),
			ThemeCSSRecord(selectors: [.confirm],				property: .fill,   value: self.approvalColors.normal.background),
			ThemeCSSRecord(selectors: [.confirm, .disabled],		property: .stroke, value: self.approvalColors.disabled.foreground),
			ThemeCSSRecord(selectors: [.confirm, .disabled],		property: .fill,   value: self.approvalColors.disabled.background),
			ThemeCSSRecord(selectors: [.confirm, .highlighted],		property: .stroke, value: self.approvalColors.highlighted.foreground),
			ThemeCSSRecord(selectors: [.confirm, .highlighted],		property: .fill,   value: self.approvalColors.highlighted.background),

			ThemeCSSRecord(selectors: [.cancel],				property: .stroke, value: self.neutralColors.normal.foreground),
			ThemeCSSRecord(selectors: [.cancel],				property: .fill,   value: self.neutralColors.normal.background),
			ThemeCSSRecord(selectors: [.cancel, .disabled],			property: .stroke, value: self.neutralColors.disabled.foreground),
			ThemeCSSRecord(selectors: [.cancel, .disabled],			property: .fill,   value: self.neutralColors.disabled.background),
			ThemeCSSRecord(selectors: [.cancel, .highlighted],		property: .stroke, value: self.neutralColors.highlighted.foreground),
			ThemeCSSRecord(selectors: [.cancel, .highlighted],		property: .fill,   value: self.neutralColors.highlighted.background),

			ThemeCSSRecord(selectors: [.proceed],				property: .stroke, value: self.neutralColors.normal.foreground),
			ThemeCSSRecord(selectors: [.proceed],				property: .fill,   value: self.neutralColors.normal.background),
			ThemeCSSRecord(selectors: [.proceed, .disabled],		property: .stroke, value: self.neutralColors.disabled.foreground),
			ThemeCSSRecord(selectors: [.proceed, .disabled],		property: .fill,   value: self.neutralColors.disabled.background),
			ThemeCSSRecord(selectors: [.proceed, .highlighted],		property: .stroke, value: self.neutralColors.highlighted.foreground),
			ThemeCSSRecord(selectors: [.proceed, .highlighted],		property: .fill,   value: self.neutralColors.highlighted.background),

			ThemeCSSRecord(selectors: [.info],				property: .stroke, value: self.neutralColors.normal.foreground),
			ThemeCSSRecord(selectors: [.info],				property: .fill,   value: self.neutralColors.normal.background),
			ThemeCSSRecord(selectors: [.info, .disabled],			property: .stroke, value: self.neutralColors.disabled.foreground),
			ThemeCSSRecord(selectors: [.info, .disabled],			property: .fill,   value: self.neutralColors.disabled.background),
			ThemeCSSRecord(selectors: [.info, .highlighted],		property: .stroke, value: self.neutralColors.highlighted.foreground),
			ThemeCSSRecord(selectors: [.info, .highlighted],		property: .fill,   value: self.neutralColors.highlighted.background),

			ThemeCSSRecord(selectors: [.warning],				property: .stroke, value: self.warningColors.normal.foreground),
			ThemeCSSRecord(selectors: [.warning],				property: .fill,   value: self.warningColors.normal.background),
			ThemeCSSRecord(selectors: [.warning, .disabled],		property: .stroke, value: self.warningColors.disabled.foreground),
			ThemeCSSRecord(selectors: [.warning, .disabled],		property: .fill,   value: self.warningColors.disabled.background),
			ThemeCSSRecord(selectors: [.warning, .highlighted],		property: .stroke, value: self.warningColors.highlighted.foreground),
			ThemeCSSRecord(selectors: [.warning, .highlighted],		property: .fill,   value: self.warningColors.highlighted.background),

			ThemeCSSRecord(selectors: [.purchase],				property: .stroke, value: self.purchaseColors.normal.foreground),
			ThemeCSSRecord(selectors: [.purchase],				property: .fill,   value: self.purchaseColors.normal.background),
			ThemeCSSRecord(selectors: [.purchase, .disabled],		property: .stroke, value: self.purchaseColors.disabled.foreground),
			ThemeCSSRecord(selectors: [.purchase, .disabled],		property: .fill,   value: self.purchaseColors.disabled.background),
			ThemeCSSRecord(selectors: [.purchase, .highlighted],		property: .stroke, value: self.purchaseColors.highlighted.foreground),
			ThemeCSSRecord(selectors: [.purchase, .highlighted],		property: .fill,   value: self.purchaseColors.highlighted.background),

			// - Pass code fill style
			ThemeCSSRecord(selectors: [.digit],				property: .stroke, value: self.neutralColors.normal.foreground),
			ThemeCSSRecord(selectors: [.digit],				property: .fill,   value: self.neutralColors.normal.background),
			ThemeCSSRecord(selectors: [.digit, .disabled],			property: .stroke, value: self.neutralColors.disabled.foreground),
			ThemeCSSRecord(selectors: [.digit, .disabled],			property: .fill,   value: self.neutralColors.disabled.background),
			ThemeCSSRecord(selectors: [.digit, .highlighted],		property: .stroke, value: self.neutralColors.highlighted.foreground),
			ThemeCSSRecord(selectors: [.digit, .highlighted],		property: .fill,   value: self.neutralColors.highlighted.background),

			ThemeCSSRecord(selectors: [.passcode],				property: .fill,   value: self.tableBackgroundColor),
			ThemeCSSRecord(selectors: [.passcode, .title],			property: .stroke, value: UIColor.label),
			ThemeCSSRecord(selectors: [.passcode, .disabled, .title],	property: .stroke, value: UIColor.secondaryLabel),
			ThemeCSSRecord(selectors: [.passcode, .code],			property: .stroke, value: self.neutralColors.normal.background),
			ThemeCSSRecord(selectors: [.passcode, .disabled, .code],	property: .stroke, value: UIColor.label),
			ThemeCSSRecord(selectors: [.passcode, .subtitle],		property: .stroke, value: UIColor.secondaryLabel),
			ThemeCSSRecord(selectors: [.passcode, .disabled, .subtitle],	property: .stroke, value: UIColor.tertiaryLabel),

			// - Alert View Controller
			ThemeCSSRecord(selectors: [.alert],				property: .stroke, value: self.tintColor),

			// - Action / Drop target (plain) fill style
			ThemeCSSRecord(selectors: [.action],				property: .fill, value: UIColor(white: 0, alpha: 0.05)),
			ThemeCSSRecord(selectors: [.action, .highlighted],		property: .fill, value: UIColor(white: 0, alpha: 0.10)),

			// - Drive Header
			ThemeCSSRecord(selectors: [.header, .drive, .cover],		property: .fill, value: self.lightBrandColor),

			// - Expandable Resource Cell
			ThemeCSSRecord(selectors: [.expandable],			property: .fill,   value: self.tableBackgroundColor),
			ThemeCSSRecord(selectors: [.expandable, .button],		property: .stroke, value: self.tintColor),
			ThemeCSSRecord(selectors: [.expandable, .textView],		property: .fill,   value: self.tableBackgroundColor),
			ThemeCSSRecord(selectors: [.expandable, .textView],		property: .stroke, value: UIColor.secondaryLabel),
			ThemeCSSRecord(selectors: [.expandable, .shadow],		property: .fill,   value: self.tableRowColors.tintColor),

			// - Location Bar
			ThemeCSSRecord(selectors: [.locationBar],			property: .fill, value: self.tableRowColors.backgroundColor ?? .white),

			// - Keyboard
			ThemeCSSRecord(selectors: [.all],				property: .keyboardAppearance, value: (style == .dark) ? UIKeyboardAppearance.dark : UIKeyboardAppearance.light),

			// - Account Cell
			ThemeCSSRecord(selectors: [.account],				property: .fill,   value: self.darkBrandColor),
			ThemeCSSRecord(selectors: [.account, .title],			property: .stroke, value: UIColor.white),
			ThemeCSSRecord(selectors: [.account, .description],		property: .stroke, value: UIColor.lightGray),
			ThemeCSSRecord(selectors: [.account, .disconnect],		property: .stroke, value: self.tintColor),
			ThemeCSSRecord(selectors: [.account, .disconnect],		property: .fill,   value: UIColor.white),

			// - Location Picker
			ThemeCSSRecord(selectors: [.locationPicker, .collection, .accountList], property: .fill, value: self.tableGroupBackgroundColor),
			ThemeCSSRecord(selectors: [.locationPicker, .collection, .accountList, .cell], property: .fill, value: UIColor.white),
			ThemeCSSRecord(selectors: [.locationPicker, .collection, .accountList, .account], property: .fill, value: self.darkBrandColor),

			// - More card header
			ThemeCSSRecord(selectors: [.table, .grouped, .more, .header], 	property: .fill, value: self.tableBackgroundColor),
			ThemeCSSRecord(selectors: [.more, .favorite],			property: .stroke, value: self.favoriteEnabledColor),
			ThemeCSSRecord(selectors: [.more, .favorite, .disabled],	property: .stroke, value: self.favoriteDisabledColor),

			// - TVG icon colors
			ThemeCSSRecord(selectors: [.vectorImage, .folderFillColor], 	property: .fill, value: iconSymbolColor),
			ThemeCSSRecord(selectors: [.vectorImage, .fileFillColor], 	property: .fill, value: iconSymbolColor),
			ThemeCSSRecord(selectors: [.vectorImage, .logoFillColor], 	property: .fill, value: logoFillColor ?? UIColor.white),
			ThemeCSSRecord(selectors: [.vectorImage, .iconFillColor], 	property: .fill, value: tableRowColors.tintColor ?? iconSymbolColor),
			ThemeCSSRecord(selectors: [.vectorImage, .symbolFillColor], 	property: .fill, value: iconSymbolColor),

			// Side Bar
			// - Interface Style
			ThemeCSSRecord(selectors: [.sidebar], 			   	property: .style, value: UIUserInterfaceStyle.light),

			// - Status Bar
			ThemeCSSRecord(selectors: [.sidebar], 			   	property: .statusBarStyle, value: UIStatusBarStyle.darkContent),

			// - Collection View
			ThemeCSSRecord(selectors: [.sidebar, .collection, .cell],  	property: .fill,   value: UIColor.clear),
			ThemeCSSRecord(selectors: [.sidebar, .collection],  	   	property: .fill,   value: self.lightBrandColor),
			ThemeCSSRecord(selectors: [.sidebar, .collection, .cell], 	property: .stroke, value: UIColor.white),
			ThemeCSSRecord(selectors: [.sidebar, .collection, .label], 	property: .stroke, value: self.darkBrandColor),
			ThemeCSSRecord(selectors: [.sidebar, .collection, .icon],  	property: .stroke, value: self.darkBrandColor),

			ThemeCSSRecord(selectors: [.sidebar, .collection, .selected, .cell],  property: .stroke, value: self.darkBrandColor),
			ThemeCSSRecord(selectors: [.sidebar, .collection, .selected, .cell],  property: .fill, value: UIColor.white),

			// - Account Cell
			ThemeCSSRecord(selectors: [.sidebar, .account],			property: .fill,   value: self.darkBrandColor.withAlphaComponent(0.5)),
			ThemeCSSRecord(selectors: [.sidebar, .account, .title],		property: .stroke, value: UIColor.white),
			ThemeCSSRecord(selectors: [.sidebar, .account, .description],	property: .stroke, value: UIColor.lightGray),
			ThemeCSSRecord(selectors: [.sidebar, .account, .disconnect],	property: .stroke, value: self.tintColor),
			ThemeCSSRecord(selectors: [.sidebar, .account, .disconnect],	property: .fill,   value: UIColor.white),

			// - Navigation Bar
			ThemeCSSRecord(selectors: [.sidebar, .navigationBar],		property: .stroke, value: UIColor.white),
			ThemeCSSRecord(selectors: [.sidebar, .navigationBar],		property: .fill,   value: nil),
			ThemeCSSRecord(selectors: [.sidebar, .navigationBar, .logo],	property: .stroke, value: UIColor.white),
			ThemeCSSRecord(selectors: [.sidebar, .navigationBar, .logo, .label],property: .stroke, value: UIColor.white),

			// - Toolbar
			ThemeCSSRecord(selectors: [.sidebar, .toolbar],			property: .fill,   value: self.lightBrandColor),
			ThemeCSSRecord(selectors: [.sidebar, .toolbar],			property: .stroke, value: UIColor.white),

			// Content Area
			ThemeCSSRecord(selectors: [.content],				property: .fill,   value: self.tableRowColors.backgroundColor),

			// - Navigation Bar
			ThemeCSSRecord(selectors: [.content, .navigationBar],		property: .fill,   value: self.tableRowColors.backgroundColor ?? .white),
			ThemeCSSRecord(selectors: [.content, .navigationBar],		property: .stroke, value: self.navigationBarColors.tintColor),
			ThemeCSSRecord(selectors: [.content, .navigationBar, .label],	property: .stroke, value: self.navigationBarColors.labelColor) // ,
//
//			ThemeCSSRecord(selectors: [.sidebar, .navigationBar, .logo],		property: .stroke, value: UIColor.red),
//			ThemeCSSRecord(selectors: [.sidebar, .navigationBar, .logo, .label],	property: .stroke, value: UIColor.white),
//			ThemeCSSRecord(selectors: [.sidebar, .navigationBar, .logo, .icon],	property: .stroke, value: UIColor.systemPink)
		])

//		{
//			<key>sidebar.collection.icon.stroke</key>
//			<string>#ffffff</string>
//
//			<key>css.0</key><string>sidebar.collection.icon.stroke=#ffffff</string>
//			<key>css.1</key><string>sidebar.collection.icon.stroke=#ffffff</string>
//
//			ThemeCSSRecord(selectors: [.sidebar, .collection, .icon],  property: .stroke, value: UIColor.white)
//
//		}
	}

	convenience override init() {
		self.init(darkBrandColor: UIColor(hex: 0x1D293B), lightBrandColor: UIColor(hex: 0x468CC8))
	}

	// MARK: - Icon colors
	var _iconColors: [String:String]?
	public var iconColors: [String:String] {
		if _iconColors == nil {
			_iconColors = [:]

			_iconColors?["folderFillColor"] = css.getColor(.fill, selectors: [.vectorImage, .folderFillColor], for: nil)?.hexString()
			_iconColors?["fileFillColor"] = css.getColor(.fill, selectors: [.vectorImage, .fileFillColor], for: nil)?.hexString()
			_iconColors?["logoFillColor"] = css.getColor(.fill, selectors: [.vectorImage, .logoFillColor], for: nil)?.hexString()
			_iconColors?["iconFillColor"] = css.getColor(.fill, selectors: [.vectorImage, .iconFillColor], for: nil)?.hexString()
			_iconColors?["symbolFillColor"] = css.getColor(.fill, selectors: [.vectorImage, .symbolFillColor], for: nil)?.hexString()
			_iconColors?["folderFillColor"] = css.getColor(.fill, selectors: [.vectorImage, .folderFillColor], for: nil)?.hexString()
		}

		return _iconColors ?? [:]
	}
}

extension ThemeCSSSelector {
	static let folderFillColor = ThemeCSSSelector(rawValue: "folderFillColor")
	static let fileFillColor = ThemeCSSSelector(rawValue: "fileFillColor")
	static let logoFillColor = ThemeCSSSelector(rawValue: "logoFillColor")
	static let iconFillColor = ThemeCSSSelector(rawValue: "iconFillColor")
	static let symbolFillColor = ThemeCSSSelector(rawValue: "symbolFillColor")
}

class ThemeStyleValueResolver : NSObject {

	var styles: NSDictionary?

	init(styleValues : NSDictionary?) {
		styles = styleValues
	}

	func resolveStatusBarStyle(for key: String, fallback: UIStatusBarStyle) -> UIStatusBarStyle {
		if let styleValue = styles?.value(forKeyPath: key) as? String {
			switch styleValue {
			case "default":
				return .default
			case "lightContent":
				return .lightContent
			case "darkContent":
				return .darkContent
			default:
				return fallback
			}
		}
		return fallback
	}

	func resolveBarStyle(fallback: UIBarStyle) -> UIBarStyle {
		if let styleValue = styles?.value(forKeyPath: "barStyle") as? String {
			switch styleValue {
			case "default":
				return .default
			case "black":
				return .black
			default:
				return fallback
			}
		}
		return fallback
	}

	func resolveActivityIndicatorViewStyle(for key: String, fallback: UIActivityIndicatorView.Style) -> UIActivityIndicatorView.Style {
		if let styleValue = styles?.value(forKeyPath: key) as? String {
			switch styleValue {
			case "medium", "white", "gray":
				return .medium
			case "whiteLarge", "large":
				return .large
			default:
				return fallback
			}
		}
		return fallback
	}

	func resolveKeyboardStyle(fallback: UIKeyboardAppearance) -> UIKeyboardAppearance {
		if let styleValue = styles?.value(forKeyPath: "keyboardAppearance") as? String {
			switch styleValue {
			case "default":
				return .default
			case "light":
				return .light
			case "dark":
				return .dark
			default:
				return fallback
			}
		}
		return fallback
	}

	func resolveBlurEffectStyle(fallback: UIBlurEffect.Style) -> UIBlurEffect.Style {
		if let styleValue = styles?.value(forKeyPath: "backgroundBlurEffectStyle") as? String {
			switch styleValue {
			case "regular":
				return .regular
			case "light":
				return .light
			case "dark":
				return .dark
			default:
				return fallback
			}
		}
		return fallback
	}

	func resolveInterfaceStyle(fallback: ThemeCollectionInterfaceStyle) -> ThemeCollectionInterfaceStyle {
		if let styleValue = styles?.value(forKeyPath: "interfaceStyle") as? String {
			switch styleValue {
			case "unspecified":
				return .unspecified
			case "light":
				return .light
			case "dark":
				return .dark
			default:
				return fallback
			}
		}
		return fallback
	}

}

class ThemeColorValueResolver : NSObject {

	var generic: NSDictionary?
	var colors: NSDictionary?

	var themeCollectionStyle : ThemeCollectionStyle?

	init(colorValues : NSDictionary?, genericValues: NSDictionary?, themeCollectionStyle: ThemeCollectionStyle? = nil) {
		colors = colorValues
		generic = genericValues
		self.themeCollectionStyle = themeCollectionStyle
	}

	func resolveColor(_ forKeyPath: String, _ fallback : UIColor) -> UIColor {
		if let rawColor = colors?.value(forKeyPath: forKeyPath) as? String {
			if rawColor.contains("."), let genericRawColor = generic?.value(forKeyPath: rawColor) as? String, let decodedHexColor = genericRawColor.colorFromHex {
				return decodedHexColor
			} else if let decodedHexColor = rawColor.colorFromHex {
				return decodedHexColor
			}
		}
		return fallback
	}

	func resolveColor(_ forKeyPath: String, _ fallback : UIColor? = nil) -> UIColor? {
		if let rawColor = colors?.value(forKeyPath: forKeyPath) as? String {
			if rawColor.contains("."), let genericRawColor = generic?.value(forKeyPath: rawColor) as? String, let decodedHexColor = genericRawColor.colorFromHex {
				return decodedHexColor
			} else if let decodedHexColor = rawColor.colorFromHex {
				if forKeyPath.hasPrefix("NavigationBar") {
				}
				return decodedHexColor
			}
		}
		return fallback
	}

	func resolveThemeColorPair(_ forKeyPath: String, _ colorPair : ThemeColorPair) -> ThemeColorPair {
		let pair = ThemeColorPair(foreground: self.resolveColor(forKeyPath.appending(".foreground"), colorPair.foreground),
								  background: self.resolveColor(forKeyPath.appending(".background"), colorPair.background))

		return pair
	}

	func resolveThemeColorCollection(_ forKeyPath: String, _ colorCollection : ThemeColorCollection) -> ThemeColorCollection {
		let collection = ThemeColorCollection(backgroundColor: self.resolveColor(forKeyPath.appending(".backgroundColor"), colorCollection.backgroundColor),
											  tintColor: self.resolveColor(forKeyPath.appending(".tintColor"), colorCollection.tintColor),
											  labelColor: self.resolveColor(forKeyPath.appending(".labelColor"), colorCollection.labelColor),
											  secondaryLabelColor: self.resolveColor(forKeyPath.appending(".secondaryLabelColor"), colorCollection.secondaryLabelColor),
											  symbolColor: self.resolveColor(forKeyPath.appending(".symbolColor"), colorCollection.symbolColor),
											  filledColorPairCollection: self.resolveThemeColorPairCollection(forKeyPath.appending(".filledColorPairCollection"), colorCollection.filledColorPairCollection))

		return collection
	}

	func resolveThemeColorPairCollection(_ forKeyPath: String, _ colorPairCollection : ThemeColorPairCollection) -> ThemeColorPairCollection {
		let newColorPairCollection = ThemeColorPairCollection(fromPairCollection: colorPairCollection)

		if let baseForegroundColor = self.resolveColor(forKeyPath.appending(".baseForegroundColor")),
		   let baseBackgroundColor = self.resolveColor(forKeyPath.appending(".baseBackgroundColor")) {
			return ThemeColorPairCollection(fromPair: ThemeColorPair(foreground: baseForegroundColor, background: baseBackgroundColor))
		} else {
			newColorPairCollection.normal = self.resolveThemeColorPair(forKeyPath.appending(".normal"), colorPairCollection.normal)
			newColorPairCollection.highlighted = self.resolveThemeColorPair(forKeyPath.appending(".highlighted"), colorPairCollection.highlighted)
			newColorPairCollection.disabled = self.resolveThemeColorPair(forKeyPath.appending(".disabled"), colorPairCollection.disabled)
		}

		return newColorPairCollection
	}

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

		if scrollEdge {
			appearance.shadowColor = .clear
		}

		return appearance
	}
}
