//
//  SecureTextField.swift
//  ownCloud
//
//  Created by Matthias Hühne on 09.12.24.
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
import ownCloudApp

class SecureTextField : UITextField {

	override init(frame: CGRect) {
		super.init(frame: .zero)
		self.isSecureTextEntry = true
		self.translatesAutoresizingMaskIntoConstraints = false
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	var secureContainerView: UIView {
		guard !ConfidentialManager.shared.allowScreenshots else {
			let view = UIView()
			view.translatesAutoresizingMaskIntoConstraints = false
			
			return view
		}
		
		if let secureView = self.subviews.filter({ subview in
			type(of: subview).description().contains("CanvasView")
		}).first {
			secureView.translatesAutoresizingMaskIntoConstraints = false
			secureView.isUserInteractionEnabled = true
			return secureView
		}
		
		// If screenshot protection was not possible, force close the application.
		exit(0)
		
		let view = UIView()
		view.translatesAutoresizingMaskIntoConstraints = false
			
		return view
	}
	
	override var canBecomeFirstResponder: Bool { false }
	override func becomeFirstResponder() -> Bool { false }
}
