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
	func upload(with core:OCCore?, at rootItem:OCItem, alternativeName:String? = nil, importByCopy:Bool = false, placeholderHandler:UploadHandler? = nil, completionHandler:UploadHandler? = nil) -> Progress? {
		let fileName = alternativeName != nil ? alternativeName! : self.lastPathComponent
		let importOptions : [OCCoreOption : Any] = [OCCoreOption.importByCopying : importByCopy, OCCoreOption.automaticConflictResolutionNameStyle : OCCoreDuplicateNameStyle.bracketed.rawValue]

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
}
