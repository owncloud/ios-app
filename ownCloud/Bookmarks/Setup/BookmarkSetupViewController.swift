//
//  BookmarkSetupViewController.swift
//  ownCloud
//
//  Created by Felix Schwarz on 05.09.23.
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
import ownCloudApp
import ownCloudAppShared

class BookmarkSetupViewController: EmbeddingViewController, BookmarkComposerDelegate {
	var composer: BookmarkComposer?
	var configuration: BookmarkComposerConfiguration

	var stepControllerByStep : [BookmarkComposer.Step : UIViewController] = [:]

	var visibleContentContainerView: UIView = UIView()

	var helpMessageView: ComposedMessageView?

	private var centerHelperView: UIView = UIView()
	private var logoView: UIView?

	init(configuration: BookmarkComposerConfiguration, cancelHandler: CancelHandler? = nil, doneHandler: DoneHandler? = nil) {
		self.configuration = configuration

		super.init(nibName: nil, bundle: nil)

		self.doneHandler = doneHandler
		self.cancelHandler = cancelHandler

		composer = BookmarkComposer(configuration: configuration, delegate: self)
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func loadView() {
		let contentView = UIView()
		contentView.translatesAutoresizingMaskIntoConstraints = false

		visibleContentContainerView.translatesAutoresizingMaskIntoConstraints = false

		let brandBackground = BrandView(showBackground: true, showLogo: false, roundedCorners: false, assetSuffix: .setup)

		contentView.embed(toFillWith: brandBackground)
		contentView.embed(toFillWith: visibleContentContainerView, enclosingAnchors: contentView.safeAreaWithKeyboardAnchorSet)

		centerHelperView.translatesAutoresizingMaskIntoConstraints = false
		contentView.addSubview(centerHelperView)

		self.cssSelectors = [.modal, .accountSetup]

		// Add logo
		if navigationController == nil {
			let deviceScreenHeight = UIScreen.main.bounds.height
			let logoMaxHeight = deviceScreenHeight < 800 ? (deviceScreenHeight < 600 ? 48 : 96) : 128
			let maxLogoSize = CGSize(width: 256, height: logoMaxHeight)
			logoView = BrandView(showBackground: false, showLogo: true, logoMaxSize: maxLogoSize, fitToLogo: true, roundedCorners: false, assetSuffix: .setup)
		}

		if let logoView {
			contentView.addSubview(logoView)

			NSLayoutConstraint.activate([
				centerHelperView.leadingAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.leadingAnchor).with(priority: .defaultLow),
				centerHelperView.trailingAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.trailingAnchor).with(priority: .defaultLow),

				centerHelperView.topAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.topAnchor).with(priority: .defaultLow),
				centerHelperView.heightAnchor.constraint(greaterThanOrEqualToConstant: 1),

				logoView.topAnchor.constraint(equalTo: centerHelperView.topAnchor),
				logoView.centerXAnchor.constraint(equalTo: centerHelperView.centerXAnchor)
			])
		}

		// Add cancel button
		if cancelHandler != nil {
			if navigationController != nil {
				navigationItem.rightBarButtonItem = UIBarButtonItem(systemItem: .cancel, primaryAction: UIAction(handler: { [weak self] action in
					self?.cancel()
				}))
			} else {
				let cancelButton = ThemeCSSButton(withSelectors: [.cancel])
				cancelButton.translatesAutoresizingMaskIntoConstraints = false
				cancelButton.setTitle(OCLocalizedString("Cancel", nil), for: .normal)
				cancelButton.addAction(UIAction(handler: { [weak self] _ in
					self?.cancel()
				}), for: .primaryActionTriggered)

				contentView.addSubview(cancelButton)

				NSLayoutConstraint.activate([
					cancelButton.trailingAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.trailingAnchor, constant: -20),
					cancelButton.topAnchor.constraint(equalTo:  contentView.safeAreaLayoutGuide.topAnchor, constant: 20)
				])
			}
		}

		// Add help message
		if configuration.helpButtonURL != nil || configuration.helpMessage != nil {
			var helpElements: [ComposedMessageElement] = []

			if let helpButtonURL = configuration.helpButtonURL {
				helpElements += [
					.button(configuration.helpButtonLabel ?? OCLocalizedString("Open help page", nil), action: UIAction(handler: { action in
						UIApplication.shared.open(helpButtonURL)
					}), image: UIImage(systemName: "questionmark.circle"))
				]
			}

			if let helpMessage = configuration.helpMessage {
				helpElements += [
					.subtitle(helpMessage, alignment: .centered)
				]
			}

			let helpMessageView = ComposedMessageView(elements: helpElements)
			helpMessageView.cssSelectors = [ .help ]
			helpMessageView.elementInsets = NSDirectionalEdgeInsets(top: 0, leading: 15, bottom: 10, trailing: 15)
			helpMessageView.setContentHuggingPriority(.required, for: .vertical)

			contentView.addSubview(helpMessageView)

			NSLayoutConstraint.activate([
				helpMessageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
				helpMessageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
				helpMessageView.bottomAnchor.constraint(equalTo: contentView.keyboardLayoutGuide.topAnchor)
			])
		}

		view = contentView
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		composer?.updateState()
	}

	override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
		return [.portrait, .portraitUpsideDown]
	}

	override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
		return .portrait
	}

	override var preferredStatusBarStyle : UIStatusBarStyle {
		return Theme.shared.activeCollection.css.getStatusBarStyle(for: self) ?? .default
	}

	// MARK: - Steps view controller and layout
	func viewController(for step: BookmarkComposer.Step) -> UIViewController? {
		if let stepViewController = stepControllerByStep[step] {
			return stepViewController
		}

		var stepViewController: UIViewController?

		switch step {
			case .intro:
				stepViewController = BookmarkSetupStepIntroViewController(with: self, step: step)

			case .serverURL(urlString: _):
				stepViewController = BookmarkSetupStepEnterURLViewController(with: self, step: step)

			case .enterUsername:
				stepViewController = BookmarkSetupStepEnterUsernameViewController(with: self, step: step)

			case .authenticate(withCredentials: _, username: _, password: _):
				stepViewController = BookmarkSetupStepAuthenticateViewController(with: self, step: step)

			case .chooseServer(fromInstances: _):
				// Do not support server choice for now (also see present(composer:step:)
				break

			case .infinitePropfind:
				stepViewController = BookmarkSetupStepPrepopulateViewController(with: self, step: step)

			case .completed:
				if composer?.configuration.nameEditable == true {
					stepViewController = BookmarkSetupStepFinishedViewController(with: self, step: step)
				} else {
					let bookmark = composer?.addBookmark()
					done(bookmark: bookmark)
				}
		}

		(stepViewController as? BookmarkSetupStepViewController)?.setupViewController = self

		if (stepViewController as? BookmarkSetupStepViewController)?.cacheViewController == true {
			stepControllerByStep[step] = stepViewController
		}

		return stepViewController
	}

	override func constraintsForEmbedding(contentViewController: UIViewController) -> [NSLayoutConstraint] {
		let contentViewControllerView = contentViewController.view!
		var constraints: [NSLayoutConstraint]

		if let logoView {
			constraints = visibleContentContainerView.embed(centered: centerHelperView, minimumInsets: NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20), constraintsOnly: true)

			constraints += [
				contentViewControllerView.topAnchor.constraint(equalTo: logoView.safeAreaLayoutGuide.bottomAnchor, constant: 10),
				contentViewControllerView.bottomAnchor.constraint(equalTo: centerHelperView.safeAreaLayoutGuide.bottomAnchor),
				contentViewControllerView.leadingAnchor.constraint(equalTo: centerHelperView.safeAreaLayoutGuide.leadingAnchor),
				contentViewControllerView.trailingAnchor.constraint(equalTo: centerHelperView.safeAreaLayoutGuide.trailingAnchor)
			]
		} else {
			constraints = visibleContentContainerView.embed(centered: contentViewControllerView, minimumInsets: NSDirectionalEdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20), constraintsOnly: true)
		}

		return constraints
	}

	// MARK: - HUD message
	var hudMessageView: UIView? {
		willSet {
			hudMessageView?.removeFromSuperview()

			if newValue == nil {
				contentViewController?.view.isHidden = false
				logoView?.isHidden = false
			}
		}

		didSet {
			if let hudMessageView {
				visibleContentContainerView.addSubview(hudMessageView)
				NSLayoutConstraint.activate([
					hudMessageView.centerYAnchor.constraint(equalTo: visibleContentContainerView.centerYAnchor),
					hudMessageView.centerXAnchor.constraint(equalTo: visibleContentContainerView.safeAreaLayoutGuide.centerXAnchor),
					hudMessageView.leadingAnchor.constraint(greaterThanOrEqualTo: visibleContentContainerView.safeAreaLayoutGuide.leadingAnchor, constant: 20),
					hudMessageView.trailingAnchor.constraint(lessThanOrEqualTo: visibleContentContainerView.safeAreaLayoutGuide.trailingAnchor, constant: -20)
				])
				contentViewController?.view.isHidden = true
				logoView?.isHidden = true
			}
		}
	}

	// MARK: - History support
	var canGoBack: Bool {
		return composer?.canUndoLastStep ?? false
	}

	func goBack() {
		if canGoBack {
			composer?.undoLastStep()
		}
	}

	// MARK: - Dismiss
	typealias CancelHandler = () -> Void
	var cancelHandler: CancelHandler?

	func cancel() {
		cancelHandler?()
		cancelHandler = nil
	}

	typealias DoneHandler = (_ bookmark: OCBookmark?) -> Void
	var doneHandler: DoneHandler?

	func done(bookmark: OCBookmark?) {
		doneHandler?(bookmark)
		doneHandler = nil
	}

	// MARK: - Bookmark Composer Delegate
	func present(composer: BookmarkComposer, step: BookmarkComposer.Step) {
		if case let .chooseServer(fromInstances: instances) = step {
			// Do not support server choice for now (also see viewController(for:)
			// Pick first server from list
			composer.chooseServer(instance: instances.first!, completion: { [weak self] error, issue, issueCompletionHandler in
				guard let self, let composer = self.composer else { return }
				self.present(composer: composer, error: error, issue: issue, issueCompletionHandler: issueCompletionHandler)
			})
		} else {
			OnMainThread {
				let stepViewController = self.viewController(for: step)
				stepViewController?.view.widthAnchor.constraint(greaterThanOrEqualToConstant: 400).with(priority: .defaultHigh).isActive = true
				self.contentViewController = stepViewController
			}
		}
	}

	func present(composer: BookmarkComposer, hudMessage: String?) {
		OnMainThread {
			if let hudMessage {
				let indeterminateProgress = Progress.indeterminate()
				indeterminateProgress.isCancellable = false

				let messageView = ComposedMessageView.infoBox(additionalElements: [
					.progressCircle(with: indeterminateProgress, alignment: .centered),
					.spacing(10),
					.text(hudMessage, style: .system(textStyle: .headline, weight: .bold), alignment: .centered)
				])
				messageView.cssSelectors = [ .step ]

				messageView.widthAnchor.constraint(greaterThanOrEqualToConstant: 400).with(priority: .defaultHigh).isActive = true

				self.hudMessageView = messageView
			} else {
				self.hudMessageView = nil
			}
		}
	}

	func present(composer: BookmarkComposer, error: Error?, issue: OCIssue?, issueCompletionHandler: IssuesCardViewController.CompletionHandler?) {
		OnMainThread {
			var presentIssue: OCIssue? = issue
			var completionHandler = issueCompletionHandler

			if presentIssue == nil, let error {
				presentIssue = OCIssue(forError: error, level: .warning)
			}

			if completionHandler == nil {
				completionHandler = { [weak presentIssue] (response) in
					switch response {
						case .cancel:
							presentIssue?.reject()

						case .approve:
							presentIssue?.approve()

						case .dismiss: break
					}
				}
			}

			if let presentIssue, let completionHandler {
				let displayIssues = presentIssue.prepareForDisplay()

				IssuesCardViewController.present(on: self, issue: presentIssue, displayIssues: displayIssues, completion: completionHandler)
			}
		}
	}
}

extension ThemeCSSSelector {
}
