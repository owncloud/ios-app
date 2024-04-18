//
//  ShortcutFileDisplayViewController.swift
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

class ShortcutFileDisplayViewController: DisplayViewController {
	override func renderItem(completion: @escaping (Bool) -> Void) {
		if let itemDirectURL, let core = clientContext?.core {
			INIFile.resolveShortcutFile(at: itemDirectURL, core: core, result: { [weak self] error, url, item in
				OnMainThread {
					if let error {
						let alertController = ThemedAlertController(with: "Error".localized, message: error.localizedDescription, okLabel: "OK".localized, action: nil)
						self?.present(alertController, animated: true)
					} else if item != nil {
						self?.presentShortcutWith(item: item)
					} else {
						self?.presentShortcutWith(url: url)
					}
				}
			})
		}

		completion(true)
	}

	func presentShortcutWith(url: URL? = nil, item: OCItem? = nil) {
		let rootView = ThemeCSSView(withSelectors: [])
		rootView.translatesAutoresizingMaskIntoConstraints = false

		let openButton = ThemeCSSButton(withSelectors: [])
		openButton.translatesAutoresizingMaskIntoConstraints = false
		rootView.addSubview(openButton)

		var openButtonConfig = UIButton.Configuration.bordered()

		if let url {
			let urlTitleLabel = ThemeCSSLabel(withSelectors: [])
			urlTitleLabel.translatesAutoresizingMaskIntoConstraints = false

			let urlLabel = ThemeCSSLabel(withSelectors: [ .secondary ])
			urlLabel.translatesAutoresizingMaskIntoConstraints = false

			rootView.addSubview(urlTitleLabel)
			rootView.addSubview(urlLabel)

			urlTitleLabel.textAlignment = .center
			urlTitleLabel.font = UIFont.preferredFont(forTextStyle: .headline, with: .bold)
			urlTitleLabel.text = "Shortcut".localized

			urlLabel.textAlignment = .center
			urlLabel.font = UIFont.preferredFont(forTextStyle: .subheadline, with: .regular)
			urlLabel.text = url.absoluteString

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

			openButtonConfig.title = "Open link".localized
		}

		if let item, let core = clientContext?.core {
			let itemView = MoreViewHeader(for: item, with: core)

			rootView.addSubview(itemView)

			NSLayoutConstraint.activate([
				itemView.leadingAnchor.constraint(greaterThanOrEqualTo: rootView.leadingAnchor, constant: 10),
				itemView.trailingAnchor.constraint(lessThanOrEqualTo: rootView.trailingAnchor, constant: -10),
				itemView.centerXAnchor.constraint(equalTo: rootView.centerXAnchor),
				itemView.bottomAnchor.constraint(equalTo: rootView.centerYAnchor, constant: 0),

				openButton.topAnchor.constraint(equalTo: rootView.centerYAnchor, constant: 20),
				openButton.centerXAnchor.constraint(equalTo: rootView.centerXAnchor)
			])

			openButtonConfig.title = "Open shortcut".localized
		}

		openButtonConfig.cornerStyle = .large

		openButton.translatesAutoresizingMaskIntoConstraints = false
		openButton.configuration = openButtonConfig
		openButton.addAction(UIAction(handler: { [weak self] _ in
			self?.open(url: url, item: item)
		}), for: .primaryActionTriggered)

		view.addSubview(rootView)
		view.embed(toFillWith: rootView, insets: .zero, enclosingAnchors: view.safeAreaAnchorSet)
	}

	func open(url: URL? = nil, item: OCItem? = nil) {
		if let url {
			UIApplication.shared.open(url) { success in
				if !success {
					OnMainThread {
						let alert = ThemedAlertController(title: "Opening link failed".localized, message: nil, preferredStyle: .alert)
						alert.addAction(UIAlertAction(title: "OK".localized, style: .default))
						self.present(alert, animated: true)
					}
				}
			}
		}

		if let item {
			_ = item.openItem(from: nil, with: clientContext, animated: true, pushViewController: true, completion: nil)
		}
	}
}

extension ShortcutFileDisplayViewController: DisplayExtension {
	static var customMatcher: OCExtensionCustomContextMatcher?
	static var displayExtensionIdentifier: String = "org.owncloud.url-shortcut"
	static var supportedMimeTypes: [String]? = ["text/uri-list"]
	static var features: [String : Any]? = [FeatureKeys.canEdit : false]
}
