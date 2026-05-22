//
//  TagEditViewController.swift
//  ownCloud
//
//  Copyright © 2025 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2025, ownCloud GmbH.
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

class TagEditViewController: UIViewController, Themeable {

	typealias CompletionHandler = (_ tagName: String?) -> Void

	private let tag: OCSystemTag?
	private let completion: CompletionHandler

	private let tagNameField = HCTextFieldView(frame: .zero)
	private let cancelBarButtonItem: UIBarButtonItem
	private let doneBarButtonItem: UIBarButtonItem
	private var themeRegistered = false

	init(tag: OCSystemTag?, completion: @escaping CompletionHandler) {
		self.tag = tag
		self.completion = completion
		self.cancelBarButtonItem = UIBarButtonItem(
			title: HCL10n.TagEdit.cancel,
			style: .plain,
			target: nil,
			action: nil
		)
		self.doneBarButtonItem = UIBarButtonItem(
			title: HCL10n.TagEdit.done,
			style: .done,
			target: nil,
			action: nil
		)
		super.init(nibName: nil, bundle: nil)
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	// MARK: - View lifecycle

	override func viewDidLoad() {
		super.viewDidLoad()

		Theme.shared.register(client: self, applyImmediately: true)

		title = (tag == nil)
			? HCL10n.TagEdit.add
			: HCL10n.TagEdit.edit

		cancelBarButtonItem.target = self
		cancelBarButtonItem.action = #selector(cancelTapped)
		doneBarButtonItem.target = self
		doneBarButtonItem.action = #selector(doneTapped)
		navigationItem.leftBarButtonItem = cancelBarButtonItem
		navigationItem.rightBarButtonItem = doneBarButtonItem

		setupTextField()
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)

		tagNameField.textField.becomeFirstResponder()
	}

	deinit {
		if themeRegistered {
			Theme.shared.unregister(client: self)
		}
	}

	// MARK: - Themeable

	func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		self.applyThemeCollection(collection)
		view.backgroundColor = HCColor.Structure.appBackground(collection.isDark)

		cancelBarButtonItem.tintColor = HCColor.Interaction.primarySolidNormal(collection.isDark)
		doneBarButtonItem.tintColor = HCColor.Interaction.primarySolidNormal(collection.isDark)

		tagNameField.clearButton.setImage(collection.isDark ? HCIcon.clearDark : HCIcon.clearLight, for: .normal)
	}

	// MARK: - Setup

	private func setupTextField() {
		tagNameField.translatesAutoresizingMaskIntoConstraints = false
		tagNameField.title = ""
		tagNameField.placeholder = tag == nil ? HCL10n.TagEdit.addPlaceholder : HCL10n.TagEdit.editPlaceholder
		tagNameField.textField.text = tag?.displayName
		tagNameField.textField.returnKeyType = .done
		tagNameField.textField.autocapitalizationType = .none
		tagNameField.textField.autocorrectionType = .no
		tagNameField.textField.delegate = self
		tagNameField.textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
		tagNameField.showsCardBackground = true

		view.addSubview(tagNameField)

		NSLayoutConstraint.activate([
			tagNameField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
			tagNameField.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
			tagNameField.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16)
		])

		updateDoneButton()
	}

	// MARK: - Actions

	@objc private func cancelTapped() {
		tagNameField.textField.resignFirstResponder()
		dismiss(animated: true) { [completion] in
			completion(nil)
		}
	}

	@objc private func doneTapped() {
		let trimmedName = tagNameField.textField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
		guard !trimmedName.isEmpty else { return }
		if let error = validationError(for: trimmedName) {
			tagNameField.errorText = error
			return
		}
		tagNameField.textField.resignFirstResponder()
		dismiss(animated: true) { [completion] in
			completion(trimmedName)
		}
	}

	@objc private func textFieldDidChange() {
		validateInput()
		updateDoneButton()
	}

	private func validationError(for name: String) -> String? {
		TagNameValidation.validationError(for: name)
	}

	private func validateInput() {
		let trimmedName = tagNameField.textField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
		tagNameField.errorText = trimmedName.isEmpty ? nil : validationError(for: trimmedName)
	}

	private func updateDoneButton() {
		let trimmedName = tagNameField.textField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
		let isValid = !trimmedName.isEmpty && validationError(for: trimmedName) == nil
		doneBarButtonItem.isEnabled = isValid
	}
}

// MARK: - UITextFieldDelegate

extension TagEditViewController: UITextFieldDelegate {
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		doneTapped()
		return false
	}
}
