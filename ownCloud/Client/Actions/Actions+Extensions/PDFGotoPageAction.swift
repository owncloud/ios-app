//
//  PDFGoToPageAction.swift
//  ownCloud
//
//  Created by Matthias Hühne on 17/03/2021.
//  Copyright © 2021 ownCloud GmbH. All rights reserved.
//

/*
* Copyright (C) 2021, ownCloud GmbH.
*
* This code is covered by the GNU Public License Version 3.
*
* For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
* You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
*
*/

import ownCloudSDK
import ownCloudAppShared

class PDFGoToPageAction : Action {
	override class var identifier : OCExtensionIdentifier? { return OCExtensionIdentifier("com.owncloud.action.pdfpage") }
	override class var category : ActionCategory? { return .normal }
	override class var name : String? { return "Go to page".localized }
	override class var keyCommand : String? { return "G" }
	override class var keyModifierFlags: UIKeyModifierFlags? { return [.command] }
	override class var locations : [OCExtensionLocationIdentifier]? { return [.moreDetailItem, .keyboardShortcut] }

	// MARK: - Extension matching
	override class func applicablePosition(forContext: ActionContext) -> ActionPosition {
		if forContext.items.count == 1, ((forContext.viewController as? PDFViewerViewController) != nil) {
			return .first
		}

		return .none
	}

	// MARK: - Action implementation
	override func run() {
		guard context.items.count > 0, let viewController = context.viewController as? PDFViewerViewController else {
			self.completed(with: NSError(ocError: .insufficientParameters))
			return
		}

		viewController.goToPage()
	}

	override class func iconForLocation(_ location: OCExtensionLocationIdentifier) -> UIImage? {
		if location == .moreDetailItem {
			if #available(iOS 13.0, *) {
				return UIImage(systemName: "arrow.up.doc")?.withRenderingMode(.alwaysTemplate)
			} else {
				return UIImage(named: "ic_pdf_go_to_page")
			}
		}

		return nil
	}
}
