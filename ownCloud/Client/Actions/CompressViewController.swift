//
//  CompressViewController.swift
//  ownCloud
//
//  Created by Matthias Hühne on 05/4/2020.
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
import ownCloudSDK

class CompressViewController: NamingViewController {

	private var passwordTextField: UITextField
	private var passwordSwitch: UISwitch
	private var passwordLabel: UILabel
	var completionHandler: (String?, String?, NamingViewController) -> Void
	private let zipExtension = ".zip"

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	public init(with item: OCItem? = nil, core: OCCore? = nil, defaultName: String? = nil, stringValidator: StringValidatorHandler? = nil, completion: @escaping (String?, String?, NamingViewController) -> Void) {

		passwordTextField = UITextField(frame: .zero)
		passwordTextField.accessibilityIdentifier = "pasword-text-field"
		passwordSwitch = UISwitch(frame: .zero)
		passwordSwitch.accessibilityIdentifier = "password-switch"
		passwordLabel = UILabel(frame: .zero)
		completionHandler = completion

		super.init(with: item, core: core, defaultName: defaultName, stringValidator: stringValidator, completion: { _, _ in
		})
	}

	override func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		super.applyThemeCollection(theme: theme, collection: collection, event: event)

		passwordTextField.backgroundColor = collection.tableBackgroundColor
		passwordTextField.textColor = collection.tableRowColors.labelColor
		passwordTextField.keyboardAppearance = collection.keyboardAppearance
		passwordLabel.textColor = collection.tableRowColors.labelColor
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		completion = {name, controller in
			self.passwordTextField.resignFirstResponder()
			if self.passwordSwitch.isOn {
				self.completionHandler(name, self.passwordTextField.text, controller)
			} else {
				self.completionHandler(name, nil, controller)
			}
		}

		// Password switch
		passwordSwitch.translatesAutoresizingMaskIntoConstraints = false
		nameContainer.addSubview(passwordSwitch)

		NSLayoutConstraint.activate([
			passwordSwitch.topAnchor.constraint(equalTo: nameTextField.bottomAnchor, constant: 30),
			passwordSwitch.leftAnchor.constraint(equalTo: nameContainer.leftAnchor, constant: 30)
		])

		// Password label
		passwordLabel.translatesAutoresizingMaskIntoConstraints = false
		nameContainer.addSubview(passwordLabel)

		passwordLabel.text = "Protect file with password".localized

		NSLayoutConstraint.activate([
			passwordLabel.centerYAnchor.constraint(equalTo: passwordSwitch.centerYAnchor),
			passwordLabel.heightAnchor.constraint(equalToConstant: 40),
			passwordLabel.leftAnchor.constraint(equalTo: passwordSwitch.rightAnchor, constant: 15),
			passwordLabel.rightAnchor.constraint(equalTo: nameContainer.rightAnchor, constant: -20)
		])

		// Password textfield
		passwordTextField.translatesAutoresizingMaskIntoConstraints = false
		nameContainer.addSubview(passwordTextField)
		NSLayoutConstraint.activate([
			passwordTextField.topAnchor.constraint(equalTo: passwordLabel.bottomAnchor, constant: 15),
			passwordTextField.heightAnchor.constraint(equalToConstant: 40),
			passwordTextField.leftAnchor.constraint(equalTo: nameContainer.leftAnchor, constant: 30),
			passwordTextField.rightAnchor.constraint(equalTo: nameContainer.rightAnchor, constant: -20)
		])

		passwordSwitch.isOn = false

		passwordTextField.delegate = self
		passwordTextField.textAlignment = .center
		passwordTextField.becomeFirstResponder()
		passwordTextField.addTarget(self, action: #selector(textfieldDidChange(_:)), for: .editingChanged)
		passwordTextField.enablesReturnKeyAutomatically = true
		passwordTextField.autocorrectionType = .no
		passwordTextField.isSecureTextEntry = true
		passwordTextField.borderStyle = .roundedRect
		passwordTextField.clearButtonMode = .always
		passwordTextField.accessibilityLabel = "Password".localized
		passwordTextField.placeholder = "Password".localized
	}

	override func textfieldDidChange(_ sender: UITextField) {
		if sender.isEqual(passwordTextField), sender.text?.count ?? 0 > 0 {
			passwordSwitch.setOn(true, animated: true)
		}
	}
}

extension CompressViewController {

	override func textFieldDidBeginEditing(_ textField: UITextField) {

		if textField.isEqual(nameTextField) {
			if let name = nameTextField.text,
				let range = name.range(of: zipExtension),
				let position: UITextPosition = nameTextField.position(from: nameTextField.beginningOfDocument, offset: range.lowerBound.utf16Offset(in: name)) {

				textField.selectedTextRange = nameTextField.textRange(from: nameTextField.beginningOfDocument, to:position)

			} else {
				textField.selectedTextRange = nameTextField.textRange(from: nameTextField.beginningOfDocument, to: nameTextField.endOfDocument)
			}
		}
	}
}
