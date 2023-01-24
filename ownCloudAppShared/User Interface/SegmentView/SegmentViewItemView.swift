//
//  SegmentViewItemView.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 29.09.22.
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

public class SegmentViewItemView: ThemeView {
	weak var item: SegmentViewItem?

	var iconView: UIImageView?
	var titleView: UILabel?

	public init(with item: SegmentViewItem) {
		self.item = item

		super.init()

		isOpaque = false
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	open override func setupSubviews() {
		super.setupSubviews()
		compose()
	}

	open func compose() {
		guard let item else { return }

		let rootView = self
		var views : [UIView] = []

		rootView.setContentHuggingPriority(.required, for: .horizontal)
		rootView.setContentHuggingPriority(.required, for: .vertical)

		if let icon = item.icon {
			iconView = UIImageView()
			iconView?.image = icon.withRenderingMode(.alwaysTemplate)
			iconView?.contentMode = .scaleAspectFit
			iconView?.translatesAutoresizingMaskIntoConstraints = false
			iconView?.setContentHuggingPriority(.required, for: .horizontal)
			iconView?.setContentHuggingPriority(.required, for: .vertical)
			iconView?.setContentCompressionResistancePriority(.required, for: .horizontal)
			iconView?.setContentCompressionResistancePriority(.required, for: .vertical)
			views.append(iconView!)
		}

		if let title = item.title {
			titleView = UILabel()
			titleView?.translatesAutoresizingMaskIntoConstraints = false
			titleView?.text = title
			if let titleTextStyle = item.titleTextStyle {
				if let titleTextWeight = item.titleTextWeight {
					titleView?.font = .preferredFont(forTextStyle: titleTextStyle, with: titleTextWeight)
				} else {
					titleView?.font = .preferredFont(forTextStyle: titleTextStyle)
				}
			}
			titleView?.setContentHuggingPriority(.required, for: .horizontal)
			titleView?.setContentHuggingPriority(.required, for: .vertical)
			titleView?.setContentCompressionResistancePriority(.required, for: .vertical)
			titleView?.setContentCompressionResistancePriority(.required, for: .horizontal)

			views.append(titleView!)
		}

		embedHorizontally(views: views, insets: item.insets, limitHeight: item.segmentView?.limitVerticalSpaceUsage ?? false, spacingProvider: { leadingView, trailingView in
			if trailingView == self.titleView, leadingView == self.iconView {
				return item.iconTitleSpacing
			}

			return nil
		})

		switch item.cornerStyle {
			case .none, .sharp:
				layer.cornerRadius = 0

			case .round(let points):
				layer.cornerRadius = points
		}

		alpha = item.alpha
	}

	public override func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		super.applyThemeCollection(theme: theme, collection: collection, event: event)

		if let item {
			switch item.style {
				case .plain, .label:
					iconView?.tintColor = collection.tableRowColors.symbolColor
					titleView?.textColor = collection.tableRowColors.secondaryLabelColor
					backgroundColor = .clear

				case .token:
					iconView?.tintColor = collection.tokenColors.normal.foreground
					titleView?.textColor = collection.tokenColors.normal.foreground
					backgroundColor = collection.tokenColors.normal.background
			}
		}
	}
}
