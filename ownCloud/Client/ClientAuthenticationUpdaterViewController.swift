//
//  ClientAuthenticationUpdaterViewController.swift
//  ownCloud
//
//  Created by Felix Schwarz on 26.04.20.
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
import ownCloudAppShared

class ClientAuthenticationUpdaterViewController: StaticTableViewController {
	var headerText : String
	typealias PasswordValidationHandler = (_ password: String, _ completion: @escaping (_ error: Error?) -> Void) -> Void
	var validationHandler : PasswordValidationHandler?
	var validationQueue : OCAsyncSequentialQueue

	init(passwordHeaderText: String, passwordValidationHandler : @escaping PasswordValidationHandler) {
		self.headerText = passwordHeaderText
		self.validationHandler = passwordValidationHandler

		self.validationQueue = OCAsyncSequentialQueue()

		super.init(style: .grouped)
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	var passwordRow : StaticTableViewRow?

	override func viewDidLoad() {
		super.viewDidLoad()

		self.navigationItem.title = "Sign in".localized
		self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Continue".localized, style: .done, target: self, action: #selector(startValidation(_:)))
		self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(dismissAnimated))

		self.navigationItem.rightBarButtonItem?.isEnabled = false

		passwordRow = StaticTableViewRow(secureTextFieldWithAction: { [weak self] (row, _, _) in
			self?.navigationItem.rightBarButtonItem?.isEnabled = ((row.value as? String)?.count ?? 0) > 0
		}, placeholder: "Password".localized, value: "", autocorrectionType: .no, autocapitalizationType: .none, enablesReturnKeyAutomatically: true, returnKeyType: .continue, identifier: "password", accessibilityLabel: "Password".localized)

		passwordRow?.textField?.delegate = self

		self.sections = [
			StaticTableViewSection(headerTitle: headerText, footerTitle: nil, identifier: nil, rows: [ passwordRow! ])
		]
	}

	var hud : ProgressHUDViewController?

	@objc func startValidation(_ sender: Any?) {
		if let password = self.passwordRow?.value as? String {
			self.validate(password: password)
		}
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)

		passwordRow?.textField?.becomeFirstResponder()
	}

	func validate(password: String) {
		validationQueue.async { [weak self] (validationCompleted) in
			self?.hud = ProgressHUDViewController(on: self, label: "Verifying password…".localized)

			let hudCompletion: (((() -> Void)?) -> Void) = { [weak self] (completion) in
				OnMainThread {
					if self?.hud?.presenting == true {
						self?.hud?.dismiss(completion: completion)
					} else {
						completion?()
					}

					validationCompleted()
				}
			}

			self?.validationHandler?(password, { [weak self] (error) in
				hudCompletion({
					if error == nil {
						self?.dismissAnimated()
					} else {
						self?.view.shakeHorizontally()
					}
				})
			})
		}
	}

	override func dismissAnimated() {
		validationHandler = nil
		super.dismissAnimated()
	}
}

extension ClientAuthenticationUpdaterViewController : UITextFieldDelegate {
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		startValidation(textField)

		return false
	}
}
