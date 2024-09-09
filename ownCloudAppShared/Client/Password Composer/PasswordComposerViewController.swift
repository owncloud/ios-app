//
//  PasswordComposerViewController.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 23.02.24.
//  Copyright © 2024 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2024, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import UIKit
import ownCloudSDK

class PasswordComposerViewController: UIViewController {
	typealias ResultHandler = (_ password: String?, _ cancelled: Bool) -> Void

	var resultHandler: ResultHandler?

	let passwordLabel = ThemeCSSLabel(withSelectors: [ .label, .secondary ])
	let passwordFieldContainer = ThemeCSSView(withSelectors: [ .cell ])
	let passwordField = ThemeCSSTextField()

	let componentToolbar = SegmentView(with: [], truncationMode: .none, scrollable: false)

	let validationReportContainerView = ThemeCSSView(withSelectors: [ .cell ])

	lazy var showPasswordSegment: SegmentViewItem = {
		return SegmentViewItem.button(title: OCLocalizedString("Show", nil), customizeButton: { _, config in
			var buttonConfig = config
			buttonConfig.image = OCSymbol.icon(forSymbolName: "eye")?.applyingSymbolConfiguration(UIImage.SymbolConfiguration(scale: .small))
			buttonConfig.imagePadding = 5
			return buttonConfig
		}, action: UIAction(handler: { [weak self] _ in
			self?.showPassword = true
		}))
	}()
	lazy var hidePasswordSegment: SegmentViewItem = {
		return SegmentViewItem.button(title: OCLocalizedString("Hide", nil), customizeButton: { _, config in
			var buttonConfig = config
			buttonConfig.image = OCSymbol.icon(forSymbolName: "eye.slash")?.applyingSymbolConfiguration(UIImage.SymbolConfiguration(scale: .small))
			buttonConfig.imagePadding = 5
			return buttonConfig
		}, action: UIAction(handler: { [weak self] _ in
			self?.showPassword = false
		}))
	}()
	lazy var generatePasswordSegment: SegmentViewItem = {
		return SegmentViewItem.button(title: OCLocalizedString("Generate", nil), action: UIAction(handler: { [weak self] _ in
			self?.generatePassword()
		}))
	}()
	lazy var copyPasswordSegment: SegmentViewItem = {
		return SegmentViewItem.button(title: OCLocalizedString("Copy", nil), action: UIAction(handler: { [weak self] _ in
			self?.copyToClipboard()
		}))
	}()

	var saveButton: UIBarButtonItem?

	var passwordPolicy: OCPasswordPolicy

	init(password: String, policy: OCPasswordPolicy, saveButtonTitle: String, resultHandler: @escaping ResultHandler) {
		self.passwordPolicy = policy

		super.init(nibName: nil, bundle: nil)

		defer {
			// Placing this in a defer block makes sure that didSet is called for the respective properties
			self.password = password
			self.showPassword = false
		}

		self.resultHandler = resultHandler

		saveButton = UIBarButtonItem(title: saveButtonTitle, style: .done, target: self, action: #selector(save))

		navigationItem.leftBarButtonItem = UIBarButtonItem(title: OCLocalizedString("Cancel", nil), style: .plain, target: self, action: #selector(cancel))
		navigationItem.rightBarButtonItem = saveButton
		navigationItem.title = OCLocalizedString("Password", nil)
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func loadView() {
		let rootView = ThemeCSSView(withSelectors: [ .grouped, .collection ])
		let padding = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
		let labelFieldSpacing: CGFloat = 10
		let fieldToolbarSpacing: CGFloat = 15
		let toolbarValidationReportSpacing: CGFloat = 15

		passwordLabel.translatesAutoresizingMaskIntoConstraints = false
		passwordFieldContainer.translatesAutoresizingMaskIntoConstraints = false
		passwordField.translatesAutoresizingMaskIntoConstraints = false
		componentToolbar.translatesAutoresizingMaskIntoConstraints = false
		componentToolbar.setContentHuggingPriority(.defaultHigh, for: .horizontal)
		validationReportContainerView.translatesAutoresizingMaskIntoConstraints = false

		passwordFieldContainer.layer.cornerRadius = 5
		validationReportContainerView.layer.cornerRadius = 10

		passwordField.cssSelectors = [ .cell ]
		passwordFieldContainer.embed(toFillWith: passwordField, insets: NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))

		componentToolbar.insets = .zero
		componentToolbar.itemSpacing = 0

		rootView.addSubview(passwordLabel)
		rootView.addSubview(passwordFieldContainer)
		rootView.addSubview(componentToolbar)
		rootView.addSubview(validationReportContainerView)

		passwordLabel.text = OCLocalizedString("Password", nil)
		passwordLabel.font = UIFont.systemFont(ofSize: UIFont.smallSystemFontSize)

		passwordField.placeholder = OCLocalizedString("Password", nil)
		passwordField.clearButtonMode = .always
		passwordField.addAction(UIAction(handler: { [weak self] _ in
			self?.passwordChanged()
		}), for: .editingChanged)

		rootView.addConstraints([
			passwordLabel.topAnchor.constraint(equalTo: rootView.safeAreaLayoutGuide.topAnchor, constant: padding.top),
			passwordLabel.leadingAnchor.constraint(equalTo: rootView.safeAreaLayoutGuide.leadingAnchor, constant: padding.left),
			passwordLabel.trailingAnchor.constraint(equalTo: rootView.safeAreaLayoutGuide.trailingAnchor, constant: -padding.right),

			passwordFieldContainer.topAnchor.constraint(equalTo: passwordLabel.bottomAnchor, constant: labelFieldSpacing),
			passwordFieldContainer.leadingAnchor.constraint(equalTo: rootView.safeAreaLayoutGuide.leadingAnchor, constant: padding.left),
			passwordFieldContainer.trailingAnchor.constraint(equalTo: rootView.safeAreaLayoutGuide.trailingAnchor, constant: -padding.right),

			componentToolbar.topAnchor.constraint(equalTo: passwordField.bottomAnchor, constant: fieldToolbarSpacing),
			componentToolbar.leadingAnchor.constraint(equalTo: rootView.safeAreaLayoutGuide.leadingAnchor, constant: padding.left - 5),
			componentToolbar.trailingAnchor.constraint(lessThanOrEqualTo: rootView.safeAreaLayoutGuide.trailingAnchor, constant: -padding.right),

			validationReportContainerView.topAnchor.constraint(equalTo: componentToolbar.bottomAnchor, constant: toolbarValidationReportSpacing),
			validationReportContainerView.leadingAnchor.constraint(equalTo: rootView.safeAreaLayoutGuide.leadingAnchor, constant: padding.left),
			validationReportContainerView.trailingAnchor.constraint(equalTo: rootView.safeAreaLayoutGuide.trailingAnchor, constant: -padding.right)
		])

		view = rootView
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		validatePasssword()
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)

		passwordField.becomeFirstResponder()
	}

	func passwordChanged() {
		password = passwordField.text ?? ""
	}

	func validatePasssword() {
		let report = passwordPolicy.validate(password)
		var lines : [UIView] = []
		var failures: Int = 0

		for rule in report.rules {
			var ruleDescription: String? = rule.localizedDescription

			if !(rule is OCPasswordPolicyRuleCharacters), let result = report.result(for: rule) {
				ruleDescription = result
			}

			if let ruleDescription {
				let passedValidation = report.passedValidation(for: rule)
				let symbolConfiguration = UIImage.SymbolConfiguration(hierarchicalColor: passedValidation ? .systemGreen : .systemRed)
				let line = SegmentView(with: [
					SegmentViewItem(with: UIImage(systemName: passedValidation ? "checkmark.circle.fill" : "xmark.circle.fill")?.withConfiguration(symbolConfiguration), iconRenderingMode: .automatic, title: ruleDescription)
				], truncationMode: .truncateTail)
				line.translatesAutoresizingMaskIntoConstraints = false
				line.insets = .zero

				if passedValidation {
					lines.append(line)
				} else {
					lines.insert(line, at: failures)
					failures += 1
				}
			}
		}

		for subview in validationReportContainerView.subviews {
			subview.removeFromSuperview()
		}

		validationReportContainerView.embedVertically(views: lines, insets: NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10), enclosingAnchors: validationReportContainerView.safeAreaAnchorSet, centered: false)

		saveButton?.isEnabled = report.passedValidation
	}

	func updateSegments() {
		var items: [SegmentViewItem] = []

		// Show/Hide password
		if showPassword {
			items.append(hidePasswordSegment)
		} else {
			items.append(showPasswordSegment)
		}

		// Generate password
		items.append(SegmentViewItem(title: "|", style: .label))
		items.append(generatePasswordSegment)

		// Copy password
		if password.count > 0 {
			items.append(SegmentViewItem(title: "|", style: .label))
			items.append(copyPasswordSegment)
		}

		if componentToolbar.items != items {
			componentToolbar.items = items
		}
	}

	var password: String {
		get {
			return passwordField.text ?? ""
		}

		set {
			passwordField.text = newValue

			updateSegments()
			validatePasssword()
		}
	}
	var showPassword: Bool = false {
		didSet {
			passwordField.isSecureTextEntry = !showPassword
			updateSegments()
		}
	}

	func generatePassword() {
		var generatedPassword: String?
		do {
			try generatedPassword = passwordPolicy.generatePassword(withMinLength: nil, maxLength: nil)
		} catch let error as NSError {
			Log.error("Error generating password: \(error)")
		}
		if let generatedPassword {
			password = generatedPassword
		}
	}

	func copyToClipboard() {
		UIPasteboard.general.string = password

		_ = NotificationHUDViewController(on: self, title: OCLocalizedString("Password", nil), subtitle: OCLocalizedString("The password was copied to the clipboard", nil), completion: nil)
	}

	func viewControllerForPresentation() -> ThemeNavigationController {
		let navigationViewController = ThemeNavigationController(rootViewController: self)
		navigationViewController.cssSelectors = [ .modal ]

		return navigationViewController
	}

	@objc func save() {
		presentingViewController?.dismiss(animated: true, completion: {
			self.resultHandler?(self.password, false)
		})
	}

	@objc func cancel() {
		presentingViewController?.dismiss(animated: true, completion: {
			self.resultHandler?(nil, true)
		})
	}
}
