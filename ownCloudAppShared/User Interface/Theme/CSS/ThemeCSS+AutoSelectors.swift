//
//  ThemeCSS+AutoSelectors.swift
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

extension UILabel: ThemeCSSAutoSelector {
	public var cssAutoSelectors: [ThemeCSSSelector] {
		return [.label]
	}
}

extension UICollectionReusableView: ThemeCSSAutoSelector {
	public var cssAutoSelectors: [ThemeCSSSelector] {
		return [.cell]
	}
}

extension UICollectionView: ThemeCSSAutoSelector {
	public var cssAutoSelectors: [ThemeCSSSelector] {
		return [.collection]
	}
}

extension UITableView: ThemeCSSAutoSelector {
	public var cssAutoSelectors: [ThemeCSSSelector] {
		switch style {
			case .grouped: return [.grouped, .table]
			case .insetGrouped: return [.insetGrouped, .table]
			default: return [.table] // includes .plain
		}
	}
}

extension UINavigationBar: ThemeCSSAutoSelector {
	public var cssAutoSelectors: [ThemeCSSSelector] {
		return [.navigationBar]
	}
}

extension UIToolbar: ThemeCSSAutoSelector {
	public var cssAutoSelectors: [ThemeCSSSelector] {
		return [.toolbar]
	}
}

extension UITabBar: ThemeCSSAutoSelector {
	public var cssAutoSelectors: [ThemeCSSSelector] {
		return [.tabBar]
	}
}

extension UIProgressView: ThemeCSSAutoSelector {
	public var cssAutoSelectors: [ThemeCSSSelector] {
		return [.progress]
	}
}

extension UIButton: ThemeCSSAutoSelector {
	public var cssAutoSelectors: [ThemeCSSSelector] {
		if (self as? ThemeButton) != nil {
			return [.filled, .button]
		} else {
			return [.button]
		}
	}
}

extension UITextField: ThemeCSSAutoSelector {
	public var cssAutoSelectors: [ThemeCSSSelector] {
		if (self as? UISearchTextField) != nil {
			return [.textField, .searchField]
		} else {
			return [.textField]
		}
	}
}

extension UITextView: ThemeCSSAutoSelector {
	public var cssAutoSelectors: [ThemeCSSSelector] {
		return [.textView]
	}
}

extension UISegmentedControl: ThemeCSSAutoSelector {
	public var cssAutoSelectors: [ThemeCSSSelector] {
		return [.segmentedControl]
	}
}

extension UIDatePicker: ThemeCSSAutoSelector {
	public var cssAutoSelectors: [ThemeCSSSelector] {
		return [.datePicker]
	}
}

extension UISlider: ThemeCSSAutoSelector {
	public var cssAutoSelectors: [ThemeCSSSelector] {
		return [.slider]
	}
}

extension UIAlertController: ThemeCSSAutoSelector {
	public var cssAutoSelectors: [ThemeCSSSelector] {
		return [.alert]
	}
}
