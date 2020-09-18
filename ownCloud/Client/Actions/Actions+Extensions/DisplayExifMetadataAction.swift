//
//  DisplayExifMetadataAction.swift
//  ownCloud
//
//  Created by Michael Neuwert on 29.06.20.
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

import ownCloudSDK
import ownCloudAppShared

class DisplayExifMetadataAction : Action {
	override class var identifier : OCExtensionIdentifier? { return OCExtensionIdentifier("com.owncloud.action.show-exif") }
	override class var category : ActionCategory? { return .normal }
	override class var name : String? { return "Image Metadata".localized }
	override class var locations : [OCExtensionLocationIdentifier]? { return [.moreItem, .moreFolder, .contextMenuItem] }
	class var supportedMimeTypes : [String] { return ["image"] }
	class var excludedMimeTypes : [String] { return ["image/gif", "image/svg"] }

	override class var keyCommand : String? { return "I" }
	override class var keyModifierFlags: UIKeyModifierFlags? { return [.command] }

	override class var licenseRequirements: LicenseRequirements? { return LicenseRequirements(feature: .photoProFeatures) }

	// MARK: - Extension matching
	override class func applicablePosition(forContext: ActionContext) -> ActionPosition {
		if forContext.items.count == 1, let item = forContext.items.first, item.type == .file, let mimeType = item.mimeType {

			if supportedMimeTypes.filter({
				if mimeType.contains($0) {
					if excludedMimeTypes.filter({
						return mimeType.contains($0)
					}).count == 0 {
						return true
					}
				}
				return false
			}).count > 0 {
				return .middle
			}
		}

		// Examine items in context
		return .none
	}

	override class func iconForLocation(_ location: OCExtensionLocationIdentifier) -> UIImage? {
		if location == .moreItem || location == .moreFolder || location == .contextMenuItem {
			return UIImage(named: "camera-info")?.withRenderingMode(.alwaysTemplate)
		}
		return nil
	}

	// MARK: - Action implementation
	override func run() {
		guard context.items.count > 0, let hostViewController = context.viewController, let core = self.core else {
			self.completed(with: NSError(ocError: .insufficientParameters))
			return
		}

		guard self.proceedWithLicensing(from: hostViewController) else {
			return
		}

		let hudViewController = DownloadItemsHUDViewController(core: core, downloadItems: context.items) { [weak hostViewController] (error, files) in
			if let error = error {
				if (error as NSError).isOCError(withCode: .cancelled) {
					return
				}

				let appName = OCAppIdentity.shared.appName ?? "ownCloud"
				let alertController = ThemedAlertController(with: "Cannot connect to ".localized + appName, message: appName + " couldn't download file(s)".localized, okLabel: "OK".localized, action: nil)

				hostViewController?.present(alertController, animated: true)
			} else {
				guard let files = files, files.count > 0, let viewController = hostViewController else { return }

				if let item = self.context.items.first, let sourceURL = files.first?.url {
					let metadataViewController = ImageMetadataViewController(core: core, item: item, url: sourceURL)
					let navigationController = ThemeNavigationController(rootViewController: metadataViewController)
					navigationController.modalPresentationStyle = .formSheet
					if #available(iOS 13, *) {
						navigationController.modalPresentationStyle = .automatic
					}
					viewController.present(navigationController, animated: true)
				}
			}
		}

		hudViewController.presentHUDOn(viewController: hostViewController)

		self.completed()
	}
}
