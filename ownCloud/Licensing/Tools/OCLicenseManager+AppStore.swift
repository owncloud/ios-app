//
//  OCLicenseManager+AppStore.swift
//  ownCloud
//
//  Created by Felix Schwarz on 12.12.19.
//  Copyright © 2019 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2019, ownCloud GmbH.
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

extension OCLicenseManager {
	@objc func restorePurchases(on viewController: UIViewController, with completionHandler: OCLicenseAppStoreRestorePurchasesCompletionHandler? = nil) {
		if let appStoreProvider = OCLicenseManager.appStoreProvider {
			let hud : ProgressHUDViewController? = ProgressHUDViewController(on: nil)

			hud?.present(on: viewController, label: "Restoring purchases…".localized)

			appStoreProvider.restorePurchases(completionHandler: { (error) in
				let completion = {
					OnMainThread {
						if let error = error {
							let alert = ThemedAlertController(title: "Error restoring purchases".localized, message: error.localizedDescription, preferredStyle: .alert)

							alert.addAction(UIAlertAction(title: "OK".localized, style: .default, handler: nil))

							viewController.present(alert, animated: true, completion: nil)
						}

						completionHandler?(error)
					}
				}

				OnMainThread {
					if hud != nil {
						hud?.dismiss(completion: completion)
					} else {
						completion()
					}
				}
			})
		}
	}

}
