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

	var headerTitle: String?

	var helpMessageView: ComposedMessageView?

	init(configuration: BookmarkComposerConfiguration, headerTitle: String? = nil, cancelHandler: CancelHandler? = nil, doneHandler: DoneHandler? = nil) {
		self.configuration = configuration

		super.init(nibName: nil, bundle: nil)

		self.headerTitle = headerTitle
		self.doneHandler = doneHandler
		self.cancelHandler = cancelHandler

		composer = BookmarkComposer(configuration: configuration, delegate: self)
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func loadView() {
		let contentView = UIView()

		visibleContentContainerView.translatesAutoresizingMaskIntoConstraints = false

		let backgroundView = ThemeCSSView(withSelectors: [.background])
		backgroundView.translatesAutoresizingMaskIntoConstraints = false

		contentView.embed(toFillWith: backgroundView)
		contentView.embed(toFillWith: visibleContentContainerView, enclosingAnchors: contentView.safeAreaWithKeyboardAnchorSet)

		self.cssSelectors = [.modal, .accountSetup]

		// Add login background image
		if let image = Branding.shared.brandedImageNamed(.loginBackground) {
			let backgroundImageView = UIImageView(image: image)
			backgroundImageView.contentMode = .scaleAspectFill
			backgroundView.embed(toFillWith: backgroundImageView)
		}

		// Add brand title
		let logoImage = UIImage(named: "branding-login-logo")
		let logoImageView = UIImageView(image: logoImage)
		logoImageView.cssSelector = .icon
		logoImageView.accessibilityLabel = VendorServices.shared.appName
		logoImageView.contentMode = .scaleAspectFit
		logoImageView.translatesAutoresizingMaskIntoConstraints = false

		// Add cancel button
		if cancelHandler != nil {
			let navigationView = UINavigationBar()
			navigationView.translatesAutoresizingMaskIntoConstraints = false
			
			let cancelBarButton = UIBarButtonItem(systemItem: .cancel, primaryAction: UIAction(handler: { [weak self] action in
				self?.cancel()
			}))
			let navigationItem = UINavigationItem(title: headerTitle ?? Branding.shared.appDisplayName)
			navigationItem.rightBarButtonItem = cancelBarButton
			navigationView.setItems([navigationItem], animated: false)
			
			contentView.addSubview(navigationView)
			contentView.addSubview(logoImageView)
			
			NSLayoutConstraint.activate([
				navigationView.topAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.topAnchor),
				navigationView.leadingAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.leadingAnchor),
				navigationView.trailingAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.trailingAnchor),
				
				logoImageView.widthAnchor.constraint(equalToConstant: 128),
				logoImageView.heightAnchor.constraint(equalToConstant: 128),
				logoImageView.topAnchor.constraint(equalTo: navigationView.safeAreaLayoutGuide.bottomAnchor, constant: 20.0),
				logoImageView.centerXAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.centerXAnchor)
			])
		} else {
			var title = headerTitle
			if !Branding.shared.isBranded, title == "" {
				title = Branding.shared.appDisplayName
			}
			
			let logoTitle = ThemeCSSLabel(withSelectors: [.title])
			logoTitle.translatesAutoresizingMaskIntoConstraints = false
			logoTitle.font = .preferredFont(forTextStyle: .title3, with: .bold)
			logoTitle.text = title
			logoTitle.textAlignment = .center
			
			let logoContainerView = UIView()
			logoContainerView.translatesAutoresizingMaskIntoConstraints = false
			logoContainerView.cssSelector = .header
			logoContainerView.addSubview(logoTitle)
			logoContainerView.addSubview(logoImageView)
			
			logoContainerView.embedHorizontally(views: [logoTitle], insets: NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)) { _, _ in
				return 10
			}
			
			contentView.addSubview(logoContainerView)
			logoContainerView.addSubview(logoImageView)
			
			NSLayoutConstraint.activate([
				logoContainerView.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.safeAreaLayoutGuide.leadingAnchor),
				logoContainerView.trailingAnchor.constraint(lessThanOrEqualTo: contentView.safeAreaLayoutGuide.trailingAnchor),
				logoContainerView.centerXAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.centerXAnchor).with(priority: .defaultHigh),
				logoContainerView.topAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.topAnchor, constant: 20),
				logoContainerView.heightAnchor.constraint(equalToConstant: 40),
				
				logoImageView.widthAnchor.constraint(equalToConstant: 128),
				logoImageView.heightAnchor.constraint(equalToConstant: 128),
				logoImageView.topAnchor.constraint(equalTo: logoTitle.safeAreaLayoutGuide.bottomAnchor, constant: 20.0),
				logoImageView.centerXAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.centerXAnchor)
			])
		}
			
		// Add help message
		if configuration.helpButtonURL != nil || configuration.helpMessage != nil {
			var helpElements: [ComposedMessageElement] = [
				// .title("Help".localized)
			]

			if let helpButtonURL = configuration.helpButtonURL {
				helpElements += [
					.button(configuration.helpButtonLabel ?? "Open help page".localized, action: UIAction(handler: { action in
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

			case .oidc(withCredentials: _, username: _, password: _):
				stepViewController = BookmarkSetupStepAuthenticateViewController(with: self, step: step)

			case .chooseServer(fromInstances: _):
				// Do not support server choice for now (also see present(composer:step:)
				break

			case .infinitePropfind:
				stepViewController = BookmarkSetupStepPrepopulateViewController(with: self, step: step)

			case .completed:
			if Branding.shared.canEditAccount {
				stepViewController = BookmarkSetupStepFinishedViewController(with: self, step: step)
			} else {
				let bookmark = composer?.addBookmark()
				done(bookmark: bookmark)
			}
		}

		(stepViewController as? BookmarkSetupStepViewController)?.setupViewController = self

		stepControllerByStep[step] = stepViewController

		return stepViewController
	}

	override func constraintsForEmbedding(contentViewController: UIViewController) -> [NSLayoutConstraint] {
		return visibleContentContainerView.embed(centered: contentViewController.view!, minimumInsets: NSDirectionalEdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20), constraintsOnly: true)
	}

	// MARK: - HUD message
	var hudMessageView: UIView? {
		willSet {
			hudMessageView?.removeFromSuperview()

			if newValue == nil {
				contentViewController?.view.isHidden = false
			}
		}

		didSet {
			if let hudMessageView {
				visibleContentContainerView.embed(centered: hudMessageView, minimumInsets: NSDirectionalEdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20))
				contentViewController?.view.isHidden = true
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

				self.hudMessageView = ComposedMessageView(elements: [
					.progressCircle(with: indeterminateProgress),
					.title(hudMessage)
				])
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
