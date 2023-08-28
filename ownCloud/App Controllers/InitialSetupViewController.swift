//
//  InitialSetupViewController.swift
//  ownCloud
//
//  Created by Felix Schwarz on 28.08.23.
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
import ownCloudApp
import ownCloudAppShared

class InitialSetupViewController: UIViewController {
	override var preferredStatusBarStyle : UIStatusBarStyle {
		return Theme.shared.activeCollection.css.getStatusBarStyle(for: self) ?? .default
	}

	override func loadView() {
		cssSelectors = [.modal, .welcome]

		var addAccountTitle = "Add account".localized
		if !VendorServices.shared.canAddAccount {
			addAccountTitle = "Login".localized
		}

		let messageView = ComposedMessageView.infoBox(additionalElements: [
			.image(AccountSettingsProvider.shared.logo, size: CGSize(width: 128, height: 128), cssSelectors: [.icon]),
			.title(String(format: "Welcome to %@".localized, VendorServices.shared.appName), alignment: .centered, cssSelectors: [.title], insets: NSDirectionalEdgeInsets(top: 25, leading: 0, bottom: 25, trailing: 0)),
			.button(addAccountTitle, action: UIAction(handler: { [weak self] action in
				if let self = self {
					BookmarkViewController.showBookmarkUI(on: self, attemptLoginOnSuccess: true)
				}
			}), image: UIImage(systemName: "plus.circle"), cssSelectors: [.welcome]),
			.button("Settings".localized ,action: UIAction(handler: { [weak self] action in
				if let self = self {
					self.present(ThemeNavigationController(rootViewController: SettingsViewController()), animated: true)
				}
			}), image: UIImage(systemName: "gearshape"), cssSelectors: [.welcome])
		])
		messageView.elementInsets = NSDirectionalEdgeInsets(top: 25, leading: 50, bottom: 50, trailing: 50)

		let rootView = ThemeCSSView(withSelectors: [])

		if let image = Branding.shared.brandedImageNamed(.loginBackground) {
			messageView.isOpaque = false
			let backgroundImageView = UIImageView(image: image)
			backgroundImageView.contentMode = .scaleAspectFill
			rootView.embed(toFillWith: backgroundImageView)
		}

		rootView.embed(centered: messageView, minimumInsets: NSDirectionalEdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20))

		view = rootView
	}
}
