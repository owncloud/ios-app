//
//  OCFileProviderServiceSession+UploadByFileProvider.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 30.07.20.
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

import UIKit
import ownCloudSDK
import ownCloudApp

public extension OCFileProviderServiceSession {
	private func performThroughSession(url importItemURL: URL, as importName : String?, to targetDirectory : OCItem, action: @escaping (_ serviceHost: OCFileProviderServicesHost?, _ name: String, _ effectiveImportItemURL: URL, _ completeImport : @escaping (Error?) -> Void) -> Void, completion: @escaping (_ error: Error?) -> Void) {
		let name = importName ?? importItemURL.lastPathComponent
		var effectiveImportItemURL : URL = importItemURL
		var tempFolderURL : URL?

		guard let vault = vault else {
			Log.error("Not importing file \(importItemURL.lastPathComponent) due to insufficient parameters…")
			completion(NSError(ocError: .insufficientParameters))
			return
		}

		Log.debug("Importing file \(importItemURL.lastPathComponent) …")

		// Check if item is inside vault
		if let vaultRootURLString = vault.rootURL?.absoluteString, !importItemURL.absoluteString.hasPrefix(vaultRootURLString) {
			// If not, copy item inside temporary vault location
			if let shareFilesRootURL = vault.rootURL?.appendingPathComponent("fp-import", isDirectory: true) {
				let tryTempFolderURL = shareFilesRootURL.appendingPathComponent(UUID().uuidString, isDirectory: true)
				let name = importItemURL.lastPathComponent
				let tempFileURL = tryTempFolderURL.appendingPathComponent(name)

				do {
					// Create unique temporary, shared location
					try FileManager.default.createDirectory(at: tryTempFolderURL, withIntermediateDirectories: true, attributes: [ .protectionKey : FileProtectionType.completeUntilFirstUserAuthentication])

					tempFolderURL = tryTempFolderURL

					// Copy file into temporary, shared location
					try FileManager.default.copyItem(at: importItemURL, to: tempFileURL)

					effectiveImportItemURL = tempFileURL
				} catch {
					Log.error("Error importing \(importItemURL.absoluteString) to temporary location \(tempFileURL): \(error.localizedDescription)")
					if let tempFolderURL = tempFolderURL {
						try? FileManager.default.removeItem(at: tempFolderURL)
					}
					completion(error)
					return
				}
			}
		}

		let wrappedCompleteHandler : (Error?) -> Void = { (error) in
			completion(error)

			// Remove unique temporary shared location when no longer needed
			if let tempFolderURL = tempFolderURL {
				try? FileManager.default.removeItem(at: tempFolderURL)
			}
		}

		self.acquireFileProviderServicesHost(completionHandler: { (error, serviceHost, doneHandler) in
			let completeImport : (Error?) -> Void = { (error) in
				wrappedCompleteHandler(error)
				doneHandler?()
			}

			if error != nil {
				Log.debug("Error acquiring file provider host: \(error?.localizedDescription ?? "" )")
				completeImport(error)
			} else {
				// Upload file from shared location
				action(serviceHost, name, effectiveImportItemURL, completeImport)
			}
		}, errorHandler: { (error) in
			wrappedCompleteHandler(error)
		})
	}

	func importThroughFileProvider(url importItemURL: URL, as importName : String? = nil, to targetDirectory : OCItem, completion: @escaping (_ error: Error?) -> Void) {
		performThroughSession(url: importItemURL, as: importName, to: targetDirectory, action: { (serviceHost, name, effectiveImportItemURL, completeImport) in
			// Upload file from shared location
			if serviceHost?.importItemNamed(name, at: targetDirectory, from: effectiveImportItemURL, isSecurityScoped: false, importByCopying: true, automaticConflictResolutionNameStyle: .bracketed, placeholderCompletionHandler: { (error) in
				if error != nil {
					Log.debug("Error uploading \(Log.mask(name)) to \(Log.mask(targetDirectory.path)), error: \(error?.localizedDescription ?? "" )")
				}

				completeImport(error)
			}) == nil {
				Log.debug("Error setting up upload of \(Log.mask(name)) to \(Log.mask(targetDirectory.path))")
				let error = NSError(domain: OCErrorDomain, code: Int(OCError.internal.rawValue), userInfo: [NSLocalizedDescriptionKey: "Error setting up upload of \(Log.mask(name)) to \(Log.mask(targetDirectory.path))"])

				completeImport(error)
			}
		}, completion: completion)
	}

	func reportModificationThroughFileProvider(url importItemURL: URL, as importName : String? = nil, for item: OCItem, to targetDirectory : OCItem, lastModifiedDate: Date?, completion: @escaping (_ error: Error?) -> Void) {
		performThroughSession(url: importItemURL, as: importName, to: targetDirectory, action: { (serviceHost, name, effectiveImportItemURL, completeImport) in
			// Upload file from shared location
			if serviceHost?.reportLocalModification(of: item, parentItem: targetDirectory, withContentsOfFileAt: effectiveImportItemURL, lastModifiedDate: lastModifiedDate, isSecurityScoped: false, placeholderCompletionHandler: { (error) in
				if error != nil {
					Log.debug("Error uploading \(Log.mask(name)) to \(Log.mask(targetDirectory.path)), error: \(error?.localizedDescription ?? "" )")
				}

				completeImport(error)
			}) == nil {
				Log.debug("Error setting up upload/update of \(Log.mask(name)) at \(Log.mask(targetDirectory.path))")
				let error = NSError(domain: OCErrorDomain, code: Int(OCError.internal.rawValue), userInfo: [NSLocalizedDescriptionKey: "Error setting up upload/update of \(Log.mask(name)) at \(Log.mask(targetDirectory.path))"])

				completeImport(error)
			}
		}, completion: completion)
	}
}
