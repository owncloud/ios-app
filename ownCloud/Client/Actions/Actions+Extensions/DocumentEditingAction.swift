//
//  DocumentEditingAction.swift
//  ownCloud
//
//  Created by Matthias Hühne on 21/01/2020.
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

@available(iOS 13.0, *)
class DocumentEditingAction : Action {
	override class var identifier : OCExtensionIdentifier? { return OCExtensionIdentifier("com.owncloud.action.markup") }
	override class var category : ActionCategory? { return .normal }
	override class var name : String? { return "Markup".localized }
	override class var keyCommand : String? { return "E" }
	override class var keyModifierFlags: UIKeyModifierFlags? { return [.command] }
	override class var locations : [OCExtensionLocationIdentifier]? { return [.moreItem, .moreFolder, .keyboardShortcut, .contextMenuItem] }
	class var supportedMimeTypes : [String] { return ["image", "pdf"] }
	class var excludedMimeTypes : [String] { return ["image/x-dcraw", "image/heic"] }
	override class var licenseRequirements: LicenseRequirements? { return LicenseRequirements(feature: .documentMarkup) }

	// MARK: - Extension matching
	override class func applicablePosition(forContext: ActionContext) -> ActionPosition {
		if let core = forContext.core, forContext.items.count == 1, forContext.items.contains(where: {$0.type == .file && ($0.permissions.contains(.writable) || $0.parentItem(from: core)? .permissions.contains(.createFile) == true)}) {
			if let item = forContext.items.first, let mimeType = item.mimeType {
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
		}

		// Examine items in context
		return .none
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
				if let fileURL = files.first?.url, let item = self.context.items.first {
					let editDocumentViewController = EditDocumentViewController(with: fileURL, item: item, core: self.core)
					let navigationController = ThemeNavigationController(rootViewController: editDocumentViewController)
					navigationController.modalPresentationStyle = .overFullScreen
					viewController.present(navigationController, animated: true)
				}
			}
		}

		hudViewController.presentHUDOn(viewController: hostViewController)

		self.completed()
	}

	override class func iconForLocation(_ location: OCExtensionLocationIdentifier) -> UIImage? {
		if location == .moreItem || location == .moreFolder || location == .contextMenuItem {
			return UIImage(systemName: "pencil.tip.crop.circle")?.withRenderingMode(.alwaysTemplate)
		}

		return nil
	}
}
