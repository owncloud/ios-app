//
//  AcknowledgementsTableViewController.swift
//  ownCloud
//
//  Created by Felix Schwarz on 15.10.21.
//  Copyright © 2021 ownCloud GmbH. All rights reserved.
//

import UIKit
import ownCloudSDK
import ownCloudAppShared

class AcknowledgementsTableViewController: StaticTableViewController {

	var licensesSection : StaticTableViewSection?

	override func viewDidLoad() {
		super.viewDidLoad()
		navigationItem.title = "Acknowledgements".localized

		addSection(StaticTableViewSection(headerTitle: "", footerTitle: nil, identifier: nil, rows: [
			StaticTableViewRow(message: "Portions of this app may utilize the following copyrighted material, the use of which is hereby acknowledged.".localized, style: .text)
		]))

		let context = OCExtensionContext(location: OCExtensionLocation(ofType: .license, identifier: nil), requirements: nil, preferences: nil)

		OCExtensionManager.shared.provideExtensions(for: context, completionHandler: { (_, context, licenses) in
			OnMainThread {
				let licensesSection = StaticTableViewSection(headerTitle: "")

				if let licenses = licenses {
					for licenseExtensionMatch in licenses {
						let extensionObject = licenseExtensionMatch.extension.provideObject(for: context)

						if let licenseDict = extensionObject as? [String : Any],
						   let licenseTitle = licenseDict["title"] as? String,
						   let licenseURL = licenseDict["url"] as? URL {
							licensesSection.insert(row: StaticTableViewRow(rowWithAction: { row, _ in
								let textViewController = TextViewController()
								let licenseText : NSMutableAttributedString = NSMutableAttributedString()
								let textAttributes : [NSAttributedString.Key : Any] = [
									.font : UIFont.systemFont(ofSize: UIFont.systemFontSize)
								]

								textViewController.title = "\(licenseTitle) \("license".localized)"
								textViewController.navigationItem.largeTitleDisplayMode = .never

								// License text
								do {
									var encoding : String.Encoding = .utf8
									let licenseFileContents = try String(contentsOf: licenseURL, usedEncoding: &encoding)

									licenseText.append(NSAttributedString(string: "\n" + licenseFileContents + "\n\n", attributes: textAttributes))
								} catch {
								}

								textViewController.attributedText = licenseText

								row.viewController?.navigationController?.pushViewController(textViewController, animated: true)
							}, title: licenseTitle, accessoryType: .disclosureIndicator), at: 0)
						}
					}
				}

				self.addSection(licensesSection, animated: false)
			}
		})
    }
}
