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

	typealias CancelAction = (() -> Void)

	var cancelAction: CancelAction?

	func updateCancelLabels(with message: String, buttonLabel: String? = nil) {
		let collection = Theme.shared.activeCollection

		view.cssSelector = .toolbar
		button.cssSelector = .cancel

		view.apply(css: collection.css, properties: [.fill])
		label.apply(css: collection.css, properties: [.stroke])

		self.label.text = message
		self.button.setTitle(buttonLabel ?? OCLocalizedString("Cancel", nil), for: .normal)
	}

	@IBAction func cancelScreen() {
		self.dismiss(animated: true) {
			self.cancelAction?()
		}
	}

}
