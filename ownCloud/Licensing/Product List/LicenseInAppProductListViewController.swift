//
//  LicenseInAppProductListViewController.swift
//  ownCloud
//
//  Created by Felix Schwarz on 14.01.20.
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
import ownCloudApp
import ownCloudAppShared

class LicenseInAppProductListViewController: StaticTableViewController {
	init() {
		super.init(style: .grouped)

		self.navigationItem.title = "Pro Features".localized

		self.toolbarItems = [
			UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
			UIBarButtonItem(title: "Restore purchases".localized, style: .plain, target: self, action: #selector(restorePurchases)),
			UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
		]

		NotificationCenter.default.addObserver(self, selector: #selector(bookmarkManagerListUpdated(_:)), name: .OCBookmarkManagerListChanged, object: nil)
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	deinit {
		NotificationCenter.default.removeObserver(self, name: .OCBookmarkManagerListChanged, object: nil)
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		self.navigationController?.toolbar.isTranslucent = false
		self.navigationController?.isToolbarHidden = false

		provideContent()
	}

	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)

		self.navigationController?.isToolbarHidden = true
	}

	@objc func bookmarkManagerListUpdated(_ notification: Notification?) {
		OnMainThread { [weak self] in
			self?.generateContent()
		}
	}

	func provideContent() {
		OCLicenseManager.appStoreProvider?.refreshProductsIfNeeded(completionHandler: { [weak self] (error) in
			OnMainThread {
				if error != nil {
					let alertController = ThemedAlertController(with: "Error loading product info from App Store".localized, message: error!.localizedDescription, action: { [weak self] in
						self?.navigationController?.popViewController(animated: true)
					})

					self?.present(alertController, animated: true)
				} else {
					self?.generateContent()
				}
			}
		})
	}

	private weak var proFeaturesSection : StaticTableViewSection?
	private weak var noBookmarksSection : StaticTableViewSection?

	func generateContent() {
		if OCBookmarkManager.shared.bookmarks.count == 0 {
			if noBookmarksSection == nil {
				let section = StaticTableViewSection(headerTitle: "", identifier: "no-bookmarks")

				section.add(row: StaticTableViewRow(message: "In order to accurately determine your current licensing status, please add one or more accounts first.".localized, title: "No accounts found".localized, style: .warning))

				noBookmarksSection = section
				self.addSection(section)
			}
		} else {
			if let noBookmarksSection = noBookmarksSection {
				self.removeSection(noBookmarksSection)
			}
		}

		if proFeaturesSection == nil {
			let section = StaticTableViewSection(headerTitle: "Pro Features".localized, identifier: "pro-features")
			let environment = OCLicenseEnvironment()

			if let iapMessages = OCLicenseManager.shared.inAppPurchaseMessage(forFeature: nil) {
				let messageRow = StaticTableViewRow(message: iapMessages, icon: UIImage(named: "info-icon")?.scaledImageFitting(in: CGSize(width: 24, height: 24)), style: .warning, identifier: "iap-messages")

				section.add(row: messageRow)
			}

			if let features = OCLicenseManager.shared.features(withOffers: true) {
				for feature in features {
					section.add(row: StaticTableViewRow(customView: LicenseInAppPurchaseFeatureView(with: feature, in: environment, baseViewController: self), inset: UIEdgeInsets(top: 15, left: 18, bottom: 15, right: 18)))
				}
			}

			if section.rows.count > 0 {
				proFeaturesSection = section
				self.addSection(section)
			}
		}
	}

	@objc func restorePurchases() {
		OCLicenseManager.shared.restorePurchases(on: self) { (error) in
			if error == nil {
				self.removeSections(self.sections)
				self.generateContent()
			}
		}
	}

}
