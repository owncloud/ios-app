//
//  BookmarkSetupStepEnterURLViewController.swift
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
import ownCloudAppShared
import ownCloudSDK

class BookmarkSetupStepEnterURLViewController: BookmarkSetupStepViewController {
	var urlTextField: UITextField?
	var clientCertificateButton: UIButton = ThemeCSSButton(withSelectors: [])

	override func loadView() {
		stepTitle = OCLocalizedString("Server URL", nil)

		// Client certificate (mTLS) button
		var buttonConfiguration = UIButton.Configuration.plain()
		buttonConfiguration.image = UIImage(systemName: "person.badge.key")
		buttonConfiguration.imagePadding = 6
		buttonConfiguration.titleLineBreakMode = .byWordWrapping
		buttonConfiguration.subtitleLineBreakMode = .byWordWrapping
		clientCertificateButton.translatesAutoresizingMaskIntoConstraints = false
		clientCertificateButton.configuration = buttonConfiguration
		clientCertificateButton.addAction(UIAction(handler: { [weak self] _ in
			self?.manageClientCertificate()
		}), for: .primaryActionTriggered)
		bottomViews = [ clientCertificateButton ]

		super.loadView()

		urlTextField = buildTextField(withAction: UIAction(handler: { [weak self] _ in
			self?.updateState()
		}), placeholder: "https://", keyboardType: .URL, autocorrectionType: .no, autocapitalizationType: .none, accessibilityLabel: OCLocalizedString("Server URL", nil), borderStyle: .roundedRect)

		urlTextField?.text = setupViewController?.composer?.configuration.url?.absoluteString

		focusTextFields = [ urlTextField! ]

		contentView = urlTextField

		updateState()
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		urlTextField?.becomeFirstResponder()
	}

	var enteredHost: String? {
		if let urlString = urlTextField?.text, !urlString.isEmpty,
		   let normalizedURL = NSURL(username: nil, password: nil, afterNormalizingURLString: urlString, protocolWasPrepended: nil) {
			return normalizedURL.host
		}
		return nil
	}

	func manageClientCertificate() {
		ClientCertificateManager.present(for: enteredHost, on: self, sourceView: clientCertificateButton, changeHandler: { [weak self] in
			self?.updateState()
		})
	}

	func updateClientCertificateButton() {
		var configuration = clientCertificateButton.configuration ?? .plain()

		if let host = enteredHost, let info = OCClientIdentityStore.shared.identityInfo(forHost: host) {
			configuration.title = OCLocalizedString("Client certificate", nil)
			configuration.subtitle = info.displaySummary
		} else {
			configuration.title = OCLocalizedString("Use a client certificate…", nil)
			configuration.subtitle = nil
		}

		clientCertificateButton.configuration = configuration
	}

	func updateState() {
		updateClientCertificateButton()

		if let urlString = urlTextField?.text, urlString.count > 0, NSURL(username: nil, password: nil, afterNormalizingURLString: urlString, protocolWasPrepended: nil) != nil {
			continueButton.isEnabled = true
		} else {
			continueButton.isEnabled = false
		}
	}

	override func handleContinue() {
		if let urlString = urlTextField?.text {
			setupViewController?.composer?.enterURL(urlString, completion: composerCompletion)
		}
	}
}
