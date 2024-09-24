//
//  BookmarkSetupStepAuthenticateViewController.swift
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

class BookmarkSetupStepAuthenticateViewController: BookmarkSetupStepViewController {
	var usernameField: UITextField?
	var passwordField: UITextField?

	override init(with setupViewController: BookmarkSetupViewController, step: BookmarkComposer.Step) {
		super.init(with: setupViewController, step: step)
		cacheViewController = false
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func loadView() {
		guard case let .authenticate(withCredentials: withCredentials, username: prefillUsername, password: prefillPassword) = step else {
			return
		}

		if withCredentials {
			continueButtonLabelText = OCLocalizedString("Login", nil)
		} else {
			stepTitle = OCLocalizedString("Login", nil)
			stepMessage = OCLocalizedString("If you 'Continue', you will be prompted to allow the '{{app.name}}' app to open the login page where you can enter your credentials.", nil)
			continueButtonLabelText = OCLocalizedString("Open login page", nil)
		}

		let certificateSummaryView = CertificateSummaryView(with: bookmark?.primaryCertificate, httpHostname: bookmark?.url?.host)
		certificateSummaryView.translatesAutoresizingMaskIntoConstraints = false

		if withCredentials {
			self.topViews = [ certificateSummaryView ]
			self.topViewsSpacing = 20
		}

		super.loadView()

		if withCredentials {
			usernameField = buildTextField(withAction: UIAction(handler: { [weak self] _ in
				self?.updateState()
			}), placeholder: "Username", value: prefillUsername ?? "", autocorrectionType: .no, autocapitalizationType: .none, accessibilityLabel: OCLocalizedString("Server Username", nil), borderStyle: .roundedRect)
			usernameField?.textContentType = .username

			passwordField = buildTextField(withAction: UIAction(handler: { [weak self] _ in
				self?.updateState()
			}), placeholder: "Password", value: prefillPassword ?? "", secureTextEntry: true, autocorrectionType: .no, autocapitalizationType: .none, accessibilityLabel: OCLocalizedString("Server Password", nil), borderStyle: .roundedRect)
			passwordField?.textContentType = .password

			focusTextFields = [ usernameField!, passwordField! ]

			let hostView = UIView()
			hostView.translatesAutoresizingMaskIntoConstraints = false

			hostView.embedVertically(views: [usernameField!, passwordField!], insets: .zero, spacingProvider: { leadingView, trailingView in
				return 10
			}, centered: false)

			contentView = hostView
		} else {
			contentView = certificateSummaryView
		}

		updateState()
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)

		guard case let .authenticate(withCredentials: withCredentials, username: _, password: _) = step else {
			return
		}

		if withCredentials {
			usernameField?.becomeFirstResponder()
		}
	}

	func updateState() {
		guard case let .authenticate(withCredentials: withCredentials, username: _, password: _) = step else {
			return
		}

		if withCredentials {
			if let username = usernameField?.text, username.count > 0, let password = usernameField?.text, password.count > 0 {
				continueButton.isEnabled = true
			} else {
				continueButton.isEnabled = false
			}
		}
	}

	override func handleContinue() {
		setupViewController?.composer?.authenticate(username: usernameField?.text, password: passwordField?.text, presentingViewController: self, completion: composerCompletion)
	}
}
