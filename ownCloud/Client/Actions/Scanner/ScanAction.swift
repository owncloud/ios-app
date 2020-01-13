//
//  ScanAction.swift
//  ownCloud
//
//  Created by Felix Schwarz on 28.08.19.
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

import ownCloudSDK
import ownCloudApp
import ownCloudAppShared
import VisionKit

class ScanAction: Action, VNDocumentCameraViewControllerDelegate {
	override class var identifier : OCExtensionIdentifier? { return OCExtensionIdentifier("com.owncloud.action.scan") }
	override class var category : ActionCategory? { return .normal }
	override class var name : String? { return "Scan document".localized }
	override class var locations : [OCExtensionLocationIdentifier]? { return [ .folderAction, .keyboardShortcut ] }
	override class var keyCommand : String? { return "S" }
	override class var keyModifierFlags: UIKeyModifierFlags? { return [.command, .alternate] }
	override class var licenseRequirements: LicenseRequirements? { return LicenseRequirements(feature: .documentScanner) }

	// MARK: - Extension matching
	override class func applicablePosition(forContext: ActionContext) -> ActionPosition {
		if forContext.items.count > 1 {
			return .none
		}

		if forContext.items.first?.type != OCItemType.collection {
			return .none
		}

		if #available(iOS 13.0, *) {
			return .middle
		} else {
			return .none
		}
	}

	// MARK: - Action implementation
	override func run() {
		guard let viewController = context.viewController else {
			return
		}

		guard self.proceedWithLicensing(from: viewController) else {
			return
		}

		guard context.items.count > 0 else {
			completed(with: NSError(ocError: .itemNotFound))
			return
		}

		guard let targetFolderItem = context.items.first, let itemPath = targetFolderItem.path else {
			completed(with: NSError(ocError: .itemNotFound))
			return
		}

		guard let core = context.core else {
			completed(with: NSError(ocError: .internal))
			return
		}

		if #available(iOS 13.0, *) {
			Scanner.scan(on: viewController) { [weak core] (_, _, scan) in
				if let pageCount = scan?.pageCount, pageCount > 0, let scannedPages = scan?.scannedPages {
					var filename : String? = scan?.title

					if filename?.count == 0 {
						filename = nil
					}

					core?.suggestUnusedNameBased(on: filename ?? "\("Scan".localized) \(DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .medium)).pdf", atPath: itemPath, isDirectory: true, using: .bracketed, filteredBy: nil, resultHandler: { (suggestedName, _) in
						guard let suggestedName = suggestedName else { return }

						OnMainThread {
							let navigationController = ThemeNavigationController(rootViewController: ScanViewController(with: scannedPages, core: core, fileName: suggestedName, targetFolder: targetFolderItem))
							viewController.present(navigationController, animated: true)
						}
					})
				}

			}
		}
	}

	override class func iconForLocation(_ location: OCExtensionLocationIdentifier) -> UIImage? {
		if location == .folderAction {
			if #available(iOS 13.0, *) {
				return UIImage(systemName: "doc.text.viewfinder", withConfiguration: UIImage.SymbolConfiguration(pointSize: 26, weight: .regular))
			}
//			Theme.shared.add(tvgResourceFor: "application-pdf")
//			return Theme.shared.image(for: "application-pdf", size: CGSize(width: 30.0, height: 30.0))!.withRenderingMode(.alwaysTemplate)
		}

		return nil
	}
}
