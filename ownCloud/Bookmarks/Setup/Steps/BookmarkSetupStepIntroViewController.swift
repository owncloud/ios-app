//
//  BookmarkSetupStepIntroViewController.swift
//  ownCloud
//
//  Created by Felix Schwarz on 11.09.23.
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

class BookmarkSetupStepIntroViewController: BookmarkSetupStepViewController {
	override func loadView() {
		super.loadView()

		var logoImage = AccountSettingsProvider.shared.logo

		continueButtonLabelText = "Start setup".localized

		if let tintImageColor = Theme.shared.activeCollection.css.getThemeCSSColor(.fill, selectors: [.accountSetup, .welcome, .icon]) {
			if let tintedLogoImage = logoImage.tinted(with: tintImageColor) {
				logoImage = tintedLogoImage
			}
		}

		let messageView = ComposedMessageView(elements: [
			.image(logoImage, size: CGSize(width: 128, height: 128), adaptSizeToRatio: true, cssSelectors: [.icon], insets: .zero),
			.title(String(format: "Welcome to %@".localized, VendorServices.shared.appName), alignment: .centered, cssSelectors: [.title], insets: NSDirectionalEdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0)),
			.subtitle("The following steps will guide you through the setup process.".localized, alignment: .centered, cssSelectors: [.message])
		])
		messageView.elementInsets = .zero
		messageView.cssSelectors = [ .welcome ]

		contentView = messageView
	}

	override func handleContinue() {
		setupViewController?.composer?.doneIntro()
	}
}
