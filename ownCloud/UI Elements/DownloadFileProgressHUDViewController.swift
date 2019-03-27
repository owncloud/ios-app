//
//  DownloadFileProgressHUDViewController.swift
//  ownCloud
//
//  Created by Pablo Carrascal on 29/10/2018.
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

class DownloadFileProgressHUDViewController: UIViewController {

	private let progressViewSidesConstraintConstant: CGFloat = 20
	private let progressViewWidthConstraintConstant: CGFloat = 280
	private let cancelButtonTopAnchor: CGFloat = 10
	private let cancelButtonHeightConstraintConstant: CGFloat = 40
	private let infoLabelBottomAnchor: CGFloat = 10
	private let infoLabelHeightConstraintConstant: CGFloat = 20
	private let rootViewBackgroundWhite: CGFloat = 0.0
	private let rootViewBackgroundAlpha: CGFloat = 0.7

	// MARK: - Instance variables.
	private var progressView: UIProgressView {
		didSet {
			if let observedProgress = progressView.observedProgress {
				if observedProgress.isFinished {
					self.dismiss(animated: true, completion: completion)
				}
			}
		}
	}

	private var cancelButton: ThemeButton
	private var infoLabel: UILabel
	private var transitionAnimator = ProgressHUDViewControllerAnimator()
	private var completion: (() -> Void)?

	// MARK: - Init & deinit
	init(with completionHandler: (() -> Void)? = nil) {
		progressView = UIProgressView(progressViewStyle: .bar)
		cancelButton = ThemeButton()
		infoLabel = UILabel()
		completion = completionHandler

		super.init(nibName: nil, bundle: nil)

		self.modalPresentationStyle = .overFullScreen
		self.transitioningDelegate = transitionAnimator

		Theme.shared.register(client: self)
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	deinit {
		Theme.shared.unregister(client: self)

		if let progress = progressView.observedProgress, !progress.isFinished {
			progress.cancel()
		}
	}

	override func loadView() {
		super.loadView()

		view.backgroundColor = UIColor.init(white: rootViewBackgroundWhite, alpha: rootViewBackgroundAlpha)

		// Progress view
		progressView.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(progressView)
		NSLayoutConstraint.activate([
			progressView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
			progressView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
			progressView.leftAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.leftAnchor, constant: progressViewSidesConstraintConstant),
			progressView.rightAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.rightAnchor, constant: progressViewSidesConstraintConstant),
			progressView.widthAnchor.constraint(lessThanOrEqualToConstant: progressViewWidthConstraintConstant)
		])

		// Cancel button
		cancelButton.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(cancelButton)
		NSLayoutConstraint.activate([
			cancelButton.centerXAnchor.constraint(equalTo: progressView.centerXAnchor),
			cancelButton.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: cancelButtonTopAnchor),
			cancelButton.leftAnchor.constraint(equalTo: progressView.leftAnchor),
			cancelButton.rightAnchor.constraint(equalTo: progressView.rightAnchor),
			cancelButton.heightAnchor.constraint(equalToConstant: cancelButtonHeightConstraintConstant)
		])
		cancelButton.setTitle("Cancel".localized, for: .normal)

		// Info label
		infoLabel.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(infoLabel)
		NSLayoutConstraint.activate([
			infoLabel.centerXAnchor.constraint(equalTo: progressView.centerXAnchor),
			infoLabel.bottomAnchor.constraint(equalTo: progressView.topAnchor, constant: -infoLabelBottomAnchor),
			infoLabel.leftAnchor.constraint(equalTo: progressView.leftAnchor),
			infoLabel.rightAnchor.constraint(equalTo: progressView.rightAnchor),
			infoLabel.heightAnchor.constraint(equalToConstant: infoLabelHeightConstraintConstant)
		])

		infoLabel.text = "Downloading".localized
		infoLabel.textColor = .white
		infoLabel.textAlignment = .center

		progressView.progressTintColor = .white
		progressView.trackTintColor = .lightGray
	}

    override func viewDidLoad() {
        super.viewDidLoad()

		cancelButton.addTarget(self, action: #selector(cancelButtonPressed), for: .touchUpInside)
    }

	@objc private func cancelButtonPressed() {
		guard let observedProgress = progressView.observedProgress, observedProgress.isCancellable else {
			return
		}

		observedProgress.cancel()
		dismiss(animated: true, completion: completion)
	}

}

// MARK: - Public API
extension DownloadFileProgressHUDViewController {

	func present(on viewController: UIViewController, completion: (() -> Void)? = nil) {
		viewController.present(self, animated: true, completion: completion)
	}

	func attach(progress: Progress) {
		progressView.observedProgress = progress
	}

}

// MARK: - Theme support
extension DownloadFileProgressHUDViewController: Themeable {
	func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		cancelButton.applyThemeCollection(collection)
	}
}

internal class DownloadFileProgressHUDViewControllerAnimator : NSObject, UIViewControllerTransitioningDelegate, UIViewControllerAnimatedTransitioning {
	private let ANIMATION_DURATION: Double = 0.4
	private let AFFINE_TRANSFORM_SCALE: CGAffineTransform = CGAffineTransform(scaleX: 0.6, y: 0.6)

	var isDismissing : Bool = false

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
		return ANIMATION_DURATION
	}

	func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
		let containerView = transitionContext.containerView

		if isDismissing {
			if let fromView = transitionContext.view(forKey: .from) {
				let fromViewController = transitionContext.viewController(forKey: .from)
				let hudViewController = fromViewController as? DownloadFileProgressHUDViewController

				if fromViewController != nil {
					fromView.frame = transitionContext.initialFrame(for: fromViewController!)
				}

				containerView.addSubview(fromView)

				UIView.animate(withDuration: ANIMATION_DURATION, animations: {
					fromView.alpha = 0
					hudViewController?.view.transform = self.AFFINE_TRANSFORM_SCALE
				}, completion: { (_) in
					transitionContext.completeTransition(true)
				})
			}
		} else {
			if let toView = transitionContext.view(forKey: .to) {
				let toViewController = transitionContext.viewController(forKey: .to)
				let hudViewController = toViewController as? DownloadFileProgressHUDViewController

				if toViewController != nil {
					toView.frame = transitionContext.finalFrame(for: toViewController!)
				}

				containerView.addSubview(toView)

				toView.alpha = 0
				hudViewController?.view.transform = self.AFFINE_TRANSFORM_SCALE

				UIView.animate(withDuration: ANIMATION_DURATION, animations: {
					toView.alpha = 1
					hudViewController?.view.transform = .identity
				}, completion: { (_) in
					transitionContext.completeTransition(true)
				})
			}
		}
	}
}
