//
//  ThemeTableViewCell.swift
//  ownCloud
//
//  Created by Felix Schwarz on 16.04.18.
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

open class ThemeTableViewCell: UITableViewCell, Themeable {
	private var themeRegistered = false

	public var updateLabelColors : Bool = true

	public var messageStyle : StaticTableViewRowMessageStyle?

	public var primaryTextLabel : UILabel? {
		return customTextLabels?.first ?? textLabel
	}
	public var primaryDetailTextLabel : UILabel? {
		return customDetailTextLabels?.first ?? detailTextLabel
	}

	public var customTextLabels : [UILabel]?
	public var customDetailTextLabels : [UILabel]?

	public struct CellStyleSet {
		public var theme: Theme
		public var collection: ThemeCollection
		public var backgroundColor: UIColor?
		public var textColor: UIColor?
	}

	public typealias CellStyler = (_ cell: ThemeTableViewCell, _ styleSet: CellStyleSet) -> Bool

	public var cellStyler : CellStyler?

	override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
		if style == .default {
			// This is a workaround, because some cells with style .default does not support automatically Right-to-Left UI support. When switching to style .subtitle, the style will be kept, if no subtitle was set ant the RtL support will work on this cells
			super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
		} else {
			super.init(style: style, reuseIdentifier: reuseIdentifier)
		}
	}

	public typealias CellLayouter = (_ cell: ThemeTableViewCell, _ textLabel: UILabel, _ detailLabel : UILabel?) -> Void

	static public var systemLikeLayout : CellLayouter = { (cell, textLabel, detailLabel) in
		customLeadingViewLayout(leadingView: cell.contentView)(cell, textLabel, detailLabel)
	}

	static func customLeadingViewLayout(leadingView: UIView) -> CellLayouter {
		let layouter : CellLayouter = { (cell, textLabel, detailLabel) in
			let includeLeadingView : Bool = (leadingView != cell.contentView)
			var leadingAnchor : NSLayoutXAxisAnchor = cell.contentView.leadingAnchor

			if includeLeadingView {
				if leadingView.superview == nil {
					// Add leadingView
					cell.contentView.addSubview(leadingView)
				}

				leadingAnchor = leadingView.trailingAnchor
			}

			var constraints = [
				textLabel.leadingAnchor.constraint(equalToSystemSpacingAfter: leadingAnchor, multiplier: 1),
				textLabel.trailingAnchor.constraint(equalToSystemSpacingAfter: cell.contentView.trailingAnchor, multiplier: -1)
			]

			if let detailLabel = detailLabel {
				constraints += [
					textLabel.topAnchor.constraint(equalToSystemSpacingBelow: cell.contentView.topAnchor, multiplier: 1),

					detailLabel.leadingAnchor.constraint(equalToSystemSpacingAfter: leadingAnchor, multiplier: 1),
					detailLabel.trailingAnchor.constraint(equalToSystemSpacingAfter: cell.contentView.trailingAnchor, multiplier: -1),

					detailLabel.topAnchor.constraint(equalToSystemSpacingBelow: textLabel.bottomAnchor, multiplier: 1),
					detailLabel.bottomAnchor.constraint(equalToSystemSpacingBelow: cell.contentView.bottomAnchor, multiplier: -1)
				]
			} else {
				constraints += [
					textLabel.topAnchor.constraint(greaterThanOrEqualTo: cell.contentView.topAnchor, constant: 11),
					textLabel.bottomAnchor.constraint(lessThanOrEqualTo: cell.contentView.bottomAnchor, constant: -11),
					textLabel.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor)
				]
			}

			if includeLeadingView {
				constraints += [
					leadingView.leadingAnchor.constraint(equalToSystemSpacingAfter: cell.contentView.leadingAnchor, multiplier: 1),
					leadingView.topAnchor.constraint(greaterThanOrEqualToSystemSpacingBelow:cell.contentView.topAnchor, multiplier: 1),
					leadingView.bottomAnchor.constraint(lessThanOrEqualToSystemSpacingBelow:cell.contentView.bottomAnchor, multiplier: -1),
					leadingView.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor)
				]
			}

			NSLayoutConstraint.activate(constraints)
		}

		return layouter
	}

	convenience public init(withLabelColorUpdates labelColorUpdates: Bool, style: UITableViewCell.CellStyle = .default, recreatedLabelLayout : CellLayouter? = nil, reuseIdentifier: String? = nil) {
		self.init(style: style, reuseIdentifier: reuseIdentifier)

		if let recreatedLabelLayout = recreatedLabelLayout {
			let replacementTextLabel = UILabel()
			var replacementDetailLabel : UILabel?

			replacementTextLabel.translatesAutoresizingMaskIntoConstraints = false
			replacementTextLabel.makeLabelWrapText()

			replacementTextLabel.font = (style == .subtitle) ?
				UIFont.systemFont(ofSize: UIFont.systemFontSize) :
				UIFont.systemFont(ofSize: UIFont.labelFontSize)

			self.customTextLabels = [ replacementTextLabel ]
			self.contentView.addSubview(replacementTextLabel)

			if style == .subtitle {
				replacementDetailLabel = UILabel()

				replacementDetailLabel?.translatesAutoresizingMaskIntoConstraints = false
				replacementDetailLabel?.makeLabelWrapText()

				replacementDetailLabel?.font = UIFont.systemFont(ofSize: UIFont.smallSystemFontSize)

				self.customDetailTextLabels = [ replacementDetailLabel! ]
				self.contentView.addSubview(replacementDetailLabel!)
			}

			recreatedLabelLayout(self, replacementTextLabel, replacementDetailLabel)
		}

		updateLabelColors = labelColorUpdates
	}

	required public init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	deinit {
		if themeRegistered {
			Theme.shared.unregister(client: self)
		}
	}

	open override func willMove(toSuperview newSuperview: UIView?) {
		super.willMove(toSuperview: newSuperview)

		if !themeRegistered {
			// Postpone registration with theme until we actually need to. Makes sure self.applyThemeCollection() can take all properties into account
			Theme.shared.register(client: self, applyImmediately: true)
			themeRegistered = true
		}
	}

	open func applyThemeCollectionToCellContents(theme: Theme, collection: ThemeCollection) {
		let state = ThemeItemState(selected: self.isSelected)

		if updateLabelColors {
			if let messageStyle = messageStyle {
				var textColor, backgroundColor : UIColor?
				var doStyle = true

				switch messageStyle {
					case .plain:
						textColor = collection.tableRowColors.labelColor
						backgroundColor = collection.tableRowColors.backgroundColor

					case .text:
						textColor = collection.tableRowColors.labelColor
						backgroundColor = collection.tableRowColors.backgroundColor

					case .text:
						textColor = collection.tableRowColors.labelColor
						backgroundColor = collection.tableRowColors.backgroundColor

					case .confirmation:
						textColor = collection.approvalColors.normal.foreground
						backgroundColor = collection.approvalColors.normal.background

					case .warning:
						textColor = .black
						backgroundColor = .systemYellow

					case .alert:
						textColor = collection.destructiveColors.normal.foreground
						backgroundColor = collection.destructiveColors.normal.background

					case let .custom(customTextColor, customBackgroundColor, _):
						textColor = customTextColor
						backgroundColor = customBackgroundColor
				}

				if let cellStyler = cellStyler, cellStyler(self, CellStyleSet(theme: theme, collection: collection, backgroundColor: backgroundColor, textColor: textColor)) {
					doStyle = false
				}

				if doStyle {
					self.textLabel?.textColor = textColor
					self.detailTextLabel?.textColor = textColor
					self.backgroundColor = backgroundColor

					if let customTextLabels = customTextLabels {
						for customTextLabel in customTextLabels {
							customTextLabel.textColor = textColor
						}
					}

					if let customMessageLabels = customDetailTextLabels {
						for customMessageLabel in customMessageLabels {
							customMessageLabel.textColor = textColor
						}
					}
				}
			} else {
				self.textLabel?.applyThemeCollection(collection, itemStyle: .defaultForItem, itemState: state)
				self.detailTextLabel?.applyThemeCollection(collection, itemStyle: .message, itemState: state)

				if let customTextLabels = customTextLabels {
					for customTextLabel in customTextLabels {
						customTextLabel.applyThemeCollection(collection, itemStyle: .defaultForItem, itemState: state)
					}
				}

				if let customMessageLabels = customDetailTextLabels {
					for customMessageLabel in customMessageLabels {
						customMessageLabel.applyThemeCollection(collection, itemStyle: .message, itemState: state)
					}
				}
			}
		}
	}

	open func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		self.applyThemeCollection(Theme.shared.activeCollection)

		self.applyThemeCollectionToCellContents(theme: theme, collection: collection)
	}

	open override func setSelected(_ selected: Bool, animated: Bool) {
		super.setSelected(selected, animated: animated)

		if self.selectionStyle != .none {
			self.applyThemeCollectionToCellContents(theme: Theme.shared, collection: Theme.shared.activeCollection)
		}
	}
}
