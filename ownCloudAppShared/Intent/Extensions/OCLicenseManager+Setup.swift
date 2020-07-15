//
//  OCLicenseManager+Setup.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 13.01.20.
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

import ownCloudApp

public extension OCLicenseFeatureIdentifier {
	static var documentScanner : OCLicenseFeatureIdentifier { return OCLicenseFeatureIdentifier(rawValue: "document-scanner") }
	static var shortcuts : OCLicenseFeatureIdentifier { return OCLicenseFeatureIdentifier(rawValue: "shortcuts") }
	static var documentMarkup : OCLicenseFeatureIdentifier { return OCLicenseFeatureIdentifier(rawValue: "document-markup") }
}

public extension OCLicenseProductIdentifier {
	static var singleDocumentScanner : OCLicenseProductIdentifier { return OCLicenseProductIdentifier(rawValue: "single.document-scanner") }
	static var singleShortcuts : OCLicenseProductIdentifier { return OCLicenseProductIdentifier(rawValue: "single.shortcuts") }
	static var singleDocumentMarkup : OCLicenseProductIdentifier { return OCLicenseProductIdentifier(rawValue: "single.document-markup") }

	static var bundlePro : OCLicenseProductIdentifier { return OCLicenseProductIdentifier(rawValue: "bundle.pro") }
}

private var OCLicenseManagerHasBeenSetup : Bool = false

public extension OCLicenseManager {
	func setupLicenseManagement() {
		if OCLicenseManagerHasBeenSetup {
			return
		}

		OCLicenseManagerHasBeenSetup = true

		// Set up features and products
		let documentScannerFeature = OCLicenseFeature(identifier: .documentScanner, name: "Document Scanner".localized, description: "Scan documents and photos with your camera.".localized)
		let shortcutsFeature = OCLicenseFeature(identifier: .shortcuts, name: "Shortcuts Actions".localized, description: "Use ownCloud actions in Shortcuts.".localized)
		let documentMarkupFeature = OCLicenseFeature(identifier: .documentMarkup, name: "Markup Documents".localized, description: "Markup photos and PDF files.".localized)

		// - Features
		register(documentScannerFeature)
		register(shortcutsFeature)
		register(documentMarkupFeature)

		// - Single feature products
		register(OCLicenseProduct(identifier: .singleDocumentScanner, name: documentScannerFeature.localizedName!, description: documentScannerFeature.localizedDescription, contents: [.documentScanner]))
		register(OCLicenseProduct(identifier: .singleShortcuts, name: shortcutsFeature.localizedName!, description: shortcutsFeature.localizedDescription, contents: [.shortcuts]))
		register(OCLicenseProduct(identifier: .singleDocumentMarkup, name: documentMarkupFeature.localizedName!, description: documentMarkupFeature.localizedDescription, contents: [.documentMarkup]))

		// - Subscription
		register(OCLicenseProduct(identifier: .bundlePro, name: "Pro Features".localized, description: "Unlock all Pro Features.".localized, contents: [.documentScanner, .shortcuts, .documentMarkup]))

		// Set up App Store License Provider
		if !OCLicenseEMMProvider.isEMMVersion { // only add AppStore IAP provider (and IAPs) if this is not the EMM version (which is supposed to already include all of them)
			let appStoreLicenseProvider = OCLicenseAppStoreProvider(items: [
				OCLicenseAppStoreItem.nonConsumableIAP(withAppStoreIdentifier: "single.documentscanner", productIdentifier: .singleDocumentScanner),
				OCLicenseAppStoreItem.nonConsumableIAP(withAppStoreIdentifier: "single.shortcuts", productIdentifier: .singleShortcuts),
				OCLicenseAppStoreItem.nonConsumableIAP(withAppStoreIdentifier: "single.documentmarkup", productIdentifier: .singleDocumentMarkup),
				OCLicenseAppStoreItem.subscription(withAppStoreIdentifier: "bundle.pro", productIdentifier: .bundlePro, trialDuration: OCLicenseDuration(unit: .day, length: 14))
			])

			add(appStoreLicenseProvider)
		}

		// Set up Enterprise Provider
		let enterpriseProvider = OCLicenseEnterpriseProvider(unlockedProductIdentifiers: [.bundlePro])

		add(enterpriseProvider)

		// Set up EMM Provider
		let emmProvider = OCLicenseEMMProvider(unlockedProductIdentifiers: [.bundlePro])

		add(emmProvider)
	}
}
