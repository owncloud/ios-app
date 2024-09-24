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

public extension OCClassSettingsKey {
	static let openShortcutMode = OCClassSettingsKey("open-shortcut-mode")
}

public enum OpenShortcutActionMode: String {
	case all = "all"
	case itemsOnly = "items-only"
	case linksOnly = "links-only"
	case none = "none"
}

class OpenShortcutFileAction: Action {
	public static func registerSettings() {
		self.registerOCClassSettingsDefaults([
			.openShortcutMode : OpenShortcutActionMode.all.rawValue
		], metadata: [
			.openShortcutMode : [
				.type 		: OCClassSettingsMetadataType.string,
				.label		: "Open Shortcut mode",
				.description 	: "Determines how the app opens shortcut files (ending in `.url`) app.",
				.status		: OCClassSettingsKeyStatus.advanced,
				.category	: "Actions",
				.possibleValues : [
					[
						OCClassSettingsMetadataKey.value 	: OpenShortcutActionMode.all.rawValue,
						OCClassSettingsMetadataKey.description 	: "Open all shortcut files, targeting both links (web and other) and items."
					],
					[
						OCClassSettingsMetadataKey.value 	: OpenShortcutActionMode.itemsOnly.rawValue,
						OCClassSettingsMetadataKey.description 	: "Open only shortcut files that target items."
					],
					[
						OCClassSettingsMetadataKey.value 	: OpenShortcutActionMode.linksOnly.rawValue,
						OCClassSettingsMetadataKey.description 	: "Open only shortcut files that target links (web and other)."
					],
					[
						OCClassSettingsMetadataKey.value 	: OpenShortcutActionMode.none.rawValue,
						OCClassSettingsMetadataKey.description 	: "Do not open shortcut files."
					]
				]
			]
		])
	}

	public static var openShortcutMode: OpenShortcutActionMode {
		let classSettingValue = self.classSetting(forOCClassSettingsKey: .openShortcutMode) as? String

		if let classSettingValue {
			return OpenShortcutActionMode(rawValue: classSettingValue) ?? .none
		}

		return .all
	}

	override open class var identifier : OCExtensionIdentifier? { return OCExtensionIdentifier("com.owncloud.action.openShortcutFile") }
	override open class var category : ActionCategory? { return .normal }
	override open class var name : String? { return OCLocalizedString("Open shortcut", nil) }
	override open class var locations : [OCExtensionLocationIdentifier]? { return [.directOpen] }

	// MARK: - Extension matching
	override open class func applicablePosition(forContext: ActionContext) -> ActionPosition {
		if OpenShortcutFileAction.openShortcutMode == .none {
			return .none
		}

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
			let alertController = ThemedAlertController(with: OCLocalizedString("Error", nil), message: error.localizedDescription, okLabel: OCLocalizedString("OK", nil), action: nil)
			self.context.viewController?.present(alertController, animated: true)
		} else if let item {
			_ = item.openItem(from: context.viewController, with: context.clientContext, animated: true, pushViewController: true, completion: nil)
		} else if let url {
			let alert = ThemedAlertController(title: OCLocalizedFormat("Shortcut to '{{hostname}}'", ["hostname" : url.host ?? "URL"]), message: OCLocalizedFormat("This shortcut points to:\n{{url}}", ["url" :  url.absoluteString]), preferredStyle: .alert)
			alert.addAction(UIAlertAction(title: OCLocalizedString("Open link", nil), style: .default, handler: { _ in
				UIApplication.shared.open(url) { success in
					if !success {
						OnMainThread {
							let alert = ThemedAlertController(title: OCLocalizedString("Opening link failed", nil), message: nil, preferredStyle: .alert)
							alert.addAction(UIAlertAction(title: OCLocalizedString("OK", nil), style: .default))
							self.context.viewController?.present(alert, animated: true)
						}
					}
				}
			}))
			alert.addAction(UIAlertAction(title: OCLocalizedString("Cancel", nil), style: .cancel))
			self.context.viewController?.present(alert, animated: true)
		}
	}

	override open class func iconForLocation(_ location: OCExtensionLocationIdentifier) -> UIImage? {
		return UIImage(systemName: "arrow.up.forward.square")?.withRenderingMode(.alwaysTemplate)
	}
}
