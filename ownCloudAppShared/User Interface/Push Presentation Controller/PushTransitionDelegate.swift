//
//  PushTransitionDelegate.swift
//  ownCloud
//
//  Created by Felix Schwarz on 22.04.19.
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

final public class PushTransitionDelegate: NSObject, UIViewControllerTransitioningDelegate {
	var transitionRecovery : PushTransitionRecovery?

	public init(with transitionRecovery: PushTransitionRecovery? = nil) {
		self.transitionRecovery = transitionRecovery
		super.init()
	}

	@objc private func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
		return PushPresentationController(presentedViewController: presented, presenting: presenting)
	}

	@objc private func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		return PushTransition(dismiss: false)
	}

	@objc private func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		return PushTransition(dismiss: true, transitionRecovery: transitionRecovery)
	}
}
