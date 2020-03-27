//
//  CardIssueMessagePresenter.swift
//  ownCloud
//
//  Created by Felix Schwarz on 26.03.20.
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

class CardIssueMessagePresenter: OCMessagePresenter {

	var bookmarkUUID : OCBookmarkUUID
	var presenter : (UIViewController) -> Void

	init(with bookmarkUUID: OCBookmarkUUID, presenter: @escaping (UIViewController) -> Void) {

		self.bookmarkUUID = bookmarkUUID
		self.presenter = presenter

		super.init()

		self.identifier = OCMessagePresenterIdentifier(rawValue: "card")
	}

	override func presentationPriority(for message: OCMessage) -> OCMessagePresentationPriority {
		if message.syncIssue != nil, let messageBookmarkUUID = message.bookmarkUUID, let bookmarkUUID = bookmarkUUID as UUID?, messageBookmarkUUID == bookmarkUUID {
			return .high
		}

		return .wontPresent
	}

	override func present(_ message: OCMessage, completionHandler: @escaping (Bool, OCSyncIssueChoice?) -> Void) {
		var options : [AlertOption] = []

		if let choices = message.syncIssue?.choices {
			for choice in choices {
				let option = AlertOption(label: choice.label, type: choice.type, handler: { (_, _) in
					completionHandler(true, choice)
				})

				options.append(option)
			}
		}

		if options.count == 0 {
			options.append(AlertOption(label: "OK".localized, type: .default, handler: { (_, _) in }))
		}

		if let syncIssue = message.syncIssue {
			let alertViewController = AlertViewController(localizedTitle: syncIssue.localizedTitle, localizedDescription: syncIssue.localizedDescription ?? "", options: options, dismissHandler: {
				completionHandler(true, nil)
			})

			self.presenter(alertViewController)
		}
	}
}
