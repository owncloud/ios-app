//
//  CardTransitionAnimator.swift
//  ownCloud
//
//  Created by Pablo Carrascal on 25/07/2018.
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

final class CardTransitionDelegate: NSObject, UIViewControllerTransitioningDelegate {
	private weak var viewControllerToPresent: UIViewController?
	var withHandle : Bool
	var dismissable : Bool

	init(viewControllerToPresent: UIViewController, presentingViewController: UIViewController, withHandle: Bool = true, dismissable : Bool = true) {
		self.withHandle = withHandle
		self.dismissable = dismissable
		self.viewControllerToPresent = viewControllerToPresent

		super.init()
	}

	func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
		return CardPresentationController(presentedViewController: presented, presenting: presenting, withHandle: withHandle, dismissable: dismissable)
	}
}
