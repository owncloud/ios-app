//
//  AppStateActionGoToPersonalFolder.swift
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

public class AppStateActionGoToPersonalFolder: AppStateAction {
	public init(children: [AppStateAction]? = nil) {
		super.init(with: children)
	}

	override open class var supportsSecureCoding: Bool {
		return true
	}

	public required init?(coder: NSCoder) {
		super.init(coder: coder)
	}

	var drivesSubscription: OCDataSourceSubscription?

	override public func perform(in clientContext: ClientContext, completion: @escaping AppStateAction.Completion) {
		if let core = clientContext.core {
			if core.useDrives {
				if let personalDrive = core.drives.first(where: { drive in
					drive.specialType == .personal
				}) {
					open(location: personalDrive.rootLocation, in: clientContext, completion: completion)
				} else {
					completion(NSError(ocError: .itemNotFound), clientContext)
				}
			} else {
				open(location: OCLocation.legacyRoot, in: clientContext, completion: completion)
			}
		}
	}

	func open(location: OCLocation, in clientContext: ClientContext, completion: @escaping AppStateAction.Completion) {
		OnMainThread {
			_ = location.openItem(from: nil, with: clientContext, animated: false, pushViewController: true, completion: { _ in
				completion(nil, clientContext)
			})
		}
	}
}

public extension AppStateAction {
	static func goToPersonalFolder(children: [AppStateAction]? = nil) -> AppStateActionGoToPersonalFolder {
		return AppStateActionGoToPersonalFolder(children: children)
	}
}
