//
//  HelpAndSupportViewController.swift
//  ownCloud
//
//  Created by Felix Schwarz on 27.06.24.
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
import ownCloudApp
import ownCloudAppShared

class HelpAndSupportViewController: CollectionViewController {
	init() {
		super.init(context: nil, sections: nil, useStackViewRoot: true)

		add(sections: [
			helpAndSupportSection()
		])
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		cssSelectors = [.modal]

		navigationItem.title = "Help & Support".localized
		navigationItem.largeTitleDisplayMode = .always

		navigationItem.rightBarButtonItem = UIBarButtonItem(systemItem: .close, primaryAction: UIAction(handler: { [weak self] _ in
			self?.dismiss(animated: true)
		}))
	}

	func helpAndSupportSection() -> CollectionViewSection {
		var elements: [ComposedMessageElement] = []

		if let documentationURL = VendorServices.shared.documentationURL {
			elements.append(contentsOf: [
				.title("Documentation".localized),
				.text("Find information, answers and solutions in the detailed documentation.".localized, style: .informal, cssSelectors: [.message]),
				.spacing(5),

				.button("View documentation".localized, action: UIAction(handler: { [weak self] _ in
					if let self {
						VendorServices.shared.openSFWebView(on: self, for: documentationURL)
					}
				}), image: nil, cssSelectors: [ .info ]),

				.spacing(20)
			])
		}

		elements.append(contentsOf: [
			.title("Help".localized),
			.text("Get in touch with our community in the forums - or file a GitHub issue to report a bug or request a feature.".localized, style: .informal, cssSelectors: [.message]),
			.spacing(5),

			.button("File an issue".localized, action: UIAction(handler: { [weak self] _ in
				if let self {
					VendorServices.shared.openSFWebView(on: self, for: URL(string: "https://github.com/owncloud/ios-app/issues/new/choose")!)
				}
			}), image: nil, cssSelectors: [ .info ]),

			.button("Visit the forums".localized, action: UIAction(handler: { [weak self] _ in
				if let self {
					VendorServices.shared.openSFWebView(on: self, for: URL(string: "https://central.owncloud.org/c/ios/")!)
				}
			}), image: nil, cssSelectors: [ .info ]),

			.spacing(20)
		])

		if (VendorServices.shared.feedbackMail != nil) || (Branding.shared.feedbackURL != nil) {
			elements.append(contentsOf: [
				.title("Send feedback".localized),

				.text("If you don't need a response and just want to send us feedback, you can also send us a mail.".localized, style: .informal, cssSelectors: [.message]),
				.spacing(5),

				.button("Send feedback".localized, action: UIAction(handler: { _ in
					VendorServices.shared.sendFeedback(from: self)
				}), image: nil, cssSelectors: [ .info ], insets: .zero)
			])
		}

		let section = CollectionViewSection(identifier: "helpAndSupport", dataSource: OCDataSourceArray(items: [
			ComposedMessageView(elements: elements)
		]))

		return section
	}
}
