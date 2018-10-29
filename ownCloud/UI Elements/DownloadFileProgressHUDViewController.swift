//
//  DownloadFileProgressHUDViewController.swift
//  ownCloud
//
//  Created by Pablo Carrascal on 29/10/2018.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

import UIKit

class DownloadFileProgressHUDViewController: UIViewController {

	private let PROGRESSVIEW_SIDES_CONSTRAINT_CONSTANT: CGFloat = 20
	private let PROGRESSVIEW_HEIGHT_CONSTRAINT_CONSTANT: CGFloat = 10
	private let CANCELBUTTON_TOP_ANCHOR_CONSTANT: CGFloat = 10
	private let CANCELBUTTON_HEIGHT_CONSTRAINT_CONSTANT: CGFloat = 40
	private let INFOLABEL_BOTTOM_ANCHOR_CONSTANT: CGFloat = 10
	private let INFOLABEL_HEIGHT_CONSTRAINT_CONSTANT: CGFloat = 20
	private let ROOT_VIEW_BACKGROUND_WHITE: CGFloat = 0.0
	private let ROOT_VIEW_BACKGROUND_ALPHA: CGFloat = 0.7

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

		view.backgroundColor = UIColor.init(white: ROOT_VIEW_BACKGROUND_WHITE, alpha: ROOT_VIEW_BACKGROUND_ALPHA)

		// Progress view
		progressView.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(progressView)
		NSLayoutConstraint.activate([
			progressView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
			progressView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
			progressView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: PROGRESSVIEW_SIDES_CONSTRAINT_CONSTANT),
			progressView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -PROGRESSVIEW_SIDES_CONSTRAINT_CONSTANT),
			progressView.heightAnchor.constraint(equalToConstant: PROGRESSVIEW_HEIGHT_CONSTRAINT_CONSTANT)
		])

		// Cancel button
		cancelButton.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(cancelButton)
		NSLayoutConstraint.activate([
			cancelButton.centerXAnchor.constraint(equalTo: progressView.centerXAnchor),
			cancelButton.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: CANCELBUTTON_TOP_ANCHOR_CONSTANT),
			cancelButton.leftAnchor.constraint(equalTo: progressView.leftAnchor),
			cancelButton.rightAnchor.constraint(equalTo: progressView.rightAnchor),
			cancelButton.heightAnchor.constraint(equalToConstant: CANCELBUTTON_HEIGHT_CONSTRAINT_CONSTANT)
		])
		cancelButton.setTitle("Cancel".localized, for: .normal)

		// Info label
		infoLabel.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(infoLabel)
		NSLayoutConstraint.activate([
			infoLabel.centerXAnchor.constraint(equalTo: progressView.centerXAnchor),
			infoLabel.bottomAnchor.constraint(equalTo: progressView.topAnchor, constant: -INFOLABEL_BOTTOM_ANCHOR_CONSTANT),
			infoLabel.leftAnchor.constraint(equalTo: progressView.leftAnchor),
			infoLabel.rightAnchor.constraint(equalTo: progressView.rightAnchor),
			infoLabel.heightAnchor.constraint(equalToConstant: INFOLABEL_HEIGHT_CONSTRAINT_CONSTANT)
		])

		infoLabel.text = "Downloading".localized
		infoLabel.textColor = .white
		infoLabel.textAlignment = .center

		progressView.progressTintColor = .white
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

	func present(on viewController: UIViewController) {
		viewController.present(self, animated: true)
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
