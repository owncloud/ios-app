//
//  OCExtension+DisplayView.swift
//  ownCloud
//
//  Created by Pablo Carrascal on 30/08/2018.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

import ownCloudSDK

extension OCDisplayExtension {

	static func normalPDFExtension(identifier: String) -> OCDisplayExtension {
		let rawIdentifier: OCExtensionIdentifier =  OCExtensionIdentifier(rawValue: identifier)
		let locationIdentifier = OCExtensionLocationIdentifier(rawValue: "viewer")
		let location: OCDisplayExtensionLocation = OCDisplayExtensionLocation(type: .viewer, identifier: locationIdentifier, supportedMimeTypes: PDFViewerViewController.supportedMimeTypes)
		let features: [String : Any] = PDFViewerViewController.features!

		let normalPDFExtension = OCDisplayExtension(identifier: rawIdentifier, type: .viewer, location: location, features: features) { (_ rawExtension, _ context, _ error) -> Any? in
			return PDFViewerViewController()
		}

		return normalPDFExtension
	}

	static func webViewExtension(identifier: String) -> OCDisplayExtension {
		let rawIdentifier: OCExtensionIdentifier =  OCExtensionIdentifier(rawValue: identifier)
		let locationIdentifier: OCExtensionLocationIdentifier = OCExtensionLocationIdentifier(rawValue: "viewer")
		let location: OCDisplayExtensionLocation = OCDisplayExtensionLocation(type: .viewer, identifier: locationIdentifier, supportedMimeTypes: WebViewDisplayViewController.supportedMimeTypes)
		let features: [String : Any] = WebViewDisplayViewController.features!

		let webViewExtension = OCDisplayExtension(identifier: rawIdentifier, type: .viewer, location: location, features: features) { (_ rawExtension, _ context, _ error) -> Any? in
			return WebViewDisplayViewController()
		}

		return webViewExtension
	}
}

extension OCExtensionType {
	static let viewer: OCExtensionType  =  OCExtensionType(rawValue: "viewer")
}
