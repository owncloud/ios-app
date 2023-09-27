//
//  BookmarkSetupStepViewController.swift
//  ownCloud
//
//  Created by Felix Schwarz on 06.09.23.
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
import ownCloudAppShared

extension BookmarkComposer.Step {
	var cssSelector: ThemeCSSSelector {
		switch self {
			case .intro: return ThemeCSSSelector(rawValue: "intro")
			case .enterUsername: return ThemeCSSSelector(rawValue: "enterUsername")
			case .serverURL(urlString: _):  return ThemeCSSSelector(rawValue: "serverURL")
			case .authenticate(withCredentials: _, username: _, password: _): return ThemeCSSSelector(rawValue: "authenticate")
			case .chooseServer(fromInstances: _): return ThemeCSSSelector(rawValue: "chooseServer")
			case .infinitePropfind: return ThemeCSSSelector(rawValue: "infinitePropfind")
			case .completed: return ThemeCSSSelector(rawValue: "completed")
		}
	}
}

class BookmarkSetupStepViewController: UIViewController, UITextFieldDelegate {
	weak var setupViewController: BookmarkSetupViewController?
	var backgroundView: ThemeCSSView
	var step: BookmarkComposer.Step

	init(with setupViewController: BookmarkSetupViewController, step: BookmarkComposer.Step) {
		self.setupViewController = setupViewController
		self.step = step
		self.backgroundView = ThemeCSSView(withSelectors: [.background])
		self.backgroundView.translatesAutoresizingMaskIntoConstraints = false

		composerCompletion = { [weak setupViewController] (error, issue, issueCompletionHandler) in
			if let setupViewController, let composer = setupViewController.composer {
				setupViewController.present(composer: composer, error: error, issue: issue, issueCompletionHandler: issueCompletionHandler)
			}
		}

		super.init(nibName: nil, bundle: nil)
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	var stepTitle: String?
	var stepMessage: String?
	var continueButtonLabelText: String? = "Proceed".localized {
		didSet {
			var buttonConfiguration = continueButton.configuration
			buttonConfiguration?.title = continueButtonLabelText
			continueButton.configuration = buttonConfiguration
		}
	}
	var backButtonLabelText: String? = "Back".localized {
		didSet {
			var buttonConfiguration = backButton.configuration
			buttonConfiguration?.title = backButtonLabelText
			backButton.configuration = buttonConfiguration
		}
	}

	var titleLabel: UILabel?
	var messageLabel: UILabel?
	var continueButton: UIButton = UIButton()
	var backButton: UIButton = UIButton()

	var contentContainerView: UIView?
	var contentView: UIView? {
		willSet {
			if newValue != contentView {
				contentView?.removeFromSuperview()
			}
		}

		didSet {
			if let contentView {
				contentContainerView?.embed(toFillWith: contentView)
			}
		}
	}

	var bookmark: OCBookmark? {
		return setupViewController?.composer?.bookmark
	}

	var composerCompletion: BookmarkComposer.Completion

	var topViews: [UIView]?
	var topViewsSpacing: CGFloat = 10
	var bottomViews: [UIView]?
	var bottomViewsSpacing: CGFloat = 10

	override func loadView() {
		var views: [UIView] = topViews ?? []

		let contentView = UIView()
		contentView.cssSelectors = [.step, step.cssSelector]

		// Title & message
		if let stepTitle = textOverride(for: "title") ?? stepTitle {
			titleLabel = ThemeCSSLabel(withSelectors: [.title])
			titleLabel?.translatesAutoresizingMaskIntoConstraints = false
			titleLabel?.text = stepTitle
			titleLabel?.font = UIFont.preferredFont(forTextStyle: .headline, with: .bold)
			titleLabel?.makeLabelWrapText()

			views.append(titleLabel!)
		}

		if let stepMessage = textOverride(for: "message") ?? stepMessage {
			messageLabel = ThemeCSSLabel(withSelectors: [.message])
			messageLabel?.translatesAutoresizingMaskIntoConstraints = false
			messageLabel?.text = stepMessage
			messageLabel?.font = UIFont.preferredFont(forTextStyle: .subheadline, with: .regular)
			messageLabel?.makeLabelWrapText()

			views.append(messageLabel!)
		}

		// Content container view
		contentContainerView = UIView()
		contentContainerView?.translatesAutoresizingMaskIntoConstraints = false

		if let contentContainerView {
			views.append(contentContainerView)
		}

		// Continue Button
		var buttonConfiguration = UIButton.Configuration.borderedProminent()
		buttonConfiguration.title = continueButtonLabelText
		buttonConfiguration.cornerStyle = .large

		continueButton.translatesAutoresizingMaskIntoConstraints = false
		continueButton.configuration = buttonConfiguration
		continueButton.addAction(UIAction(handler: { [weak self] _ in
			self?.handleContinue()
		}), for: .primaryActionTriggered)

		views.append(continueButton)

		// Back button
		if hasBackButton {
			buttonConfiguration = UIButton.Configuration.plain()
			buttonConfiguration.title = backButtonLabelText
			buttonConfiguration.cornerStyle = .large

			backButton.translatesAutoresizingMaskIntoConstraints = false
			backButton.configuration = buttonConfiguration
			backButton.addAction(UIAction(handler: { [weak self] _ in
				self?.handleBack()
			}), for: .primaryActionTriggered)

			views.append(backButton)
		}

		// Bottom views
		if let bottomViews {
			views.append(contentsOf: bottomViews)
		}

		// Embed background view
		self.backgroundView.layer.cornerRadius = 10
		self.backgroundView.layer.masksToBounds = true
		contentView.embed(toFillWith: backgroundView)

		// Layout views vertically in background view
		contentView.embedVertically(views: views, insets: NSDirectionalEdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20), spacingProvider: { leadingView, trailingView in
			if leadingView == self.topViews?.last {
				return self.topViewsSpacing
			}
			if trailingView == self.bottomViews?.first {
				return self.bottomViewsSpacing
			}
			if trailingView == self.contentContainerView {
				return 15
			}
			if leadingView == self.contentContainerView {
				return 30
			}
			return 5
		}, centered: false)

		// Set view controller's view
		self.view = contentView
	}

	func handleContinue() {
	}

	var hasBackButton: Bool {
		return canGoBack
	}

	var canGoBack: Bool {
		return setupViewController?.canGoBack ?? false
	}

	func handleBack() {
		self.setupViewController?.goBack()
	}

	func present(error: Error?, issue: OCIssue?, issueCompletionHandler: IssuesCardViewController.CompletionHandler?) {
		if let composer = setupViewController?.composer, error != nil || issue != nil {
			self.setupViewController?.present(composer: composer, error: error, issue: issue, issueCompletionHandler: issueCompletionHandler)
		}
	}

	func buildTextField(withAction textChangedAction: UIAction?, forEvent actionEvent: UIControl.Event = .editingChanged, placeholder placeholderString: String = "", value textValue: String = "", secureTextEntry : Bool = false, keyboardType: UIKeyboardType = .default, autocorrectionType: UITextAutocorrectionType = .default, autocapitalizationType: UITextAutocapitalizationType = UITextAutocapitalizationType.none, enablesReturnKeyAutomatically: Bool = true, returnKeyType : UIReturnKeyType = .default, inputAccessoryView : UIView? = nil, identifier : String? = nil, accessibilityLabel: String? = nil, clearButtonMode : UITextField.ViewMode = .never, borderStyle:  UITextField.BorderStyle = .none) -> UITextField {
		let textField : UITextField = ThemeCSSTextField()

		textField.translatesAutoresizingMaskIntoConstraints = false

		textField.placeholder = placeholderString
		textField.keyboardType = keyboardType
		textField.autocorrectionType = autocorrectionType
		textField.isSecureTextEntry = secureTextEntry
		textField.autocapitalizationType = autocapitalizationType
		textField.enablesReturnKeyAutomatically = enablesReturnKeyAutomatically
		textField.returnKeyType = returnKeyType
		textField.inputAccessoryView = inputAccessoryView
		textField.text = textValue
		textField.accessibilityIdentifier = identifier
		textField.clearButtonMode = clearButtonMode
		textField.borderStyle = borderStyle

		if let textChangedAction {
			textField.addAction(textChangedAction, for: actionEvent)
		}

		textField.accessibilityLabel = accessibilityLabel

		textField.setContentHuggingPriority(.required, for: .vertical)
		textField.setContentCompressionResistancePriority(.required, for: .horizontal)

		return textField
	}

	var focusTextFields: [UITextField]? {
		didSet {
			if let focusTextFields {
				for textField in focusTextFields {
					textField.delegate = self
				}
			}
		}
	}

	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		if let focusTextFields, let position = focusTextFields.firstIndex(of: textField) {
			if position < (focusTextFields.count-1) {
				let nextTextField = focusTextFields[position+1]
				nextTextField.becomeFirstResponder()

				return false
			}
		}

		if continueButton.isEnabled {
			handleContinue()
		}

		return false
	}

	func textOverride(for label: String) -> String? {
		let key = "setup-\(step.cssSelector.rawValue)-\(label)"
		let localization = key.localized

		if localization != key {
			return localization
		}

		return nil
	}
}
