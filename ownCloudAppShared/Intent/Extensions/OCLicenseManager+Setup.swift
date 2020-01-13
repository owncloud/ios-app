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
}

public extension OCLicenseProductIdentifier {
	static var singleDocumentScanner : OCLicenseProductIdentifier { return OCLicenseProductIdentifier(rawValue: "single.document-scanner") }
	static var singleShortcuts : OCLicenseProductIdentifier { return OCLicenseProductIdentifier(rawValue: "single.shortcuts") }

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
		register(OCLicenseFeature(identifier: .documentScanner))
		register(OCLicenseFeature(identifier: .shortcuts))

		register(OCLicenseProduct(identifier: .singleDocumentScanner, name: "Document scanner".localized, description: "Allows scanning documents and photos with the camera of your device", contents: [.documentScanner]))

		register(OCLicenseProduct(identifier: .singleShortcuts, name: "Shortcuts".localized, description: "Use ownCloud in your Shortcut workflows", contents: [.shortcuts]))

		register(OCLicenseProduct(identifier: .bundlePro, name: "Pro Features".localized, description: "Pro Features include the document scanner", contents: [.documentScanner, .shortcuts]))

		// Set up App Store License Provider
		let appStoreLicenseProvider = OCLicenseAppStoreProvider(items: [
			OCLicenseAppStoreItem.nonConsumableIAP(withAppStoreIdentifier: "single.documentsharing", productIdentifier: .singleDocumentScanner),
			OCLicenseAppStoreItem.subscription(withAppStoreIdentifier: "bundle.pro", productIdentifier: .bundlePro, trialDuration: OCLicenseDuration(unit: .day, length: 14))
		])

		add(appStoreLicenseProvider)

		// Set up Enterprise Provider
		let enterpriseProvider = OCLicenseEnterpriseProvider(unlockedProductIdentifiers: [.bundlePro])

		add(enterpriseProvider)
	}
}
