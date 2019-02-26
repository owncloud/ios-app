//
//  UINavigationController+Extension.swift
//  ownCloud
//
//  Created by Matthias Hühne on 25.01.19.
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

import UIKit

extension UINavigationController {
	func pushViewController(viewController: UIViewController, animated: Bool, completion: @escaping () -> Void) {
		pushViewController(viewController, animated: animated)

		if let coordinator = transitionCoordinator, animated {
			coordinator.animate(alongsideTransition: nil) { _ in
				completion()
			}
		} else {
			completion()
		}
	}

	func popViewController(animated: Bool, completion: @escaping () -> Void) {
		popViewController(animated: animated)

		if let coordinator = transitionCoordinator, animated {
			coordinator.animate(alongsideTransition: nil) { _ in
				completion()
			}
		} else {
			completion()
		}
	}
}
