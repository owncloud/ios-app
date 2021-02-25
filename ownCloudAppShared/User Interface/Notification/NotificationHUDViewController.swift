//
//  NotificationHUDViewController.swift
//  ownCloud
//
//  Created by Matthias Hühne on 27.04.20.
//  Copyright © 2020 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2020, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import UIKit

open class NotificationHUDViewController: UIViewController {

	typealias NotificationHUDDismissCompletionHandler = (() -> Void)
	var completionHandler : NotificationHUDDismissCompletionHandler?
	var onViewController : UIViewController
	var notificationContainer : UIView?
	var blurEffectView : UIVisualEffectView?
	var titleLabel : UILabel?
	var subtitleLabel : UILabel?
	var transitionAnimator = NotificationHUDViewControllerAnimator()
	var presenting : Bool = false
	var actionWaitGroup = DispatchGroup()
	var tapGestureRecognizer : UITapGestureRecognizer!
	let dismissalTimeInterval = 3.0

	public init(on viewController: UIViewController, title: String, subtitle: String, completion: (() -> Void)? = nil) {
		self.onViewController = viewController
		super.init(nibName: nil, bundle: nil)

		completionHandler = completion
		self.modalPresentationStyle = .overCurrentContext
		self.transitioningDelegate = transitionAnimator
		self.tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.dismissOnTap))
		self.view.addGestureRecognizer(self.tapGestureRecognizer)

		self.present(on: onViewController, title: title, subtitle: subtitle)

	}

	required public init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	func updateLabels(with title: String?, subtitle: String?) {
		titleLabel?.text = title
		subtitleLabel?.text = subtitle
	}

	func present(on viewController: UIViewController?, title: String, subtitle: String) {
		setupView()
		if self.view != nil {
			self.updateLabels(with: title, subtitle: subtitle)
		}

		if viewController != nil {
			if !presenting {
				presenting = true

				actionWaitGroup.enter()

				viewController?.present(self, animated: true) {

					OnMainThread(async: true, after: self.dismissalTimeInterval, inline: false) {
						self.dismiss {
							self.completionHandler?()
						}
					}
					self.actionWaitGroup.leave()
				}
			}
		}

	}

	func setupView() {
		notificationContainer = UIView()
		notificationContainer?.translatesAutoresizingMaskIntoConstraints = false
		notificationContainer?.layer.cornerRadius = 10
		notificationContainer?.layer.shadowColor = UIColor.black.cgColor
		notificationContainer?.layer.shadowOpacity = 0.3
		notificationContainer?.layer.shadowOffset = .zero
		notificationContainer?.layer.shadowRadius = 10

		let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.light)
		blurEffectView = UIVisualEffectView(effect: blurEffect)
		blurEffectView?.layer.cornerRadius = 10
		blurEffectView?.clipsToBounds = true
		blurEffectView?.translatesAutoresizingMaskIntoConstraints = false

		notificationContainer?.addSubview(blurEffectView!)

		titleLabel = UILabel()
		titleLabel?.translatesAutoresizingMaskIntoConstraints = false
		titleLabel?.numberOfLines = 0
		titleLabel?.textColor = .black
		titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
		titleLabel?.textAlignment = .left

		notificationContainer?.addSubview(titleLabel!)

		subtitleLabel = UILabel()
		subtitleLabel?.translatesAutoresizingMaskIntoConstraints = false
		subtitleLabel?.numberOfLines = 0
		subtitleLabel?.textColor = .black
		subtitleLabel?.font = UIFont.systemFont(ofSize: 16)
		subtitleLabel?.textAlignment = .left

		notificationContainer?.addSubview(subtitleLabel!)

		blurEffectView?.heightAnchor.constraint(equalTo: notificationContainer!.heightAnchor).isActive = true
		blurEffectView?.widthAnchor.constraint(equalTo: notificationContainer!.widthAnchor).isActive = true

		titleLabel?.leftAnchor.constraint(equalTo: (notificationContainer?.leftAnchor)!, constant: 10).isActive = true
		titleLabel?.rightAnchor.constraint(equalTo: (notificationContainer?.rightAnchor)!, constant: -10).isActive = true
		titleLabel?.topAnchor.constraint(equalTo: (notificationContainer?.topAnchor)!, constant: 10).isActive = true
		titleLabel?.bottomAnchor.constraint(equalTo: (subtitleLabel?.topAnchor)!, constant: 0).isActive = true

		subtitleLabel?.leftAnchor.constraint(equalTo: (notificationContainer?.leftAnchor)!, constant: 10).isActive = true
		subtitleLabel?.rightAnchor.constraint(equalTo: (notificationContainer?.rightAnchor)!, constant: -10).isActive = true
		subtitleLabel?.bottomAnchor.constraint(equalTo: (notificationContainer?.bottomAnchor)!, constant: -10).isActive = true

		self.view.addSubview(notificationContainer!)

		notificationContainer?.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10).isActive = true
		notificationContainer?.bottomAnchor.constraint(equalTo: subtitleLabel!.bottomAnchor, constant: 10).isActive = true
		notificationContainer?.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 10).isActive = true
		notificationContainer?.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -10).isActive = true
	}

	@objc func dismissOnTap() {
		self.dismiss {
			self.completionHandler?()
		}
	}

	func dismiss(completion: (() -> Void)? = nil) {
		if presenting {
			DispatchQueue.global(qos: .userInitiated).async {
				self.actionWaitGroup.wait()

				OnMainThread {
					self.presentingViewController?.dismiss(animated: true, completion: { [weak self] in
						self?.presenting = false
						completion?()
					})
				}
			}
		}
	}
}

internal class NotificationHUDViewControllerAnimator : NSObject, UIViewControllerTransitioningDelegate, UIViewControllerAnimatedTransitioning {
	var isDismissing : Bool = false
	let duration = 0.4

	// MARK: - UIViewControllerTransitioningDelegate
	func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		isDismissing = true
		return self
	}

	func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		isDismissing = false
		return self
	}

	// MARK: - UIViewControllerAnimatedTransitioning
	func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
		return duration
	}

	func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
		let containerView = transitionContext.containerView

		if isDismissing {
			if let fromView = transitionContext.view(forKey: .from) {
				let fromViewController = transitionContext.viewController(forKey: .from)

				if fromViewController != nil {
					fromView.frame = transitionContext.initialFrame(for: fromViewController!)
				}

				containerView.addSubview(fromView)

				UIView.animate(withDuration: duration, animations: {
					fromView.alpha = 0
					fromView.frame.origin.y = -100
				}, completion: { (_) in
					transitionContext.completeTransition(true)
				})
			}
		} else {
			if let toView = transitionContext.view(forKey: .to) {
				let toViewController = transitionContext.viewController(forKey: .to)

				if toViewController != nil {
					toView.frame = transitionContext.finalFrame(for: toViewController!)
				}

				containerView.addSubview(toView)

				toView.alpha = 0
				toView.frame.origin.y = -100

				UIView.animate(withDuration: duration, animations: {
					toView.alpha = 1
					toView.frame.origin.y = 0
				}, completion: { (_) in
					transitionContext.completeTransition(true)
				})
			}
		}
	}
}
