//
//  URLDisplayViewController.swift
//  ownCloud
//
//  Created by Felix Schwarz on 08.04.24.
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
import ownCloudAppShared

class URLDisplayViewController: DisplayViewController {
	override func viewDidLoad() {
		super.viewDidLoad()
	}

	override func renderItem(completion: @escaping (Bool) -> Void) {
		if let itemDirectURL {
			if let data = try? Data(contentsOf: itemDirectURL) {
				if let url = INIFile(with: data).url {
					presentShortcutWith(url: url)
				}
			}
		}

		completion(true)
	}

	func presentShortcutWith(url: URL) {
		let rootView = ThemeCSSView(withSelectors: [])
		rootView.translatesAutoresizingMaskIntoConstraints = false

		let openButton = ThemeCSSButton(withSelectors: [])
		openButton.translatesAutoresizingMaskIntoConstraints = false

		let urlTitleLabel = ThemeCSSLabel(withSelectors: [])
		urlTitleLabel.translatesAutoresizingMaskIntoConstraints = false

		let urlLabel = ThemeCSSLabel(withSelectors: [ .secondary ])
		urlLabel.translatesAutoresizingMaskIntoConstraints = false

		rootView.addSubview(urlTitleLabel)
		rootView.addSubview(urlLabel)
		rootView.addSubview(openButton)

		urlTitleLabel.textAlignment = .center
		urlTitleLabel.font = UIFont.preferredFont(forTextStyle: .headline, with: .bold)
		urlTitleLabel.text = "Shortcut".localized

		urlLabel.textAlignment = .center
		urlLabel.font = UIFont.preferredFont(forTextStyle: .subheadline, with: .regular)
		urlLabel.text = url.absoluteString

		var openButtonConfig = UIButton.Configuration.bordered()
		openButtonConfig.title = "Open link".localized
		openButtonConfig.cornerStyle = .large

		openButton.translatesAutoresizingMaskIntoConstraints = false
		openButton.configuration = openButtonConfig
		openButton.addAction(UIAction(handler: { [weak self] _ in
			UIApplication.shared.open(url) { success in
				if !success {
					OnMainThread {
						let alert = ThemedAlertController(title: "Opening link failed".localized, message: nil, preferredStyle: .alert)
						alert.addAction(UIAlertAction(title: "OK".localized, style: .default))
						self?.present(alert, animated: true)
					}
				}
			}
		}), for: .primaryActionTriggered)

		NSLayoutConstraint.activate([
			urlTitleLabel.leadingAnchor.constraint(equalTo: rootView.leadingAnchor, constant: 10),
			urlTitleLabel.trailingAnchor.constraint(equalTo: rootView.trailingAnchor, constant: -10),
			urlTitleLabel.bottomAnchor.constraint(equalTo: urlLabel.topAnchor, constant: -10),

			urlLabel.leadingAnchor.constraint(equalTo: rootView.leadingAnchor, constant: 10),
			urlLabel.trailingAnchor.constraint(equalTo: rootView.trailingAnchor, constant: -10),
			urlLabel.bottomAnchor.constraint(equalTo: rootView.centerYAnchor, constant: -10),

			openButton.topAnchor.constraint(equalTo: rootView.centerYAnchor, constant: 20),
			openButton.centerXAnchor.constraint(equalTo: rootView.centerXAnchor)
		])

		view.addSubview(rootView)
		view.embed(toFillWith: rootView, insets: .zero, enclosingAnchors: view.safeAreaAnchorSet)
	}
}

extension URLDisplayViewController: DisplayExtension {
	static var customMatcher: OCExtensionCustomContextMatcher?
	static var displayExtensionIdentifier: String = "org.owncloud.url-shortcut"
	static var supportedMimeTypes: [String]? = ["text/uri-list"]
	static var features: [String : Any]? = [FeatureKeys.canEdit : false]
}
