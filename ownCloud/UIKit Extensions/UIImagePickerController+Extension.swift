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
		picker.navigationBar.isTranslucent = false
		picker.navigationBar.barTintColor = Theme.shared.activeCollection.navigationBarColors.backgroundColor
		picker.navigationBar.backgroundColor = Theme.shared.activeCollection.navigationBarColors.backgroundColor
		picker.navigationBar.tintColor = Theme.shared.activeCollection.navigationBarColors.tintColor
		picker.navigationBar.titleTextAttributes = [ .foregroundColor :  Theme.shared.activeCollection.navigationBarColors.labelColor ]

		return picker
	}
}
