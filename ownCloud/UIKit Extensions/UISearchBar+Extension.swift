//
//  UISearchBar+Extension.swift
//  ownCloud
//
//  Created by Matthias Hühne on 30.04.19.
//  Copyright © 2019 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2019, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
*/

import Foundation
import UIKit

extension UISearchBar {
func changeSearchBarColor(fieldColor: UIColor, backColor: UIColor, borderColor: UIColor?) {
	UIGraphicsBeginImageContext(bounds.size)
	backColor.setFill()
	UIBezierPath(rect: bounds).fill()
	setBackgroundImage(UIGraphicsGetImageFromCurrentImageContext()!, for: UIBarPosition.any, barMetrics: .default)

	var newRect = bounds
	newRect.size.height = 38.0
	//let newBounds = bounds.insetBy(dx: 0, dy: 0)
	//newBounds.height = 20
	fieldColor.setFill()
	let path = UIBezierPath(roundedRect: newRect, cornerRadius: 8.0)

	if let borderColor = borderColor {
		borderColor.setStroke()
		path.lineWidth = 1 / UIScreen.main.scale
		path.stroke()
	}

	path.fill()
	setSearchFieldBackgroundImage(UIGraphicsGetImageFromCurrentImageContext()!, for: UIControl.State.normal)
	searchTextPositionAdjustment = UIOffset(horizontal: 8.0, vertical: -8.0)
	positionAdjustment(for: UISearchBar.Icon.Type) = UIOffset(horizontal: 8.0, vertical: -8.0)

	UIGraphicsEndImageContext()
	}
}

extension UISearchBar {

    func changeSearchBarColor(color: UIColor) {
        UIGraphicsBeginImageContext(self.frame.size)
        color.setFill()
        UIBezierPath(rect: self.frame).fill()
        let bgImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()

        self.setSearchFieldBackgroundImage(bgImage, for: .normal)
    }

	public var textField: UITextField? {
		let subViews = self.subviews.flatMap { $0.subviews }
		return (subViews.filter { $0 is UITextField }).first as? UITextField
	}

	public var searchIcon: UIImage? {
		let subViews = subviews.flatMap { $0.subviews }
		return  ((subViews.filter { $0 is UIImageView }).first as? UIImageView)?.image
	}

	public var searchIconView: UIView? {
		return textField?.leftView
	}

	public var activityIndicator: UIActivityIndicatorView? {
		return textField?.leftView?.subviews.compactMap { $0 as? UIActivityIndicatorView }.first
	}

	var isLoading: Bool {
		get {
			return activityIndicator != nil
		} set {
			OnMainThread {
				let _searchIcon = self.searchIcon
				if newValue {
					if self.activityIndicator == nil {
						let _activityIndicator = UIActivityIndicatorView(style: Theme.shared.activeCollection.searchBarActivityIndicatorViewStyle)
						_activityIndicator.startAnimating()
						_activityIndicator.backgroundColor = UIColor.clear
						self.setImage(UIImage(), for: .search, state: .normal)
						self.textField?.leftView?.addSubview(_activityIndicator)
						let leftViewSize = self.textField?.leftView?.frame.size ?? CGSize.zero
						_activityIndicator.center = CGPoint(x: leftViewSize.width/2, y: leftViewSize.height/2)
					}
				} else {
					self.setImage(_searchIcon, for: .search, state: .normal)
					self.activityIndicator?.removeFromSuperview()
				}
			}
		}
	}
}
