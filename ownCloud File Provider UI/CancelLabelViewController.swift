//
//  CancelLabelViewController.swift
//  ownCloud File Provider UI
//
//  Created by Matthias Hühne on 25.02.21.
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

import UIKit
import FileProviderUI
import ownCloudApp
import ownCloudAppShared

class CancelLabelViewController: UIViewController {

	@IBOutlet var label : UILabel!
	@IBOutlet var button : ThemeButton!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

	func updateCancelLabels(with message: String) {
		let collection = Theme.shared.activeCollection
		self.view.backgroundColor = collection.toolbarColors.backgroundColor
		self.label.textColor = collection.toolbarColors.labelColor
		self.button.setTitleColor(collection.toolbarColors.labelColor, for: .normal)
		self.button.backgroundColor = collection.neutralColors.normal.background
		self.label.text = message
		self.button.setTitle("Cancel".localized, for: .normal)
	}

	@IBAction func cancelScreen() {
		self.dismiss(animated: true) {
			self.extensionContext?.cancelRequest(withError: NSError(domain: FPUIErrorDomain, code: Int(FPUIExtensionErrorCode.userCancelled.rawValue), userInfo: nil))
		}
	}

}
