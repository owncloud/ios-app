//
//  CardPresentationController.swift
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
import Foundation
import UIKit

private enum CardPosition {
	case half
	case open

	var heightMultiplier: CGFloat {
		switch self {
		case .half: return 0.48
		case .open: return 0.9
		}
	}

	func origin() -> CGFloat {
		let window = UIApplication.shared.delegate!.window!!.bounds
			return window.height - (window.height * heightMultiplier)
	}
}

final class CardPresentationController: UIPresentationController {

	// MARK: - Instance Variables.
	private var cardPosition: CardPosition = .half

	private var cardAnimator: UIViewPropertyAnimator?
	private var cardPanGestureRecognizer = UIGestureRecognizer()

	private var dimmingView = UIView()
	private var dimmingViewGR = UIGestureRecognizer()

	private var windowFrame: CGRect {
		let window = UIApplication.shared.delegate!.window!!
		return window.bounds
	}

	private var disabledScrollingInViews : [UIScrollView] = []

	override var frameOfPresentedViewInContainerView: CGRect {

		var originX: CGFloat = 0
		var width: CGFloat = windowFrame.width

		if traitCollection.horizontalSizeClass == .compact && traitCollection.verticalSizeClass == .compact {
			originX = 50
			width = windowFrame.width - 100
		}

		let presentedOrigin = CGPoint(x: originX, y: cardPosition.origin())
		let presentedSize = CGSize(width: width, height: windowFrame.height + 40)
		let presentedFrame = CGRect(origin: presentedOrigin, size: presentedSize)
		return presentedFrame
	}

	// MARK: - Presentation
	override func presentationTransitionWillBegin() {
		if let containerView = containerView {
			containerView.insertSubview(dimmingView, at: 1)
			dimmingView.alpha = 0
			dimmingView.backgroundColor = .black
			dimmingView.frame = containerView.frame

			if let transitionCoordinator = self.presentingViewController.transitionCoordinator {
				transitionCoordinator.animate(alongsideTransition: { (_) in
					self.dimmingView.alpha = 0.5
				})
			}
		}
	}

	override func presentationTransitionDidEnd(_ completed: Bool) {
		cardAnimator = UIViewPropertyAnimator(duration: 0.6, dampingRatio: 0.8)
		cardAnimator?.isInterruptible = true
		cardPanGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(userDragged))
		cardPanGestureRecognizer.delegate = self
		cardPanGestureRecognizer.cancelsTouchesInView = true
		containerView?.addGestureRecognizer(cardPanGestureRecognizer)

		dimmingViewGR = UITapGestureRecognizer(target: self, action: #selector(dismissView))
		dimmingView.addGestureRecognizer(dimmingViewGR)
	}

	// MARK: - Dismissal
	override func dismissalTransitionWillBegin() {
		dimmingView.removeGestureRecognizer(dimmingViewGR)
		presentedView?.removeGestureRecognizer(cardPanGestureRecognizer)

		if let transitionCoordinator = self.presentingViewController.transitionCoordinator {
			transitionCoordinator.animate(alongsideTransition: { (_) in
				self.dimmingView.alpha = 0.0
			})
		}
	}

	override func containerViewWillLayoutSubviews() {
		presentedView?.frame = frameOfPresentedViewInContainerView
		dimmingView.frame = windowFrame
	}

	// MARK: - Card Gesture managers.
	@objc private func userDragged(_ gestureRecognizer: UIPanGestureRecognizer) {
		let originY = cardPosition.origin()
		let newOffset = originY + gestureRecognizer.translation(in: presentedView).y
		let velocity = gestureRecognizer.velocity(in: presentedView).y

		if newOffset >= 0 {
			switch gestureRecognizer.state {
			case .began, .changed:
				presentedView?.frame.origin.y = newOffset
			case .ended:
				animate(to: newOffset, with: velocity)
			default:
				()
			}
		} else {
			if gestureRecognizer.state == .ended {
				animate(to: newOffset, with: velocity)
			}
		}
	}

	private func animate(to offset: CGFloat, with velocity: CGFloat) {
		let distanceFromBottom = windowFrame.height - offset
		var nextPosition: CardPosition = .open

		switch velocity {
		case _ where velocity >= 2000:
			self.presentedViewController.dismiss(animated: true)
		case _ where velocity < 0:
			if distanceFromBottom > windowFrame.height * (CardPosition.open.heightMultiplier - 0.3) {
				nextPosition = .open
			} else if distanceFromBottom > windowFrame.height * (CardPosition.half.heightMultiplier - 0.1) {
				nextPosition = .half
			} else {
				self.presentedViewController.dismiss(animated: true)
			}

		case _ where velocity >= 0:
			if distanceFromBottom > windowFrame.height * (CardPosition.open.heightMultiplier - 0.1) {
				nextPosition = .open
			} else if distanceFromBottom > windowFrame.height * (CardPosition.half.heightMultiplier - 0.1) {
				nextPosition = .half
			} else {
				self.presentedViewController.dismiss(animated: true)
			}
		default:
			()

		}

		cardAnimator?.stopAnimation(true)
		cardAnimator?.addAnimations {
			self.presentedView?.frame.origin.y = nextPosition.origin()
		}
		self.cardPosition = nextPosition
		cardAnimator?.startAnimation()
	}

	@objc func dismissView() {
		self.presentedViewController.dismiss(animated: true)
	}
}

// MARK: - GestureRecognizer delegate.
extension CardPresentationController: UIGestureRecognizerDelegate {

	func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
		if gestureRecognizer == cardPanGestureRecognizer {
			if let otherScrollView = otherGestureRecognizer.view as? UIScrollView,
			   otherScrollView.isScrollEnabled {
				return true
			}
		}

		return false
	}

	func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
		let velocity = (cardPanGestureRecognizer as? UIPanGestureRecognizer)?.velocity(in: gestureRecognizer.view)

		var targetView = presentedView?.hitTest(gestureRecognizer.location(in: presentedView), with: nil)

		var scrollView : UIScrollView?

		while targetView != nil, targetView != containerView, scrollView == nil {
			if let foundScrollView = targetView as? UIScrollView {
				scrollView = foundScrollView
				break
			} else {
				targetView = targetView?.superview
			}
		}

		if scrollView != nil,
		   let contentOffsetY = scrollView?.contentOffset.y,
		   let hasVelocity = velocity,
		   cardPosition == .open {
		   	if contentOffsetY > 0, hasVelocity.y > 0 {
				return false
			}

		   	if hasVelocity.y < 0 {
				return false
			}
		}

		return true
	}
}
