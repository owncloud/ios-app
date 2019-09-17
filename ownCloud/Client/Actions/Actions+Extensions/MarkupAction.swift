//
//  MarkupAction.swift
//  ownCloud
//
//  Created by Matthias Hühne on 16/09/2019.
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
import PencilKit

@available(iOS 13.0, *)
class MarkupAction : Action {
	override class var identifier : OCExtensionIdentifier? { return OCExtensionIdentifier("com.owncloud.action.markup") }
	override class var category : ActionCategory? { return .normal }
	override class var name : String? { return "Markup".localized }
	override class var keyCommand : String? { return "M" }
	override class var locations : [OCExtensionLocationIdentifier]? { return [.moreItem, .moreFolder] }

	// MARK: - Extension matching
	override class func applicablePosition(forContext: ActionContext) -> ActionPosition {
		guard let viewController = forContext.viewController as? PreviewViewController, let window = viewController.view.window, let toolPicker = PKToolPicker.shared(for: window) else {
			return .none
		}

		if toolPicker.isVisible {
			return .none
		}

		// Examine items in context
		return .middle
	}

	// MARK: - Action implementation
	override func run() {
		guard context.items.count > 0, let viewController = context.viewController as? PreviewViewController, let window = viewController.view.window, let toolPicker = PKToolPicker.shared(for: window) else {
			self.completed(with: NSError(ocError: .insufficientParameters))
			return
		}

		viewController.view.addSubview(viewController.canvasView)

		let canvasView = viewController.canvasView
		NSLayoutConstraint.activate([
			canvasView.topAnchor.constraint(equalTo: viewController.view.topAnchor),
			canvasView.bottomAnchor.constraint(equalTo: viewController.view.bottomAnchor),
			canvasView.leadingAnchor.constraint(equalTo: viewController.view.leadingAnchor),
			canvasView.trailingAnchor.constraint(equalTo: viewController.view.trailingAnchor)
		])

		toolPicker.setVisible(true, forFirstResponder: viewController.canvasView)
		toolPicker.addObserver(viewController.canvasView)
		viewController.canvasView.becomeFirstResponder()

		print("--> viewController.parent \(viewController.parent)")
		print("--> viewController.parent.parent \(viewController.parent?.parent)")

		guard let displayViewController = viewController.parent as? DisplayHostViewController else {
			return
		}

		displayViewController.isPagingEnabled = false
	}

	override class func iconForLocation(_ location: OCExtensionLocationIdentifier) -> UIImage? {
		if location == .moreItem || location == .moreFolder {
			return UIImage(named: "folder")
		}

		return nil
	}
}
