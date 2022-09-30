//
//  SegmentViewItem.swift
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

public class SegmentViewItem: NSObject {
	public enum CornerStyle {
		case sharp
		case round(points: CGFloat)
	}

	public enum Style {
		case plain
		case label
		case filled
	}

	open var style: Style
	open var icon: UIImage?
	open var title: String?
	open var titleTextStyle: UIFont.TextStyle?

	open var representedObject: AnyObject?
	open weak var weakRepresentedObject: AnyObject?

	open var iconTitleSpacing: CGFloat = 2
	open var insets: NSDirectionalEdgeInsets = NSDirectionalEdgeInsets(top: 3, leading: 5, bottom: 3, trailing: 5)
	open var cornerStyle: CornerStyle?

	var _view: UIView?
	open var view: UIView? {
		if _view == nil {
			_view = SegmentViewItemView(with: self)
			_view?.translatesAutoresizingMaskIntoConstraints = false
		}
		return _view
	}

	public init(with icon: UIImage? = nil, title: String? = nil, style: Style = .plain, titleTextStyle: UIFont.TextStyle? = nil, representedObject: AnyObject? = nil, weakRepresentedObject: AnyObject? = nil) {
		self.style = style

		super.init()

		self.icon = icon
		self.title = title
		self.titleTextStyle = titleTextStyle
		self.representedObject = representedObject
		self.weakRepresentedObject = weakRepresentedObject
	}
}
