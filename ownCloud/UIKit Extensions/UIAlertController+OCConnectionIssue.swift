//
//  UIAlertController+OCConnectionIssue.swift
//  ownCloud
//
//  Created by Felix Schwarz on 18.06.18.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

import UIKit
import ownCloudSDK

extension OCConnectionIssueChoice {
	var alertActionStyle : UIAlertActionStyle {
		switch type {
			case .cancel:
				return .cancel

			case .regular, .default:
				return .default

			case .destructive:
				return .destructive
		}
	}
}

extension UIAlertController {
	convenience init(with issue: OCConnectionIssue) {
		self.init(title: issue.localizedTitle, message: issue.localizedDescription, preferredStyle: .alert)

		for choice in issue.choices {

			self.addAction(UIAlertAction.init(title: choice.label, style: choice.alertActionStyle, handler: { (_) in
				issue.selectChoice(choice)
			}))
		}
	}
}
