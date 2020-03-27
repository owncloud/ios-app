//
//  MessageCell.swift
//  ownCloud
//
//  Created by Felix Schwarz on 25.03.20.
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

class MessageCell: ThemeTableViewCell {

	weak var delegate: ClientItemCellDelegate?
	weak var core : OCCore?

	override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
	}

	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}

	// MARK: - Present item
	var message : OCMessage? {
		didSet {
			if let newMessage = message {
				updateWith(newMessage, queue: OCMessageQueue.global)
			}
		}
	}

	var alertView : AlertView?

	func updateWith(_ message: OCMessage, queue: OCMessageQueue) {
		var options : [AlertOption] = []

		if let choices = message.syncIssue?.choices {
			for choice in choices {
				let option = AlertOption(label: choice.label, type: choice.type, handler: { (_, _) in
					queue.resolveMessage(message, with: choice)
				})

				options.append(option)
			}
		}

		alertView?.removeFromSuperview()

		if let title = message.syncIssue?.localizedTitle, let description = message.syncIssue?.localizedDescription {
			alertView = AlertView(localizedTitle: title, localizedDescription: description, options: options)
			alertView?.translatesAutoresizingMaskIntoConstraints = false
			alertView?.layer.cornerRadius = 10
			alertView?.backgroundColor = UIColor(white: 0.80, alpha: 0.15)

			if let alertView = alertView {
				self.addSubview(alertView)

				NSLayoutConstraint.activate([
					alertView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 20),
					alertView.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -20),
					alertView.topAnchor.constraint(equalTo: self.topAnchor, constant: 20),
					alertView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -20)
				])
			}
		}

		self.accessoryType = .none
	}

	override func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		super.applyThemeCollection(theme: theme, collection: collection, event: event)
	}
}
