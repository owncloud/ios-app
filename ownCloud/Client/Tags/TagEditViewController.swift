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

	private let textField = UITextField()
	private var themeRegistered = false

	init(tag: OCSystemTag?, completion: @escaping CompletionHandler) {
		self.tag = tag
		self.completion = completion
		super.init(nibName: nil, bundle: nil)
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	// MARK: - View lifecycle

	override func viewDidLoad() {
		super.viewDidLoad()

		title = (tag == nil)
			? OCLocalizedString("New Tag", nil)
			: OCLocalizedString("Edit Tag", nil)

		navigationItem.leftBarButtonItem = UIBarButtonItem(
			title: OCLocalizedString("Cancel", nil),
			style: .plain,
			target: self,
			action: #selector(cancelTapped)
		)

		navigationItem.rightBarButtonItem = UIBarButtonItem(
			title: OCLocalizedString("Done", nil),
			style: .done,
			target: self,
			action: #selector(doneTapped)
		)

		setupTextField()
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)

		if !themeRegistered {
			themeRegistered = true
			Theme.shared.register(client: self, applyImmediately: true)
		}

		textField.becomeFirstResponder()
	}

	deinit {
		if themeRegistered {
			Theme.shared.unregister(client: self)
		}
	}

	// MARK: - Themeable

	func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		self.applyThemeCollection(collection)
		view.backgroundColor = collection.css.getColor(.fill, for: view) ?? .white
		textField.textColor = collection.css.getColor(.stroke, selectors: [.label, .primary], for: textField)
		textField.backgroundColor = collection.css.getColor(.fill, for: textField) ?? .white
	}

	// MARK: - Setup

	private func setupTextField() {
		textField.translatesAutoresizingMaskIntoConstraints = false
		textField.placeholder = OCLocalizedString("Tag Name", nil)
		textField.text = tag?.displayName
		textField.clearButtonMode = .whileEditing
		textField.returnKeyType = .done
		textField.autocapitalizationType = .none
		textField.autocorrectionType = .no
		textField.borderStyle = .roundedRect
		textField.delegate = self
		textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)

		view.addSubview(textField)

		NSLayoutConstraint.activate([
			textField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
			textField.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
			textField.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16)
		])

		updateDoneButton()
	}

	// MARK: - Actions

	@objc private func cancelTapped() {
		dismiss(animated: true)
		completion(nil)
	}

	@objc private func doneTapped() {
		guard let name = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty else {
			return
		}
		dismiss(animated: true)
		completion(name)
	}

	@objc private func textFieldDidChange() {
		updateDoneButton()
	}

	private func updateDoneButton() {
		let hasText = !(textField.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
		navigationItem.rightBarButtonItem?.isEnabled = hasText
	}
}

// MARK: - UITextFieldDelegate

extension TagEditViewController: UITextFieldDelegate {
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		doneTapped()
		return false
	}
}
