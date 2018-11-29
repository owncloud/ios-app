//
//  PasswordManagerAccess.swift
//  ownCloud
//
//  Created by Felix Schwarz on 08.05.18.
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
import MobileCoreServices

let PasswordManagerAccessErrorDomain : NSErrorDomain = "PasswordManagerAccessErrorDomain"

enum PasswordManagerAccessError : Int {
	case userCancelled
	case failedContactingExtension
	case unexpectedData
}

internal let PasswordManagerAccessVersionNumber = 185

internal let PasswordManagerAccessVersionNumberKey = "version_number"
internal let PasswordManagerAccessURLStringKey = "url_string"

internal let PasswordManagerAccessUsernameKey = "username"
internal let PasswordManagerAccessPasswordKey = "password"

internal let PasswordManagerAccessItemProviderTypeIdentifier = "org.appextension.find-login-action"

internal let PasswordManagerAccessURLScheme = "org-appextension-feature-password-management://"

class PasswordManagerAccess {
	static var installed : Bool {
		return UIApplication.shared.canOpenURL(URL(string: PasswordManagerAccessURLScheme)!)
	}

	static func findCredentials(url: URL, viewController: UIViewController, sourceView: UIView? = nil, completion: @escaping ((_ error: Error?, _ username: String?, _ password: String?) -> Void)) {
		let extensionItem = NSExtensionItem()
		let itemProvider = NSItemProvider(item: ([
			PasswordManagerAccessVersionNumberKey : PasswordManagerAccessVersionNumber,
			PasswordManagerAccessURLStringKey     : url.absoluteString
		] as NSDictionary), typeIdentifier: PasswordManagerAccessItemProviderTypeIdentifier)

		extensionItem.attachments = [ itemProvider ]

		let activityViewController = UIActivityViewController(activityItems: [extensionItem], applicationActivities: nil)

		activityViewController.completionWithItemsHandler = { (_, _, returnedItems, activityError) in
			if (returnedItems == nil) || (returnedItems?.count == 0) {
				completion(NSError(domain: PasswordManagerAccessErrorDomain as String,
						     code: (activityError != nil) ? PasswordManagerAccessError.failedContactingExtension.rawValue : PasswordManagerAccessError.userCancelled.rawValue,
						 userInfo: (activityError != nil) ? [NSUnderlyingErrorKey : activityError!] : nil), nil, nil)
			} else {
				if let firstExtensionItem = returnedItems?.first as? NSExtensionItem {
					self.processExtensionItem(extensionItem: firstExtensionItem, completion: completion)
				}
			}
		}

		if UIDevice.current.isIpad() {
			activityViewController.popoverPresentationController?.sourceView = sourceView ?? viewController.view
		}

		viewController.present(activityViewController, animated: true, completion: nil)
	}

	static func processExtensionItem(extensionItem : NSExtensionItem, completion: @escaping ((_ error: Error?, _ username: String?, _ password: String?) -> Void)) {
		if let attachments = extensionItem.attachments,
		   attachments.count > 0,

		   let itemProvider = extensionItem.attachments?.first as? NSItemProvider,
		   itemProvider.hasItemConformingToTypeIdentifier(kUTTypePropertyList as String) {

			itemProvider.loadItem(forTypeIdentifier: kUTTypePropertyList as String, options: nil) { (itemDictionary, error) in
				if error == nil,
				   let credentialsDict = itemDictionary as? [String:Any],
				   credentialsDict.count > 0 {

					completion(nil, credentialsDict[PasswordManagerAccessUsernameKey] as? String, credentialsDict[PasswordManagerAccessPasswordKey] as? String)

				} else {

					completion((error != nil) ? error : NSError(domain: PasswordManagerAccessErrorDomain as String, code: PasswordManagerAccessError.unexpectedData.rawValue), nil, nil)

				}
			}
		} else {
			completion(NSError(domain: PasswordManagerAccessErrorDomain as String, code: PasswordManagerAccessError.unexpectedData.rawValue), nil, nil)
		}
	}
}
