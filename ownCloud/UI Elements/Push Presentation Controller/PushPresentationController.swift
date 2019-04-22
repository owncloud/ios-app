//
//  PushPresentationController.swift
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

class PushPresentationController: UIPresentationController {

	override func presentationTransitionWillBegin() {
		if let transitionCoordinator = self.presentingViewController.transitionCoordinator {
			self.presentingViewController.view.alpha = 1.0
			self.presentedViewController.view.alpha = 1.0

			transitionCoordinator.animate(alongsideTransition: { (_) in
				self.presentingViewController.view.alpha = 0.5
				self.presentedViewController.view.alpha = 1.0
			})
		}
	}

	override func dismissalTransitionWillBegin() {
		if let transitionCoordinator = self.presentingViewController.transitionCoordinator {
			self.presentingViewController.view.alpha = 0.5
			self.presentedViewController.view.alpha = 1.0

			transitionCoordinator.animate(alongsideTransition: { (_) in
				self.presentingViewController.view.alpha = 1.0
				self.presentedViewController.view.alpha = 1.0
			})
		}
	}
}
