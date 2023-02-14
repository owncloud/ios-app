//
//  AppStateActionRevealItem.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 14.02.23.
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
import ownCloudSDK

public class AppStateActionRevealItem: AppStateAction {
	var item: OCItem?

	public init(item: OCItem, children: [AppStateAction]? = nil) {
		super.init(with: children)
		self.item = item
	}

	override open class var supportsSecureCoding: Bool {
		return true
	}

	public required init?(coder: NSCoder) {
		item = coder.decodeObject(of: OCItem.self, forKey: "item")
		super.init(coder: coder)
	}

	override public func encode(with coder: NSCoder) {
		super.encode(with: coder)
		coder.encode(item, forKey: "item")
	}

	override public func perform(in clientContext: ClientContext, completion: @escaping AppStateAction.Completion) {
		if let item {
			_ = item.revealItem(from: nil, with: clientContext, animated: false, pushViewController: true, completion: { success in
				completion(nil, clientContext)
			})
		} else {
			completion(NSError.init(ocError: .unknown), clientContext)
		}
	}
}

public extension AppStateAction {
	static func reveal(item: OCItem, children: [AppStateAction]? = nil) -> AppStateActionRevealItem {
		return AppStateActionRevealItem(item: item, children: children)
	}
}
