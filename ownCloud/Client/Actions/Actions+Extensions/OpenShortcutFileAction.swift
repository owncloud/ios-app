//
//  OpenShortcutFileAction.swift
//  ownCloud
//
//  Created by Felix Schwarz on 16.04.24.
//  Copyright © 2024 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2024, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import UIKit
import ownCloudSDK
import ownCloudAppShared

class OpenShortcutFileAction: Action {
	override open class var identifier : OCExtensionIdentifier? { return OCExtensionIdentifier("com.owncloud.action.openShortcutFile") }
	override open class var category : ActionCategory? { return .normal }
	override open class var name : String? { return "Open shortcut".localized }
	override open class var locations : [OCExtensionLocationIdentifier]? { return [.directOpen] }

	// MARK: - Extension matching
	override open class func applicablePosition(forContext: ActionContext) -> ActionPosition {
		if forContext.items.count > 1 {
			return .none
		}

		if forContext.items.first?.type == .collection {
			return .none
		}

		if forContext.core?.connectionStatus != .online {
			return .none
		}

		guard let mimeType = forContext.items.first?.mimeType, mimeType == "text/uri-list" else {
			return .none
		}

		return .first
	}

	// MARK: - Action implementation
	override open func run() {
		guard context.items.count > 0, let item = context.items.first else {
			completed(with: NSError(ocError: .itemNotFound))
			return
		}

		if let core = context.core {
			_ = core.downloadItem(item, resultHandler: { error, core, item, file in
				if let error {
					OnMainThread {
						self.open(error: error)
					}
				} else if let fileURL = file?.url, let core = self.context.clientContext?.core {
					INIFile.resolveShortcutFile(at: fileURL, core: core, result: { error, url, item in
						OnMainThread {
							self.open(error: error, url: url, item: item)
						}
					})
				}
			})
		}
	}

	func open(error: Error? = nil, url: URL? = nil, item: OCItem? = nil) {
		if let error {
			let alertController = ThemedAlertController(with: "An error occurred".localized, message: error.localizedDescription, okLabel: "OK".localized, action: nil)
			self.context.viewController?.present(alertController, animated: true)
		} else if let item {
			_ = item.openItem(from: context.viewController, with: context.clientContext, animated: true, pushViewController: true, completion: nil)
		} else if let url {
			let alert = ThemedAlertController(title: "Shortcut to '{{hostname}}'".localized(["hostname" : url.host ?? "URL"]), message: "This shortcut points to:\n\n{{url}}\n\nShould it be opened in the default browser?".localized(["url" :  url.absoluteString]), preferredStyle: .alert)
			alert.addAction(UIAlertAction(title: "Open".localized, style: .default, handler: { _ in
				UIApplication.shared.open(url) { success in
					if !success {
						OnMainThread {
							let alert = ThemedAlertController(title: "Opening link failed".localized, message: nil, preferredStyle: .alert)
							alert.addAction(UIAlertAction(title: "OK".localized, style: .default))
							self.context.viewController?.present(alert, animated: true)
						}
					}
				}
			}))
			alert.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel))
			self.context.viewController?.present(alert, animated: true)
		}
	}

	override open class func iconForLocation(_ location: OCExtensionLocationIdentifier) -> UIImage? {
		return UIImage(systemName: "arrow.up.forward.square")?.withRenderingMode(.alwaysTemplate)
	}
}
