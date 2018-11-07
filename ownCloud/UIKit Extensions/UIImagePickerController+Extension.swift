//
//  UIImagePickerController+Extension.swift
//  ownCloud
//
//  Created by Pablo Carrascal on 07/11/2018.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

import UIKit
import MobileCoreServices

extension UIImagePickerController {

	class func regularImagePicker(with sourceType: UIImagePickerController.SourceType) -> UIImagePickerController {
		let picker = UIImagePickerController()
		picker.sourceType = sourceType
		picker.mediaTypes = [kUTTypeMovie as String, kUTTypeImage as String]

		return picker
	}
}
