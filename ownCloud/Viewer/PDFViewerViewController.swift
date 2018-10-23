//
//  PDFViewerViewController.swift
//  ownCloud
//
//  Created by Pablo Carrascal on 29/08/2018.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2018, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import UIKit
import ownCloudSDK
import PDFKit

class PDFViewerViewController: DisplayViewController, DisplayExtension {

	static var customMatcher: OCExtensionCustomContextMatcher?
	static var displayExtensionIdentifier: String = "org.owncloud.pdfViewer.default"
	static var supportedMimeTypes: [String]? = ["application/pdf"]
	static var features: [String : Any]? = [FeatureKeys.canEdit : false]

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

			let pdfView = PDFView(frame: .zero)
			pdfView.translatesAutoresizingMaskIntoConstraints = false
			view.addSubview(pdfView)
			NSLayoutConstraint.activate([
				pdfView.topAnchor.constraint(equalTo: view.topAnchor),
				pdfView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
				pdfView.leftAnchor.constraint(equalTo: thumbnailsView.rightAnchor),
				pdfView.rightAnchor.constraint(equalTo: view.rightAnchor)
				])

			pdfView.document = document
			pdfView.autoScales = true
			pdfView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
			pdfView.displayMode = .singlePageContinuous
			thumbnailsView.pdfView = pdfView
		} else {
			view.backgroundColor = .red
		}
	}
}
