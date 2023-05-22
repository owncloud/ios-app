//
//  URL+Extensions.swift
//  ownCloud
//
//  Created by Michael Neuwert on 06.08.2019.
//  Copyright © 2019 ownCloud GmbH. All rights reserved.
//

import Foundation
import ownCloudSDK
import ownCloudAppShared

typealias UploadHandler = (OCItem?, Error?) -> Void

extension URL {
	// MARK: - App scheme matching
	var matchesAppScheme : Bool {
		guard
			let urlTypes = Bundle.main.object(forInfoDictionaryKey: "CFBundleURLTypes") as? [Any],
			let firstUrlType = urlTypes.first as? [String : Any],
			let urlSchemes = firstUrlType["CFBundleURLSchemes"] as? [String]  else {
				return false
		}
		if urlSchemes.first == self.scheme?.lowercased() {
			return true
		}
		return false
	}

	// MARK: - File upload
	func upload(with core:OCCore?, at rootItem:OCItem, alternativeName:String? = nil, modificationDate:Date? = nil, importByCopy:Bool = false, cellularSwitchIdentifier:OCCellularSwitchIdentifier? = nil, placeholderHandler:UploadHandler? = nil, completionHandler:UploadHandler? = nil) -> Progress? {
		let fileName = alternativeName != nil ? alternativeName! : self.lastPathComponent
		var importOptions : [OCCoreOption : Any] = [.importByCopying : importByCopy, .automaticConflictResolutionNameStyle : OCCoreDuplicateNameStyle.bracketed.rawValue]

		if cellularSwitchIdentifier != nil {
			importOptions[.dependsOnCellularSwitch] = cellularSwitchIdentifier
		}

		if let modificationDate = modificationDate {
			importOptions[.lastModifiedDate] = modificationDate
		}

		var progress:Progress?

		if core != nil {
			progress = core?.importFileNamed(fileName,
											 at: rootItem,
											 from: self,
											 isSecurityScoped: false,
											 options: importOptions,
											 placeholderCompletionHandler: { (error, item) in
												if error != nil {
													Log.error("Error creating placeholder item for \(Log.mask(fileName)), error: \(error!.localizedDescription)")
												}
												placeholderHandler?(item, error)

			}, resultHandler: { (error, _, item, _) in
				if error != nil {
					Log.error("Error uploading \(Log.mask(fileName)) to \(Log.mask(rootItem.path)), error: \(error?.localizedDescription ?? "" )")
				} else {
					Log.debug("Success uploading \(Log.mask(fileName)) to \(Log.mask(rootItem.path))")
				}
				completionHandler?(item, error)
			})
		} else {
			completionHandler?(nil, NSError(ocError: .internal))
		}

		return progress
	}

	// MARK: - Private link handling (OC10)
	var privateLinkItemID: String? {
		// Check if the link URL has format https://<server>/f/<item_id>
		if self.pathComponents.count > 2 {
			if self.pathComponents[self.pathComponents.count - 2] == "f" {
				return self.pathComponents.last
			}
		}

		return nil
	}

	@discardableResult func retrieveLinkedItem(with completion: @escaping (_ item: OCItem?, _ bookmark: OCBookmark?, _ error: Error?, _ connected: Bool) -> Void) -> Bool {
		// Check if the link is private ones and has item ID
		guard self.privateLinkItemID != nil else {
			return false
		}

		// Find matching bookmarks
		let bookmarks = OCBookmarkManager.shared.bookmarks.filter({bookmark in bookmark.url?.host == self.host})

		var matchedBookmark: OCBookmark?
		var foundItem: OCItem?
		var lastError: Error?
		var internetReachable = false

		let group = DispatchGroup()

		for bookmark in bookmarks {

			if foundItem == nil {
				var components = URLComponents(url: self, resolvingAgainstBaseURL: true)
				// E.g. if we would like to use app URL scheme (owncloud://) instead of universal link, to make it work with oC SDK, we need to change scheme back to the original bookmark URL scheme
				components?.scheme = bookmark.url?.scheme

				if let privateLinkURL = components?.url {
					group.enter()
					OCCoreManager.shared.requestCore(for: bookmark, setup: nil) { (core, error) in
						if core != nil {
							internetReachable = core!.connectionStatusSignals.contains(.reachable)
							OnMainThread {
								core?.retrieveItem(forPrivateLink: privateLinkURL, completionHandler: { (error, item) in
									if foundItem == nil {
										foundItem = item
									}
									if components?.host == bookmark.url?.host {
										matchedBookmark = bookmark
									}
									lastError = error
									OCCoreManager.shared.returnCore(for: bookmark, completionHandler: nil)
									group.leave()
								})
							}
						} else {
							group.leave()
						}
					}
				}
			}
		}

		group.notify(queue: DispatchQueue.main) {
			completion(foundItem, matchedBookmark, lastError, internetReachable)
		}

		return true
	}

	func resolveAndPresentPrivateLink(with clientContext: ClientContext) {
		guard let window = (clientContext.scene as? UIWindowScene)?.windows.first else {
			return
		}

		let hud : ProgressHUDViewController? = ProgressHUDViewController(on: nil)
		hud?.present(on: window.rootViewController?.topMostViewController, label: "Resolving link…".localized)

		self.retrieveLinkedItem(with: { (item, bookmark, _, internetReachable) in
			let completion = {
				if item == nil {
					let isOffline = internetReachable == false
					let accountFound = bookmark != nil
					var message = ""

					if !accountFound {
						message = "Link points to an account bookmark which is not configured in the app.".localized
					} else if isOffline {
						message = "Couldn't resolve a private link since you are offline and corresponding item is not cached locally.".localized
					} else {
						message = "Couldn't resolve a private link since the item is not known to the server.".localized
					}

					let alertController = ThemedAlertController(title: "Link resolution failed".localized, message: message, preferredStyle: .alert)
					alertController.addAction(UIAlertAction(title: "OK", style: .default))

					window.rootViewController?.topMostViewController.present(alertController, animated: true)

				} else {
					if let item, let bookmark = bookmark {
						let stateAction = AppStateAction(with: [
							.connection(with: bookmark, children: [
								.reveal(item: item)
							])
						])

						stateAction.run(in: clientContext, completion: { error, clientContext in
						})
					}
				}
			}

			if hud != nil {
				hud?.dismiss(completion: completion)
			} else {
				completion()
			}
		})
	}
}
