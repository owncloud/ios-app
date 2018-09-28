//
//  PDFViewerViewController.swift
//  ownCloud
//
//  Created by Pablo Carrascal on 29/08/2018.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

import UIKit
import ownCloudSDK
import PDFKit

class PDFViewerViewController: DisplayViewController, DisplayViewProtocol {

	static var supportedMimeTypes: [String] = ["application/pdf"]
	static var features: [String : Any]? = [FeatureKeys.canEdit : true]

	static func normalPDFExtension(identifier: String) -> OCExtension {
		let rawIdentifier: OCExtensionIdentifier =  OCExtensionIdentifier(rawValue: identifier)
		let locationIdentifier = OCExtensionLocationIdentifier(rawValue: supportedMimeTypes[0])
		let features: [String : Any] = PDFViewerViewController.features!

		let normalPDFExtension = OCExtension(identifier: rawIdentifier, type: .viewer, location: locationIdentifier, features: features) { (_ rawExtension, _ context, _ error) -> Any? in
			return PDFViewerViewController()
		}

		return normalPDFExtension!
	}

	override func renderSpecificView() {
		if let document = PDFDocument(url: source) {
			let thumbnailsView = PDFThumbnailView(frame: .zero)
			thumbnailsView.translatesAutoresizingMaskIntoConstraints = false
			view.addSubview(thumbnailsView)
			NSLayoutConstraint.activate([
				thumbnailsView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
				thumbnailsView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
				thumbnailsView.leftAnchor.constraint(equalTo: view.leftAnchor),
				thumbnailsView.widthAnchor.constraint(equalToConstant: 70)
				])

			thumbnailsView.thumbnailSize = CGSize(width: 70, height: 50)

			let ocPDFView = PDFView(frame: .zero)
			ocPDFView.translatesAutoresizingMaskIntoConstraints = false
			view.addSubview(ocPDFView)
			NSLayoutConstraint.activate([
				ocPDFView.topAnchor.constraint(equalTo: view.topAnchor),
				ocPDFView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
				ocPDFView.leftAnchor.constraint(equalTo: thumbnailsView.rightAnchor),
				ocPDFView.rightAnchor.constraint(equalTo: view.rightAnchor)
				])

			ocPDFView.document = document
			ocPDFView.autoScales = true
			ocPDFView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
			ocPDFView.displayMode = .singlePageContinuous
			thumbnailsView.pdfView = ocPDFView
		} else {
			view.backgroundColor = .red
		}
	}

	func save(item: OCItem) {
		editingDelegate?.save(item: item, fileURL: source)
	}
}
